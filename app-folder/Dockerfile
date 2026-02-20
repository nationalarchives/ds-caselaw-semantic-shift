FROM python:3.14.3@sha256:151ab3571dad616bb031052e86411e2165295c7f67ef27206852203e854bcd12


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
