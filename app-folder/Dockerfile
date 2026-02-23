FROM python:3.14.2@sha256:fbf695a1b7e4fd39dfac43165c0da0949262531ecd8e901abe641d79f596af80


WORKDIR /code


COPY requirements.txt /code/
COPY semantic_app.py /code/
COPY templates /code/templates
COPY models /models

RUN apt-get update && apt-get install -y --no-install-recommends awscli=2.33.27 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt


RUN python -m spacy download en_core_web_sm

EXPOSE 80

CMD ["streamlit", "run", "semantic_app.py", "--server.port=80", "--server.address=0.0.0.0"]
