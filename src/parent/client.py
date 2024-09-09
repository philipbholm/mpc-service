import json
import socket


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(("localhost", 5005))
print("Connected to enclave")


def send_json(json_data):
    message = json.dumps(json_data).encode("UTF-8")
    sock.send(message)


send_json({"message": "Hello, world!"})
send_json({"message": "Bye!"})
sock.close()
