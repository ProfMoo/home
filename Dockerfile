FROM hashicorp/terraform:1.0.3

COPY . .

RUN terraform init

ENTRYPOINT ["terraform"]
CMD ["plan"]
