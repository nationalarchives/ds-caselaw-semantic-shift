FROM python:3.14.5@sha256:6928095b5c67225857e608dd95271a81e8bb134e4bf7e7c305a9cdc2502a1d06

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
