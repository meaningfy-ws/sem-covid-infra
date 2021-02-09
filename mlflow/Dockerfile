FROM python:3.7-slim

RUN mkdir -p /mlflow/mlruns
WORKDIR /mlflow

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN echo "export LC_ALL=$LC_ALL" >> /etc/profile.d/locale.sh
RUN echo "export LANG=$LANG" >> /etc/profile.d/locale.sh

RUN pip install --upgrade pip
RUN pip install psycopg2 mlflow mlflow[extras]
#
#COPY ./start.sh ./start.sh
#RUN chmod +x ./start.sh