import json
import socket


def main():
    print("Enclave server is running")
    # sock = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
    # cid = socket.VMADDR_CID_ANY
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    cid = "0.0.0.0"
    port = 5005
    sock.bind((cid, port))
    sock.listen(5)
    print(f"Enclave server is listening on port {port} and cid {cid}")

    while True:
        conn, addr = sock.accept()
        print(f"Connection from {addr} has been established.")
        data = conn.recv(4096).decode("UTF-8")
        print(f"Received data: {data}")
        json_data = json.loads(data)
        print(f"Received json data: {json_data}")
        # TODO: Decrypt data
        # TODO: Perform analysis
        # TODO: Encrypt results
        result = {"result": "analysis result", "input": json_data}
        result_str = json.dumps(result)
        print(f"Sending result: {result_str}")
        conn.send(result_str.encode("UTF-8"))
        print("Closing connection")
        conn.close()


if __name__ == "__main__":
    main()
