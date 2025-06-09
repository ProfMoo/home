FROM hashicorp/terraform:1.12

WORKDIR /terraform


COPY src .

COPY aws-credentials /aws-credentials

RUN terraform init

ENTRYPOINT ["terraform"]
CMD ["plan"]
