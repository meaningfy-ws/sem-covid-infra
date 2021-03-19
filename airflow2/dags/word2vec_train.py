#!/usr/bin/python3

# main.py
# Date:  17/03/2021
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
from gensim.models import Word2Vec, KeyedVectors

from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator

from dagtools.miniotools import MinioAdapter

logger = logging.getLogger('lam-fetcher')
VERSION = '0.4.3'

ML_EXPERIMENTS_BUCKET_NAME = "ml-experiments"
WORD2VEC_MODEL = "word2vec.pkl"
SC_COVID_PREPARED_DATASET = "clean_dataset.pkl"

dataset_filename = Variable.get("SC_COVID_PREPARED_DATASET")
model_filename = Variable.get("WORD2VEC_MODEL")
dataset_url = Variable.get("PWDB_DATASET_URL")
minio_url = Variable.get("MINIO_URL")
minio_bucket = Variable.get("ML_EXPERIMENTS_BUCKET_NAME")
minio_access_key = Variable.get("MINIO_ACCESS_KEY")
minio_secret_key = Variable.get("MINIO_SECRET_KEY")


def word2vec_model_training():
    minio = MinioAdapter(minio_url, minio_access_key, minio_secret_key, ML_EXPERIMENTS_BUCKET_NAME)
    df = pickle.loads(minio.get_object(SC_COVID_PREPARED_DATASET))
    column = df['Concatenated Data (clean)']
    logger.info(column)
    dfVec = Word2Vec(column, window=5, min_count=10, size=300)
    logger.info(dfVec)
    w2v_saving = pickle.dumps(dfVec)
    logger.info("Save the model: " + str(w2v_saving))
    upload_model = minio.put_object("word2vec.gensim.model", w2v_saving)
    logger.info('the model: ' + str(upload_model))


def testing():
    minio = MinioAdapter(minio_url, minio_access_key, minio_secret_key, ML_EXPERIMENTS_BUCKET_NAME)
    model = pickle.loads(minio.get_object(WORD2VEC_MODEL))
    testing = model.most_similar('covid')
    logger.info(testing)


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

dag = DAG('word2vec_training_ver_' + VERSION,
          default_args=default_args,
          schedule_interval="@once",
          max_active_runs=1,
          concurrency=1)


train_task = PythonOperator(task_id='Word2vec',
                            python_callable=word2vec_model_training, retries=1, dag=dag)

testing_word2vec_task = PythonOperator(task_id='Testing',
                                       python_callable=testing, retries=1, dag=dag)

train_task >> testing_word2vec_task