FROM python:3.11.10-slim-bookworm

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY main.py .

COPY src ./nsm

CMD ["usr/local/bin/python", "main.py"]