FROM hashicorp/terraform:1.0.3

COPY . .

RUN terraform init

COPY aws-credentials /aws-credentials
RUN cat /aws-credentials
RUN ls /


ENTRYPOINT ["terraform"]
CMD ["plan"]
