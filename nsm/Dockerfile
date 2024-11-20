FROM python:3.11.10-slim-bookworm

COPY requirements.txt .

RUN pip install -r requirements.txt

WORKDIR /app

COPY . .

CMD ["python", "main.py"]