FROM hashicorp/terraform:1.16

WORKDIR /terraform


COPY src .

COPY aws-credentials /aws-credentials

RUN terraform init

ENTRYPOINT ["terraform"]
CMD ["plan"]
