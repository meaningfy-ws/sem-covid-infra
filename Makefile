build-volumes:
	@ docker volume create jupyter-notebook
	@ docker volume create mlflow_dbdata
	@ docker volume create mlflow_artifacts

start-services: build-volumes
	@ echo "$(BUILD_PRINT)Starting the Docker compose services"
	@ docker volume create --name=jupyter-notebook
	@ docker volume create --name=mlflow_artifacts
# 	@ docker volume create --name=postgres_store
	@ docker-compose --file docker-compose.yml --env-file .env up -d
# 	@ docker logs --tail 3 jupyter-notebook-srv

stop-services:
	@ echo "$(BUILD_PRINT)Stopping the Docker compose services"
	@ docker-compose --file docker-compose.yml --env-file .env down


 start-airflow2:
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file .env up -d

 stop-airflow2:
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file .env down

 start-minio:
	@ docker-compose --file docker-compose.yml --env-file .env up -d minio-s3

 stop-minio:
	@ docker-compose --file docker-compose.yml --env-file .env down minio-s3