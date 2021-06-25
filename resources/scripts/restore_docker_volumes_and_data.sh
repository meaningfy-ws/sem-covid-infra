#!/bin/bash
# This script restores the backups for various docker containers

if [ $# -eq 0 ]; then
    echo "Please provide the directory within the backup archive from which the data will be loaded."
    exit 1
fi


timestamp=$1
echo "Attempting to load backups from" ~/.docker-backup/$timestamp

function unzip_tar_file() {
  # this function will unzip a tar file
  tar -xvf ~/.docker-backup/$timestamp/$1.tar
}

function restore_data_for_service() {
  # this is taking the service name as a parameter and then will execute the necessary commands to restore that service
  SERVICE_NAME=$1
  case $SERVICE_NAME in
  airflow2)
    make stop-$SERVICE_NAME
    docker run --rm -v airflow2_postgres-db-volume-airflow:/var/lib/postgresql/data -v ~/.docker-backup/$timestamp:/backup \
    ubuntu bash -c "rm -rf /var/lib/postgresql/data/* /var/lib/postgresql/data/..?* /var/lib/postgresql/data/.[!.]* ; \
    tar -C /var/lib/postgresql/data/ -xvf /backup/airflow2_postgres_1.tar"
    unzip_tar_file airflow2_dags
    unzip_tar_file airflow2_logs
    unzip_tar_file airflow2_plugins
    make start-$SERVICE_NAME
    ;;
  elk)
    make stop-$SERVICE_NAME
    unzip_tar_file elasticsearch_config
    docker run --rm -v elasticsearch:/usr/share/elasticsearch/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c \
     "rm -rf /usr/share/elasticsearch/data/* /usr/share/elasticsearch/data/..?* /usr/share/elasticsearch/data/.[!.]* ; tar -C /usr/share/elasticsearch/data/ -xvf /backup/elasticsearch_data.tar"
    unzip_tar_file logstash_config
    unzip_tar_file logstash_pipeline
    unzip_tar_file kibana_config
    make start-$SERVICE_NAME
    make import-kibana-dashboards
    ;;
  mlflow)
    make stop-$SERVICE_NAME
    docker run --rm -v postgres_store_mlflow:/var/lib/postgresql/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash \
    -c "rm -rf /var/lib/postgresql/data/* /var/lib/postgresql/data/..?* /var/lib/postgresql/data/.[!.]* ; tar -C /var/lib/postgresql/data/ -xvf /backup/mlflow_data.tar"
    make start-$SERVICE_NAME
    ;;
  notebook)
    make stop-$SERVICE_NAME
    docker run --rm -v jupyter-notebook:/home/jovyan/work -v ~/.docker-backup/$timestamp:/backup ubuntu bash \
    -c "rm -rf /home/jovyan/work/* /home/jovyan/work/..?* /home/jovyan/work/.[!.]* ; tar -C /home/jovyan/work/ -xvf /backup/notebook_data.tar"
    make start-$SERVICE_NAME
    ;;
  storage)
    make stop-$SERVICE_NAME
    docker run --rm -v s3-disk:/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash \
    -c "rm -rf /data/* /data/..?* /data/.[!.]* ; tar -C /data/ -xvf /backup/storage_data.tar"
    make start-$SERVICE_NAME
    ;;
  vault)
    make stop-$SERVICE_NAME
    unzip_tar_file vault_config
    unzip_tar_file vault_policies
    unzip_tar_file vault_data
    make start-$SERVICE_NAME
    ;;
  esac
  echo "Service $SERVICE_NAME is restored"
}


restore_data_for_service airflow2
restore_data_for_service elk
restore_data_for_service mlflow
restore_data_for_service notebook
restore_data_for_service storage
restore_data_for_service vault