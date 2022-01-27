FROM python:3.10.2-alpine

COPY requirements.txt requirements.txt
COPY entrypoint.sh entrypoint.sh

RUN pip3 install -r requirements.txt

ENV BEETSDIR=/config
