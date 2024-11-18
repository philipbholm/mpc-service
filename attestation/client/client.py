import json
import secrets
import socket


def main():
    sock = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
    sock.connect((16, 5000))

    request = {
        "nonce": secrets.token_hex(16),
    }

    sock.send(str.encode(json.dumps(request)))

    print(sock.recv(2048).decode())

    sock.close()


if __name__ == "__main__":
    main()
