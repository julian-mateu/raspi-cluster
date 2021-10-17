FROM python:3.9-slim

RUN apt-get update
RUN apt-get upgrade

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

RUN apt-get install -y sshpass

ENTRYPOINT [ "bash" ]