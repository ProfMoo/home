FROM hashicorp/terraform:1.8

COPY src .

COPY aws-credentials /aws-credentials

RUN terraform init

ENTRYPOINT ["terraform"]
CMD ["plan"]
