FROM python:3.8.2-slim


ADD . /usr/app
WORKDIR /usr/app
RUN chmod -R 777 /usr/app



COPY wait-for-it.sh wait-for-it.sh
RUN chmod +x wait-for-it.sh



RUN pip install --upgrade pip
#RUN pip install PyMySQL mlflow[extras]
#RUN pip install psycopg2-binary
RUN pip install mlflow[extras]