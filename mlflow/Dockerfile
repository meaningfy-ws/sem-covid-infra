FROM python:3.7-slim

RUN mkdir -p /mlflow/mlruns
WORKDIR /mlflow

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN echo "export LC_ALL=$LC_ALL" >> /etc/profile.d/locale.sh
RUN echo "export LANG=$LANG" >> /etc/profile.d/locale.sh

RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    libpq-dev

RUN pip install --upgrade pip
#RUN pip install psycopg2-binary mlflow mlflow[extras] boto3
RUN pip install mlflow boto3 psycopg2-binary pysftp
#
#COPY ./start.sh ./start.sh
#RUN chmod +x ./start.sh

EXPOSE 80
EXPOSE 443