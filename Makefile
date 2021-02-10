build-volumes:
	@ docker volume create jupyter-notebook
#	@ docker volume create mlflow_dbdata
#	@ docker volume create mlflow_artifacts

start-services: build-volumes
	@ echo "$(BUILD_PRINT)Starting the Docker compose services"
#	@ docker volume create --name=jupyter-notebook
#	@ docker volume create --name=mlflow_artifacts
# 	@ docker volume create --name=postgres_store
	@ docker-compose --file docker-compose.yml --env-file .env up -d
# 	@ docker logs --tail 3 jupyter-notebook-srv

stop-services:
	@ echo "$(BUILD_PRINT)Stopping the Docker compose services"
	@ docker-compose --file docker-compose.yml --env-file .env down

start-storage:
	@ echo "$(BUILD_PRINT)Starting the File Storage services"
	@ docker-compose --file ./storage/docker-compose.yml --env-file ../.env up -d

stop-storage:
	@ echo "$(BUILD_PRINT)Stopping the File Storage services"
	@ docker-compose --file ./storage/docker-compose.yml --env-file ../.env down

start-mlflow:
	@ echo "$(BUILD_PRINT)Starting the MLFlow services"
	@ docker-compose --file ./mlflow/docker-compose.yml --env-file ../.env up -d

stop-mlflow:
	@ echo "$(BUILD_PRINT)Stopping the MLFlow services"
	@ docker-compose --file ./mlflow/docker-compose.yml --env-file ../.env down

start-airflow2:
	@ echo "$(BUILD_PRINT)Starting the AirFlow services"
	@ echo "$(BUILD_PRINT)Warning: the shared folders need R/W permissions"
	@ mkdir ./airflow2/logs
	@ mkdir ./airflow2/plugins
	@ mkdir ./airflow2/dags
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env up -d

stop-airflow2:
	@ echo "$(BUILD_PRINT)Stopping the AirFlow services"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env down

