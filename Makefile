build-volumes:
	@ echo "$(BUILD_PRINT)Creating the necessary volumes and folders and setting special rights"
	@ docker volume create jupyter-notebook
	@ sudo mkdir -p  ./airflow2/logs ./airflow2/plugins ./airflow2/dags
	@ sudo chmod 777 ./airflow2/logs ./airflow2/plugins ./airflow2/dags

build-network:
	@ docker network create -d bridge elk

start-elk:
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

start-mlflow: start-storage
	@ echo "$(BUILD_PRINT)Starting the MLFlow services"
	@ docker-compose --file ./mlflow/docker-compose.yml --env-file ../.env up -d

stop-mlflow:
	@ echo "$(BUILD_PRINT)Stopping the MLFlow services"
	@ docker-compose --file ./mlflow/docker-compose.yml --env-file ../.env down

start-airflow2: build-volumes start-storage
	@ echo "$(BUILD_PRINT)Starting the AirFlow services"
	@ echo "$(BUILD_PRINT)Warning: the shared folders need R/W permissions"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env up -d

stop-airflow2:
	@ echo "$(BUILD_PRINT)Stopping the AirFlow services"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env down

start-tika: build-volumes start-storage
	@ echo "$(BUILD_PRINT)Starting Apache Tika"
	@ echo "$(BUILD_PRINT)Warning: the shared folders need R/W permissions"
	@ docker-compose --file docker-compose.yml --env-file .env up -d apache_tika

stop-tika:
	@ echo "$(BUILD_PRINT)Stopping Apache Tika"
	@ docker-compose --file docker-compose.yml --env-file .env down

start-elk: build-volumes start-storage
	@ echo "$(BUILD_PRINT)Starting ELK"
	@ echo "$(BUILD_PRINT)Warning: the shared folders need R/W permissions"
	@ docker-compose --file docker-compose.yml --env-file .env up -d elasticsearch logstash kibana

start-notebook: build-volumes
	@ echo "$(BUILD_PRINT)Starting the Jupyter Notebook services"
	@ docker-compose --file ./notebook/docker-compose.yml --env-file ../.env up -d

stop-notebook:
	@ echo "$(BUILD_PRINT)Stopping the Jupyter Notebook services"
	@ docker-compose --file ./notebook/docker-compose.yml --env-file ../.env down

start-services-all: | build-network build-volumes start-storage start-elk start-mlflow start-airflow2

stop-services-all: | build-volumes start-storage start-elk start-mlflow start-airflow2

all: start-services-all
