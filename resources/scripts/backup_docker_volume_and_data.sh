#!/bin/bash
# This script creates backups for various docker containers

timestamp=$(date +%Y.%m.%d_at_%H.%M.%S)
mkdir -p ~/.docker-backup/$timestamp

function archive_and_save_to_location() {
  # This function will archive files from docker-backup and will put the archive file (.tar) in a specified location
  ARCHIVE_NAME=$1
  SAVE_LOCATION=$2
  tar cvf ~/.docker-backup/$timestamp/$ARCHIVE_NAME.tar $SAVE_LOCATION
}

function backup_data_for_service() {
  # this is taking the service name as a parameter and then will execute the necessary commands to backup that service
  SERVICE_NAME=$1
  case $SERVICE_NAME in
  airflow2)
    make stop-$SERVICE_NAME
    docker run --rm -v airflow2_postgres-db-volume-airflow:/var/lib/postgresql/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash \
    -c "cd /var/lib/postgresql/data && tar cvf /backup/airflow2_postgres_1.tar ."
    archive_and_save_to_location airflow2_dags ./airflow2/dags
    archive_and_save_to_location airflow2_logs ./airflow2/logs
    archive_and_save_to_location airflow2_plugins ./airflow2/plugins
    make start-$SERVICE_NAME
    ;;
  elk)
    make export-kibana-dashboards
    make stop-$SERVICE_NAME
    archive_and_save_to_location elasticsearch_config ./elk/elasticsearch/config
    docker run --rm -v elasticsearch:/usr/share/elasticsearch/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash \
    -c "cd /usr/share/elasticsearch/data && tar cvf /backup/elasticsearch_data.tar ."
    archive_and_save_to_location logstash_config ./elk/logstash/config
    archive_and_save_to_location logstash_pipeline ./elk/logstash/pipeline
    archive_and_save_to_location kibana_config ./elk/kibana/config
    make start-$SERVICE_NAME
    make import-kibana-dashboards
    ;;
  mlflow)
    make stop-$SERVICE_NAME
    docker run --rm -v postgres_store_mlflow:/var/lib/postgresql/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash \
    -c "cd /var/lib/postgresql/data && tar cvf /backup/mlflow_data.tar ."
    make start-$SERVICE_NAME
    ;;
  notebook)
    make stop-$SERVICE_NAME
    docker run --rm -v jupyter-notebook:/home/jovyan/work -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c \
    "cd /home/jovyan/work && tar cvf /backup/notebook_data.tar ."
    make start-$SERVICE_NAME
    ;;
  storage)
    make stop-$SERVICE_NAME
    docker run --rm -v s3-disk:/data -v ~/.docker-backup/$timestamp:/backup ubuntu bash -c \
    "cd /data && tar cvf /backup/storage_data.tar ."
    make start-$SERVICE_NAME
    ;;
  vault)
    make stop-$SERVICE_NAME
    archive_and_save_to_location vault_config ./vault/config
    archive_and_save_to_location vault_policies ./vault/policies
    archive_and_save_to_location vault_data ./vault/data
    make start-$SERVICE_NAME
    ;;
  esac
  echo "Service $SERVICE_NAME is backuped"
}

backup_data_for_service airflow2
backup_data_for_service elk
backup_data_for_service mlflow
backup_data_for_service notebook
backup_data_for_service storage
backup_data_for_service vault
