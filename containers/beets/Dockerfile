FROM sentriz/betanin

# Downloading git so we can use pip
RUN apk add git

# Uninstalling the version of beets that comes with betanin
# so that we can install a custom version from the requirements.txt
RUN pip3 uninstall -y beets
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
