FROM sentriz/betanin

# Downloading git so we can use pip
RUN apk add git

# Uninstalling beets so that the correct version is installed from the requirements.txt
RUN pip3 uninstall -y beets
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
