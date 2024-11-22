import datetime
import os
import socket
import ssl

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID

PORT = 8000

# TODO: Update SSL context settings
# TODO: Use private key to sign cert and make nsm sign the public key or certificate
# TODO: Add error / context handling
# TODO: Make multithreaded


def _read_nsm_random_bytes(num_bytes):
    with open("/dev/nsm", "r") as nsm:
        print(f"[enclave] Successfully opened NSM device")
        nsm.seek(0)
        print(f"[enclave] Seeking to start of NSM device")
        random_bytes = nsm.read(num_bytes)
        print(f"[enclave] Read {len(random_bytes)} bytes from NSM device")
        return random_bytes


class Server:
    def __init__(self, port: int):
        self.port = port
        self.server_socket = None
        self._key_path = "enclave.key"
        self._cert_path = "enclave.pem"
        self._generate_key_and_certificate()
        self._ssl_context = self._setup_ssl_context()

    def start(self):
        self.server_socket = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
        self.server_socket.bind((socket.VMADDR_CID_ANY, self.port))
        self.server_socket.listen(1)
        print(f"[enclave] Server listening on port {self.port}")
        while True:
            client_socket, client_address = self.server_socket.accept()
            print(f"[enclave] Accepted connection from CID: {client_address[0]}")
            secure_socket = self._ssl_context.wrap_socket(
                client_socket, server_side=True
            )
            print(f"[enclave] Secure socket created: {secure_socket}")
            try:
                while True:
                    data = secure_socket.recv(4096)
                    if not data:
                        break
                    print(f"[enclave] Received: {data.decode('utf-8')}")
                    secure_socket.sendall(b"Message received by enclave\n")
            except Exception as e:
                print(f"[enclave] Error handling client: {e}")
            finally:
                secure_socket.close()
                print("[enclave] Client connection closed")

    def _generate_key_and_certificate(self):
        print("[enclave] Generating key and certificate")
        random_bytes_needed = (521 // 8) * 2
        random_bytes = _read_nsm_random_bytes(random_bytes_needed)
        print(f"[enclave] Generated random bytes: {random_bytes_needed}")
        os.urandom = lambda size: random_bytes[:size]
        private_key = ec.generate_private_key(ec.SECP521R1())

        subject = issuer = x509.Name(
            [x509.NameAttribute(NameOID.COMMON_NAME, "enclave")]
        )
        certificate = (
            x509.CertificateBuilder()
            .subject_name(subject)
            .issuer_name(issuer)
            .public_key(private_key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(datetime.datetime.utcnow())
            .not_valid_after(datetime.datetime.utcnow() + datetime.timedelta(days=10))
            .sign(private_key, hashes.SHA256())
        )

        with open(self._cert_path, "wb") as cert_file:
            cert_file.write(certificate.public_bytes(serialization.Encoding.PEM))
        with open(self._key_path, "wb") as key_file:
            key_file.write(
                private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.TraditionalOpenSSL,
                    encryption_algorithm=serialization.NoEncryption(),
                )
            )

    def _setup_ssl_context(self):
        ssl_context = ssl.create_default_context()
        ssl_context.load_cert_chain(certfile=self._cert_path, keyfile=self._key_path)
        return ssl_context


if __name__ == "__main__":
    print("[enclave] Starting server")
    server = Server(PORT)
    try:
        server.start()
    except KeyboardInterrupt:
        print("[enclave] Server stopped")
    except Exception as e:
        print(f"[enclave] Unexpected error: {e}")
