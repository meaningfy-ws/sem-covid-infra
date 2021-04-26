FROM apache/airflow:2.0.1-python3.8

USER airflow

RUN pip install --upgrade pip
COPY requirements.txt /opt/airflow
RUN pip install --no-cache-dir --user -r /opt/airflow/requirements.txt

# COPY variables.json /opt/airflow/dags
# RUN airflow variables import /opt/airflow/dags/variables.json