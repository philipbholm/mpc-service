import json
import secrets
import socket


def main():
    sock = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
    sock.connect((4, 5000))

    request = {
        "nonce": secrets.token_hex(16),
    }
    sock.send(str.encode(json.dumps(request)))

    response = b""
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            break
        response += chunk
    
    print(response.decode("UTF-8"))

    sock.close()


if __name__ == "__main__":
    main()
