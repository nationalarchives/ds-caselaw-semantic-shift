FROM python:3.14.6@sha256:1d104eba09001f83c5fd4540fe15b44c691a76c6c816ade0e699b49518e344d8

# renovate: depName=awscli
ENV AWS_CLI_VERSION="2.33.27"

RUN useradd -m -u 1000 appuser

WORKDIR /code

COPY requirements.txt /code/
COPY semantic_app.py /code/
COPY templates /code/templates
COPY models /models

RUN apt-get update && apt-get install -y --no-install-recommends awscli="${AWS_CLI_VERSION}" && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

RUN python -m spacy download en_core_web_sm

RUN chown -R appuser:appuser /code /models

USER appuser

EXPOSE 80

CMD ["streamlit", "run", "semantic_app.py", "--server.port=80", "--server.address=0.0.0.0"]
