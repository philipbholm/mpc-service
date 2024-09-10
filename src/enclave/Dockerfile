FROM enclave_base

RUN dnf -y install python3-pip

WORKDIR /app

COPY requirements.txt .
COPY server.py .

RUN pip3 install -r requirements.txt

CMD ["python3", "server.py"]
