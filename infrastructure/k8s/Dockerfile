FROM hashicorp/terraform:1.6

COPY src .

COPY aws-credentials /aws-credentials
COPY authorized_keys /authorized_keys
COPY private_key /private_key

RUN terraform init

ENTRYPOINT ["terraform"]
CMD ["plan"]
