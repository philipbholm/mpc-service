import socket


def main():
    sock = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
    sock.settimeout(5)
    sock.connect((16, 5005))
    sock.sendall("Hello".encode("UTF-8"))
    sock.close()


if __name__ == "__main__":
    main()
