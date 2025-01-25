FROM sentriz/betanin:v0.5.6

WORKDIR /src

# Downloading git so we can use pip
RUN apk add --no-cache git=2.40.0 && \
    # Uninstalling the version of beets that comes with betanin
    # so that we can install a custom version from the requirements.txt
    pip3 uninstall -y beets

COPY requirements.txt requirements.txt

RUN pip3 install --no-cache-dir -r requirements.txt
