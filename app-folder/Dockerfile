FROM python:3.14.6-trixie@sha256:7655aadf4ac71023baa42d7e1430a61d2ca80798af2ffb71c3533baafe68695b

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

EXPOSE 8501

HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=6 \
  CMD curl --fail http://localhost:8501/_stcore/health || exit 1

CMD ["streamlit", "run", "semantic_app.py", "--server.port=8501", "--server.address=0.0.0.0"]
