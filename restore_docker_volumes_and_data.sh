#!/bin/bash
# This script restores the backups for various docker containers

if [ $# -eq 0 ]; then
    echo "Please provide the directory within the backup archive from which the data will be loaded."
    exit 1
fi


timestamp=$1
echo "Attempting to load backups from" ~/.docker-backup/$timestamp

# Airflow section
make stop-airflow2
docker run --rm -v airflow2_postgres-db-volume-airflow:/var/lib/postgresql/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "rm -rf /var/lib/postgresql/data/* /var/lib/postgresql/data/..?* /var/lib/postgresql/data/.[!.]* ; tar -C /var/lib/postgresql/data/ -xvf /backup/airflow2_postgres_1.tar"
tar -xvf ~/.docker-backup/$timestamp/airflow2_dags.tar
tar -xvf ~/.docker-backup/$timestamp/airflow2_logs.tar
tar -xvf ~/.docker-backup/$timestamp/airflow2_plugins.tar
make start-airflow2

# ELK section
make stop-elk
tar -xvf ~/.docker-backup/$timestamp/elasticsearch_config.tar
docker run --rm -v elasticsearch:/usr/share/elasticsearch/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "rm -rf /usr/share/elasticsearch/data/* /usr/share/elasticsearch/data/..?* /usr/share/elasticsearch/data/.[!.]* ; tar -C /usr/share/elasticsearch/data/ -xvf /backup/elasticsearch_data.tar"
tar -xvf ~/.docker-backup/$timestamp/logstash_config.tar
tar -xvf ~/.docker-backup/$timestamp/logstash_pipeline.tar
tar -xvf ~/.docker-backup/$timestamp/kibana_config.tar
make start-elk

# MLFlow section
make stop-mlflow
docker run --rm -v postgres_store_mlflow:/var/lib/postgresql/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "rm -rf /var/lib/postgresql/data/* /var/lib/postgresql/data/..?* /var/lib/postgresql/data/.[!.]* ; tar -C /var/lib/postgresql/data/ -xvf /backup/mlflow_data.tar"
make start-mlflow


# # Notebook section
make stop-notebook
docker run --rm -v jupyter-notebook:/home/jovyan/work -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "rm -rf /home/jovyan/work/* /home/jovyan/work/..?* /home/jovyan/work/.[!.]* ; tar -C /home/jovyan/work/ -xvf /backup/notebook_data.tar"
make start-notebook


# # Storage section
make stop-storage
docker run --rm -v s3-disk:/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c "rm -rf /data/* /data/..?* /data/.[!.]* ; tar -C /data/ -xvf /backup/storage_data.tar"
make start-storage

# # Tika section
echo "Tika does not have any associated volumes."

# Storage section
make stop-vault
tar -xvf ~/.docker-backup/$timestamp/vault_config.tar
tar -xvf ~/.docker-backup/$timestamp/vault_policies.tar
tar -xvf ~/.docker-backup/$timestamp/vault_data.tar
make start-vault