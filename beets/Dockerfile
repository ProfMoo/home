FROM python:3.8.12

# For the chroma/acoustid plugins
RUN apt-get update && apt-get -y install libchromaprint-tools ffmpeg

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY entrypoint.sh entrypoint.sh
COPY config config
