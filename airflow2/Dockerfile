#FROM apache/airflow:2.0.1-python3.8
#FROM  apache/airflow:latest-python3.8
FROM apache/airflow:2.1.0-python3.8

# quick sudo
USER root
RUN apt-get update && apt-get install make && apt-get install build-essential -y

# back to normal user
USER airflow

# Makefile, requirements-prod.txt and requirements-dev.txt shall be made availble from teh **sem-covid** GitHub repository
# https://github.com/meaningfy-ws/sem-covid
# Assuming that the above requirements are met, copy the needed files into the Docker container
COPY sem-covid/requirements-prod.txt /opt/airflow
COPY sem-covid/Makefile /opt/airflow

# working in the /opt/airflow
WORKDIR /opt/airflow
RUN /usr/local/bin/python -m pip install --upgrade pip
#this is from Makefile in **sem-covid**
RUN make install-prod