FROM ghcr.io/opentofu/opentofu:1.13.1

WORKDIR /opentofu


COPY src .

COPY aws-credentials /aws-credentials

RUN tofu init

ENTRYPOINT ["tofu"]
CMD ["plan"]
