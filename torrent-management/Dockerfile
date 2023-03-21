FROM python:3.11.2-bullseye

# Install requirements
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

# Copy in code
COPY . .
ENTRYPOINT [ "python3" ]
