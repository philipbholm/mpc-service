import os
import fcntl
import struct
import cbor2
import ctypes

MAX_REQUEST_SIZE = 0x1000
MAX_RESPONSE_SIZE = 0x3000
IOCTL_MAGIC = 0x0A


class Iovec(ctypes.Structure):
    _fields_ = [
        ("base", ctypes.c_uint64),  # pointer to buffer
        ("len", ctypes.c_uint64),  # length of buffer
    ]


class IoctlMessage(ctypes.Structure):
    _fields_ = [("request", Iovec), ("response", Iovec)]


class NSMSession:
    def __init__(self):
        self.fd = None

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def open(self):
        if self.fd is None:
            try:
                self.fd = os.open("/dev/nsm", os.O_RDWR)
            except OSError as e:
                raise Exception(f"Failed to open NSM device: {e}")
        return self

    def close(self):
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None

    def _send(self, request):
        response = bytearray(MAX_RESPONSE_SIZE)

        ioctl_msg = struct.pack(
            "QQQQ",
            id(request[0]),
            len(request),
            id(response[0]),
            len(response),
        )

        # Using _IOC(3, IOCTL_MAGIC, 0, sizeof(struct iovec) * 2)
        # [ioc] Command input: dir: 3, typ: 10, nr: 0, size: 32
        # [ioc] cDIRSHIFT: 30, cTYPESHIFT: 8, cNRSHIFT: 0, cSIZESHIFT: 16
        # [ioc] Command output: 3223325184
        # ioctl_cmd = (3 << 30) | (IOCTL_MAGIC << 8) | (0 << 0) | (len(ioctl_msg) << 16)
        ioctl_cmd = 3223325184

        try:
            print(f"[nsm] ioctl_msg: {ioctl_msg}")
            fcntl.ioctl(self.fd, ioctl_cmd, ioctl_msg)
            print(f"[nsm] ioctl_msg unpacked after ioctl: {struct.unpack('QQQQ', ioctl_msg)}")
            response_size = struct.unpack("QQQQ", ioctl_msg)[3]
            print(f"[nsm] response size: {response_size}")
            result = bytes(response[:response_size])
            print(f"[nsm] result: {result}")
            return result
        except Exception as e:
            print(f"[nsm] _send failed: {e}")
            raise e

    def get_random_bytes(self, length):
        request = cbor2.dumps("GetRandom")
        print(f"[nsm] get_random_bytes request: {request}")
        response_data = self._send(request)
        print(f"[nsm] get_random_bytes response_data: {response_data}")
        response = cbor2.loads(response_data)
        print(f"[nsm] get_random_bytes response: {response}")
        return response
