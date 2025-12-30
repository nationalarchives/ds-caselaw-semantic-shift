FROM python:3.14.1@sha256:595140b768992c05b096570e5ae487a02a2c6b3ae23ba33ce0fc34b99579c98e


WORKDIR /code


COPY requirements.txt /code/
COPY semantic_app.py /code/
COPY templates /code/templates
COPY models /models

RUN apt-get update && apt-get install -y awscli

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt


RUN python -m spacy download en_core_web_sm

EXPOSE 80

CMD ["streamlit", "run", "semantic_app.py", "--server.port=80", "--server.address=0.0.0.0"]
