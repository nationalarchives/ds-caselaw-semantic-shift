FROM python:3.14.2@sha256:6d58c1a9444bc2664f0fa20c43a592fcdb2698eb9a9c32257516538a2746c19a


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
