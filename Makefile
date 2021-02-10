build-volumes:
	@ docker volume create jupyter-notebook
	@ mkdir ./airflow2/logs
	@ mkdir ./airflow2/plugins
	@ mkdir ./airflow2/dags

start-elk: build-volumes
	@ echo "$(BUILD_PRINT)Starting the ELK and other services"
	@ docker-compose --file docker-compose.yml --env-file .env up -d

stop-elk:
	@ echo "$(BUILD_PRINT)Stopping the ELK and other services"
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
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env up -d

stop-airflow2:
	@ echo "$(BUILD_PRINT)Stopping the AirFlow services"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env down


start-services-all: | build-volumes start-storage start-elk start-mlflow start-airflow2

stop-services-all: | build-volumes start-storage start-elk start-mlflow start-airflow2

all: start-services-all
