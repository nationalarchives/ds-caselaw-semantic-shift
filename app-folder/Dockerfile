FROM python:3.12.13-trixie@sha256:a9e4190f02729f01e5b3719bd8b3ea0f8d9350dc17d01a1ce1ca6e3fbfcf7a99

# renovate: depName=awscli
ENV AWS_CLI_VERSION="2.35.14"

RUN useradd -m -u 1000 appuser

WORKDIR /code

COPY requirements.txt /code/
COPY semantic_app.py /code/
COPY templates /code/templates
COPY models /models

ARG AWSCLI_VERSION=2.28.7

RUN curl -fsSL \
      "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" \
      -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

RUN python -m spacy download en_core_web_sm

RUN chown -R appuser:appuser /code /models

USER appuser

EXPOSE 80

CMD ["streamlit", "run", "semantic_app.py", "--server.port=80", "--server.address=0.0.0.0"]
