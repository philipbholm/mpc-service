FROM enclave_base

# Install Python 3.11.9
RUN apt update && apt upgrade -y
RUN apt install -y \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libssl-dev \
    libreadline-dev \
    libffi-dev \
    libsqlite3-dev \
    wget \
    libbz2-dev
RUN wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz && \
    tar -xf Python-3.11.9.tgz && \
    cd Python-3.11.9 && \
    ./configure --enable-optimizations && \
    make -j $(nproc) && \
    make install && \
    cd .. && \
    rm -rf Python-3.11.9 Python-3.11.9.tgz

WORKDIR /app

COPY requirements.txt .
COPY server.py .

RUN pip3 install -r requirements.txt

CMD ["python3", "server.py"]
