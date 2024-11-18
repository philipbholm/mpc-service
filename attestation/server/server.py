import json
import socket


def main():
    print("Starting server")
    sock = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
    cid = socket.VMADDR_CID_ANY
    port = 5000
    sock.bind((cid, port))
    sock.listen()

    while True:
        conn, addr = sock.accept()
        payload = conn.recv(4096)
        request = json.loads(payload.decode())
        # Request attestation doc with nonce
        # Return docs
        conn.send(str.encode(json.dumps(request)))
        conn.close()


if __name__ == "__main__":
    main()
