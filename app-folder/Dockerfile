FROM python:3.10.16


WORKDIR /code


COPY requirements.txt /code/
COPY semantic_app.py /code/
COPY templates /code/templates
COPY models /models

RUN apt-get update && apt-get install -y awscli

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt


RUN python -m spacy download en_core_web_sm


CMD ["uvicorn", "semantic_app:app", "--host", "0.0.0.0", "--port", "80"]
