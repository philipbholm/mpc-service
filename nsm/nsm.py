import ctypes
import fcntl
import os
import threading
from typing import Optional, Protocol

import cbor2

from . import ioc, request, response

# Constants
MAX_REQUEST_SIZE = 0x1000
MAX_RESPONSE_SIZE = 0x3000
IOCTL_MAGIC = 0x0A


class FileDescriptor(Protocol):
    """Protocol for file descriptor objects."""

    def fileno(self) -> int:
        """Return the file descriptor number."""
        ...

    def close(self) -> None:
        """Close the file descriptor."""
        ...


class IoctlFailed(Exception):
    """Error returned when the underlying ioctl syscall has failed."""

    def __init__(self, errno_val: int):
        self.errno = errno_val
        super().__init__(f"ioctl failed on device with errno {errno_val}")


class GetRandomFailed(Exception):
    """Error returned when the GetRandom request fails."""

    def __init__(self, error_code: Optional[response.ErrorCode] = None):
        self.error_code = error_code
        msg = (
            f"GetRandom failed with error code {error_code}"
            if error_code
            else "GetRandom response did not include random bytes"
        )
        super().__init__(msg)


class SessionClosed(Exception):
    """Error returned when the session is in a closed state."""

    def __init__(self):
        super().__init__("Session is closed")


class IoctlMessage(ctypes.Structure):
    """Structure for ioctl message passing."""

    _fields_ = [
        ("request", ctypes.c_void_p),
        ("request_size", ctypes.c_size_t),
        ("response", ctypes.c_void_p),
        ("response_size", ctypes.c_size_t),
    ]


class Session:
    """A session used to interact with the NSM."""

    def __init__(self, fd: FileDescriptor):
        self._fd = fd
        self._lock = threading.Lock()

    @classmethod
    def open(cls) -> "Session":
        """Open a new session using the default NSM device."""
        try:
            fd = os.open("/dev/nsm", os.O_RDWR)
            return cls(os.fdopen(fd, "rb+"))
        except OSError as e:
            raise OSError(f"Failed to open NSM device: {e}")

    def close(self) -> None:
        """Close this session."""
        with self._lock:
            if self._fd is not None:
                self._fd.close()
                self._fd = None

    def _send(self, request_data: bytes) -> bytes:
        """Send raw request data to NSM and receive response."""
        if self._fd is None:
            raise SessionClosed()

        response_buffer = bytearray(MAX_RESPONSE_SIZE)

        msg = IoctlMessage()
        msg.request = ctypes.cast(request_data, ctypes.c_void_p)
        msg.request_size = len(request_data)
        msg.response = ctypes.cast(response_buffer, ctypes.c_void_p)
        msg.response_size = len(response_buffer)

        try:
            cmd = ioc.command(
                ioc.READ | ioc.WRITE, IOCTL_MAGIC, 0, ctypes.sizeof(IoctlMessage)
            )
            fcntl.ioctl(self._fd.fileno(), cmd, msg)
            return bytes(response_buffer[: msg.response_size])
        except OSError as e:
            raise IoctlFailed(e.errno)

    def send(self, req: request.Request) -> response.Response:
        """Send an NSM request and await its response."""
        with self._lock:
            request_data = cbor2.dumps(req.encoded())
            response_data = self._send(request_data)
            return response.Response.from_cbor(response_data)

    def read(self, buffer: bytearray) -> int:
        """Read entropy from the NSM device.

        Args:
            buffer: Buffer to fill with random data

        Returns:
            Number of bytes read

        Raises:
            GetRandomFailed: If the random data request fails
            SessionClosed: If the session is closed
        """
        get_random = request.GetRandom()
        remaining = len(buffer)
        total_read = 0

        while remaining > 0:
            res = self.send(get_random)

            if res.error or not res.get_random or not res.get_random.random:
                raise GetRandomFailed(res.error)

            n = min(remaining, len(res.get_random.random))
            buffer[total_read : total_read + n] = res.get_random.random[:n]
            total_read += n
            remaining -= n

        return total_read
