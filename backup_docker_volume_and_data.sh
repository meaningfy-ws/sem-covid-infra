#!/bin/bash

# This script creates backups for various docker containers
timestamp=$(date +%Y.%m.%d_at_%H.%M.%S)
mkdir -p ~/.docker-backup/$timestamp

# Airflow section
make stop-airflow2
docker run --rm -v airflow2_postgres-db-volume-airflow:/var/lib/postgresql/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "cd /var/lib/postgresql/data && tar cvf /backup/airflow2_postgres_1.tar ."
tar cvf ~/.docker-backup/$timestamp/airflow2_dags.tar ./airflow2/dags
tar cvf ~/.docker-backup/$timestamp/airflow2_logs.tar ./airflow2/logs
tar cvf ~/.docker-backup/$timestamp/airflow2_plugins.tar ./airflow2/plugins
make start-airflow2

# ELK section
make stop-elk
tar cvf ~/.docker-backup/$timestamp/elasticsearch_config.tar ./elk/elasticsearch/config
docker run --rm -v elasticsearch:/usr/share/elasticsearch/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "cd /usr/share/elasticsearch/data && tar cvf /backup/elasticsearch_data.tar ."
tar cvf ~/.docker-backup/$timestamp/logstash_config.tar ./elk/logstash/config
tar cvf ~/.docker-backup/$timestamp/logstash_pipeline.tar ./elk/logstash/pipeline
tar cvf ~/.docker-backup/$timestamp/kibana_config.tar ./elk/kibana/config
make start-elk

# MLFlow section
make stop-mlflow
docker run --rm -v postgres_store_mlflow:/var/lib/postgresql/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "cd /var/lib/postgresql/data && tar cvf /backup/mlflow_data.tar ."
make start-mlflow


# Notebook section
make stop-notebook
docker run --rm -v jupyter-notebook:/home/jovyan/work -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "cd /home/jovyan/work && tar cvf /backup/notebook_data.tar ."
make start-notebook


# Storage section
make stop-storage
docker run --rm -v s3-disk:/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "cd /data && tar cvf /backup/storage_data.tar ."
make start-storage

# Tika section
echo "Tika does not have any associated volumes."

# Storage section
make stop-vault
tar cvf ~/.docker-backup/$timestamp/vault_config.tar ./vault/config
tar cvf ~/.docker-backup/$timestamp/vault_policies.tar ./vault/policies
tar cvf ~/.docker-backup/$timestamp/vault_data.tar ./vault/data
make start-vault