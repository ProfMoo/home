FROM hashicorp/terraform:1.0.3

COPY . .

COPY aws-credentials /aws-credentials

RUN terraform init

ENTRYPOINT ["terraform"]
CMD ["plan"]
