import base64
import json
import socket

from nsm import NSMClient


def main():
    print("Starting server")

    print("Initializing NSM")
    nsm_client = NSMClient()

    sock = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
    cid = socket.VMADDR_CID_ANY
    port = 5000
    sock.bind((cid, port))
    sock.listen()
    print(f"Server listening on CID {cid} and port {port}")

    while True:
        conn, addr = sock.accept()
        print(f"Accepted connection from: {addr}")

        request = b""
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            request += chunk
        
        request_dict = json.loads(request.decode("UTF-8"))
        print(f"Received request: {request_dict}")
        
        print("Generating attestation document")
        attestation_document = nsm_client.get_attestation_document()
        attestation_document_b64 = base64.b64encode(attestation_document).decode()

        response = {
            "attestation_document": attestation_document_b64
        }
        print(f"Server sending response: {response}")

        conn.send(str.encode(json.dumps(response)))
        conn.close()


if __name__ == "__main__":
    main()
