#!/bin/bash

source .env

export AWS_ACCESS_KEY_ID=$MINIO_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$MINIO_SECRET_KEY
export MLFLOW_S3_ENDPOINT_URL=$MLFLOW_S3_ENDPOINT_URL
export MLFLOW_TRACKING_URI=$MLFLOW_TRACKING_URI

echo "[ OK ] Successfully set the environment variables!"

python tests/ml_flow_demo.py