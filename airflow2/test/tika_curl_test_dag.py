#!/usr/bin/python3

# tika_curl_test_dag.py
# Date:  15/02/2021
# Author: Eugeniu Costetchi
# Email: costezki.eugen@gmail.com 

"""Test DAG using BashOperator to call Apache Tika"""

from datetime import timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago

args = {
    'owner': 'airflow',
}

def print_cwd(ds, **kwargs):
    """Print the Airflow context and ds variable from the context."""
    print (Path.cwd())
    return str(Path.cwd())


dag = DAG(
    dag_id='tika_bash_operator',
    default_args=args,
    start_date=days_ago(2),
    dagrun_timeout=timedelta(minutes=60),
    tags=['curl_tika'],
    params={"example_key": "example_value"},
)

run_this = BashOperator(
    task_id='run_curl',
    bash_command='curl -T /opt/airflow/dags/LICENSE http://0.0.0.0:9998/meta',
    dag=dag,
)

run_this0 = PythonOperator(
    task_id='print_the_context',
    python_callable=print_cwd,
    dag=dag,
)

run_this0 >> run_this