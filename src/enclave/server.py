import socket


def main():
    sock = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
    cid = socket.VMADDR_CID_ANY
    port = 5005
    sock.bind((cid, port))
    sock.listen(128)
    print(f"Enclave server is listening on port {port} and cid {cid}")

    while True:
        conn, addr = sock.accept()
        print(f"Connection from {addr} has been established.")
        while True:
            try:
                data = conn.recv(4096).decode("UTF-8")
            except socket.error:
                break
            if not data:
                break
            print(f"Received data: {data}", end="", flush=True)
        print()
        conn.close()


if __name__ == "__main__":
    main()
