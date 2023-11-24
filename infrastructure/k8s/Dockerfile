FROM hashicorp/terraform:1.6

COPY src .

COPY aws-credentials /aws-credentials
COPY authorized_keys /authorized_keys

RUN terraform init

ENTRYPOINT ["terraform"]
CMD ["plan"]
