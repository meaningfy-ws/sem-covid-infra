build-externals:
	@ echo "$(BUILD_PRINT)Creating the necessary volumes, networks and folders and setting the special rights"
	@ docker volume create jupyter-notebook
	@ docker volume create elasticsearch
	@ docker volume create s3-disk
	@ docker network create -d bridge elk || true

build-externals-extra:
	@ mkdir -p  ./airflow2/logs ./airflow2/plugins ./airflow2/dags
	@ chmod 777 ./airflow2/logs ./airflow2/plugins ./airflow2/dags

start-elk: build-externals
	@ echo "$(BUILD_PRINT)Starting the ELK and other services"
	@ docker-compose --file ./elk/docker-compose.yml --env-file ../.env up -d

stop-elk:
	@ echo "$(BUILD_PRINT)Stopping the ELK and other services"
	@ docker-compose --file ./elk/docker-compose.yml --env-file ../.env down

start-storage: build-externals
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


start-airflow2-build: build-externals
	@ echo "$(BUILD_PRINT)Starting the AirFlow services"
	@ echo "$(BUILD_PRINT)Warning: the Airflow shared folders, mounted as volumes, need R/W permissions"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env build --no-cache --force-rm
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env up -d --force-recreate

start-airflow2: build-externals
	@ echo "$(BUILD_PRINT)Starting the AirFlow services"
	@ echo "$(BUILD_PRINT)Warning: the Airflow shared folders, mounted as volumes, need R/W permissions"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env up -d

stop-airflow2:
	@ echo "$(BUILD_PRINT)Stopping the AirFlow services"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env down

start-notebook: build-externals
	@ echo "$(BUILD_PRINT)Starting the Jupyter Notebook services"
	@ docker-compose --file ./notebook/docker-compose.yml --env-file ../.env up -d

stop-notebook:
	@ echo "$(BUILD_PRINT)Stopping the Jupyter Notebook services"
	@ docker-compose --file ./notebook/docker-compose.yml --env-file ../.env down

start-vault:
	@ echo "$(BUILD_PRINT)Starting the Vault services"
	@ docker-compose --file ./vault/docker-compose.yml up -d

stop-vault:
	@ echo "$(BUILD_PRINT)Stopping the Vault services"
	@ docker-compose --file ./vault/docker-compose.yml down

start-tika:
	@ echo "$(BUILD_PRINT)Starting the Apache Tika services"
	@ docker-compose --file ./tika/docker-compose.yml --env-file ../.env up -d

stop-tika:
	@ echo "$(BUILD_PRINT)Stopping the Apache Tika services"
	@ docker-compose --file ./tika/docker-compose.yml --env-file ../.env down

start-services-all: | build-externals start-airflow2-build start-storage start-elk start-mlflow start-airflow2 start-tika start-notebook start-vault

stop-services-all: | stop-storage stop-elk stop-mlflow stop-airflow2 stop-vault stop-tika stop-notebook

all: start-services-all

# Getting secrets from Vault

# Testing whether an env variable is set or not
guard-%:
	@ if [ "${${*}}" = "" ]; then \
        echo "Environment variable $* not set"; \
        exit 1; \
	fi

# Testing that vault is installed
vault-installed:
	@ if ! hash vault 2>/dev/null; then \
        echo "Vault is not installed, refer to https://www.vaultproject.io/downloads"; \
        exit 1; \
	fi

# Get secrets in dotenv format
vault_secret_to_dotenv: guard-VAULT_ADDR guard-VAULT_TOKEN vault-installed
	@ echo "Writing the mfy/sem-covid secret from Vault to .env"
	@ vault kv get -format="json" mfy/sem-covid-infra | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" > .env
	@ vault kv get -format="json" mfy/jupyter-notebook | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" >> .env
	@ vault kv get -format="json" mfy/ml-flow | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" >> .env
	@ vault kv get -format="json" mfy/air-flow | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" >> .env
	@ vault kv get -format="json" mfy/min-io | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" >> .env
	@ vault kv get -format="json" mfy/elastic-search | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" >> .env
	@ vault kv get -format="json" mfy/sem-covid | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" >> .env

# Get secrets in json format
vault_secret_to_json: guard-VAULT_ADDR guard-VAULT_TOKEN vault-installed
	@ echo "Writing the mfy/sem-covid secret from Vault to variables.json"
	@ vault kv get -format="json" mfy/sem-covid-infra | jq -r ".data.data" > tmp1.json
	@ vault kv get -format="json" mfy/jupyter-notebook | jq -r ".data.data" > tmp2.json
	@ vault kv get -format="json" mfy/ml-flow | jq -r ".data.data" > tmp3.json
	@ vault kv get -format="json" mfy/air-flow | jq -r ".data.data" > tmp4.json
	@ vault kv get -format="json" mfy/min-io | jq -r ".data.data" > tmp5.json
	@ vault kv get -format="json" mfy/elastic-search | jq -r ".data.data" > tmp6.json
	@ vault kv get -format="json" mfy/sem-covid | jq -r ".data.data" > tmp7.json
	@ jq -s '.[0] * .[1] * .[2] * .[3] * .[4] * .[5] * .[6]' tmp*.json> variables.json
	@ rm tmp*.json

vault_secret_fetch: vault_secret_to_dotenv vault_secret_to_json


backup:
	@ echo "$(BUILD_PRINT)Creating backup for all services..."
	@ ./resources/scripts/backup_docker_volume_and_data.sh


restore:
	@ echo "$(BUILD_PRINT)Restoring backups for all services..."
	@ ./resources/scripts/restore_docker_volumes_and_data.sh $(source)

get-sem-covid-repository:
	@ echo "$(BUILD_PRINT)Getting the latest version fo teh repository..."
	@ if [ ! -d 'sem-covid' ]; then \
		git clone git@github.com:meaningfy-ws/sem-covid.git; \
	 else \
	   	echo "$(BUILD_PRINT)Folder **sem-covid** already exists"; \
  	 fi
	@ cd sem-covid && git checkout main && git pull origin


deploy-to-airflow: | build-externals-extra get-sem-covid-repository
	@ echo "$(BUILD_PRINT)Deploying into airflow ..."
	@ cd airflow2/dags  && rm -rf airflow2/dags/sem_covid
	@ cp -rf sem-covid/sem_covid airflow2/dags
	@ cp -rf sem-covid/resources airflow2/dags