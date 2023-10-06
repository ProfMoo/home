FROM sentriz/betanin

# Downloading git so we can use pip
RUN apk add git

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
