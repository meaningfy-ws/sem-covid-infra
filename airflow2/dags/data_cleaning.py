#!/usr/bin/python3

# main.py
# Date:  16/03/2021
# Author: Chiriac Dan
# Email: dan.chiriac1453@gmail.com

import re
import pickle
import string
import hashlib
import json
import logging
import requests
from jq import compile
from json import dumps, loads
from datetime import datetime, timedelta

import pandas as pd
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator

from dagtools.pwdb_transformer import get_transformation_rules, transform_json_to_csv
from dagtools.feature_selector import reduce_array_column, multi_label_column_to_binary_columns
from dagtools.data_cleaner import prepare_text_for_cleaning
from dagtools.miniotools import MinioAdapter

logger = logging.getLogger('lam-fetcher')
VERSION = '0.6.8'

ML_EXPERIMENTS_BUCKET_NAME = "ml-experiments"
SC_COVID_DATASET = "pwdb_dataset.pkl"
SC_COVID_JSON = "covid19.json"

dataset_url = Variable.get("PWDB_DATASET_URL")
minio_url = Variable.get("MINIO_URL")
minio_access_key = Variable.get("MINIO_ACCESS_KEY")
minio_secret_key = Variable.get("MINIO_SECRET_KEY")


transformation = '''{
"Identifier": .recordId,
"Title": .fieldData.title,
"Title (national language)": .fieldData.title_nationalLanguage,
"Country": .fieldData.calc_country,
"Start date": .fieldData.d_startDate,
"End date": .fieldData.d_endDate,
"Date type": .fieldData.dateType,
"Type of measure": .fieldData.calc_type,
"Status of regulation": .fieldData.statusOfRegulation,
"Category": .fieldData.calc_minorCategory,
"Subcategory": .fieldData.calc_subMinorCategory,
"Case added": .fieldData.calc_creationDay,
"Background information": .fieldData.descriptionBackgroundInfo,
"Content of measure": .fieldData.descriptionContentOfMeasure,
"Use of measure": .fieldData.descriptionUseOfMeasure,
"Actors": [.portalData.actors[] |  ."actors::name" ],
"Target groups": [.portalData.targetGroups[] | ."targetGroups::name"],
"Funding": [.portalData.funding[] | ."funding::name" ],
"Views of social partners": .fieldData.descriptionInvolvementOfSocialPartners,
"Form of social partner involvement": .fieldData.socialPartnerform,
"Role of social partners": .fieldData.socialPartnerrole,
"Is sector specific": .fieldData.isSector,
"Private or public sector": .fieldData.sector_privateOrPublic,
"Is occupation specific": .fieldData.isOccupation,
"Sectors": [.portalData.sectors[] | ."sectors::name" ],
"Occupations": [.portalData.occupations[] | .],
"Sources": [.portalData.sources[] | ."sources::url" ],
}'''

SEARCH_RULE = ".[] | "


def download_dataset():
    response = requests.get(dataset_url, stream=True, timeout=30)
    response.raise_for_status()
    minio = MinioAdapter(minio_url, minio_access_key, minio_secret_key, ML_EXPERIMENTS_BUCKET_NAME)
    minio.empty_bucket()
    transformed_json = compile(get_transformation_rules(transformation)).input(loads(response.content)).all()
    uploaded_bytes = minio.put_object(SC_COVID_JSON, dumps(transformed_json).encode('utf-8'))
    logger.info('Uploaded ' + str(uploaded_bytes) + ' bytes to bucket [' + ML_EXPERIMENTS_BUCKET_NAME + '] at ' + minio_url)


def save_as_dataframe():
    response = requests.get(dataset_url, stream=True, timeout=30)
    minio = MinioAdapter(minio_url, minio_access_key, minio_secret_key, ML_EXPERIMENTS_BUCKET_NAME)
    data = json.loads(minio.get_object(SC_COVID_JSON).decode('utf-8'))
    dataframe_from_json = pd.DataFrame.from_records(data)
    convert_to_pickle = pickle.dumps(dataframe_from_json)
    uploaded_pickle = minio.put_object("pwdb_dataset.pkl", convert_to_pickle)
    logger.info(loads(response.content))
    logger.info('Uploaded ' + str(uploaded_pickle) + ' pickle to bucket [' + ML_EXPERIMENTS_BUCKET_NAME + '] at ' + minio_url)


def prepare_data():
    minio = MinioAdapter(minio_url, minio_access_key, minio_secret_key, ML_EXPERIMENTS_BUCKET_NAME)
    dataframe = pickle.loads(minio.get_object(SC_COVID_DATASET))
    reducer = reduce_array_column(dataframe, "Target groups")
    df = reducer[['Title', 'Background information', 'Content of measure',
                  'Category', 'Subcategory', 'Type of measure', 'Target groups']]
    df_columns = df['Title'].map(str) + df['Background information'].map(str) + df['Content of measure'].map(str)
    df_columns = pd.DataFrame(df_columns, columns=['Concatenated Data'])
    df['Concatenated Data'] = df_columns
    clean = lambda x: prepare_text_for_cleaning(x)
    df['Concatenated Data (clean)'] = df['Concatenated Data'].apply(clean)
    save_to_pickle = pickle.dumps(df)
    minio.put_object("clean_dataset.pkl", save_to_pickle)



default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2021, 3, 17),
    "email": ["dan.chiriac1453@gmail.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    "retry_delay": timedelta(minutes=3600)
}

dag = DAG('ml_experiment_prepare_ver_' + VERSION,
          default_args=default_args,
          schedule_interval="@once",
          max_active_runs=1,
          concurrency=1)


download_task = PythonOperator(task_id='Download',
                               python_callable=download_dataset, retries=1, dag=dag)

save_dataframe_task = PythonOperator(task_id='Transform',
                                python_callable=save_as_dataframe, retries=1, dag=dag)

prepare_data_task = PythonOperator(task_id='Prepare',
                                python_callable=prepare_data, retries=1, dag=dag)


download_task >> save_dataframe_task >> prepare_data_task
