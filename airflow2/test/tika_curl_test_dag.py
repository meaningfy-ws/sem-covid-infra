#!/usr/bin/python3

# tika_curl_test_dag.py
# Date:  15/02/2021
# Author: Eugeniu Costetchi
# Email: costezki.eugen@gmail.com 

"""Test DAG using BashOperator to call Apache Tika"""

from datetime import timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator
from airflow.utils.dates import days_ago

args = {
    'owner': 'airflow',
}

dag = DAG(
    dag_id='tika_bash_operator',
    default_args=args,
    start_date=days_ago(2),
    dagrun_timeout=timedelta(minutes=60),
    tags=['curl_tika'],
    params={"example_key": "example_value"},
)

run_this = BashOperator(
    task_id='run_after_loop',
    bash_command='echo 1',
    dag=dag,
)

run_this

if __name__ == "__main__":
    dag.cli()