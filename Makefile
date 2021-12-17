build-externals:
	@ echo "$(BUILD_PRINT)Creating the necessary volumes, networks and folders and setting the special rights"
	@ docker volume create jupyter-notebook
	@ docker volume create elasticsearch
	@ docker volume create s3-disk
	@ docker network create -d bridge elk || true

build-externals-extra:
	@ mkdir -p  ./airflow2/logs ./airflow2/plugins ./airflow2/dags
	@ chmod 777 ./airflow2/logs ./airflow2/plugins ./airflow2/dags
	@ mkdir -p  ./vault/data ./vault/policies
	@ chmod 777  ./vault/data ./vault/policies

start-elk: build-externals
	@ echo "$(BUILD_PRINT)Starting the ELK and other services"
	@ docker-compose --file ./elk/docker-compose.yml --env-file .env up --build -d

stop-elk:
	@ echo "$(BUILD_PRINT)Stopping the ELK and other services"
	@ docker-compose --file ./elk/docker-compose.yml --env-file .env down

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

start-notebook: build-externals
	@ echo "$(BUILD_PRINT)Starting the Jupyter Notebook services"
	@ docker-compose --file ./notebook/docker-compose.yml --env-file ../.env up -d

start-notebook-build: build-externals get-sem-covid-repository
	@ echo "$(BUILD_PRINT)Rebuildig the image and then starting the Jupyter Notebook services"
	@ echo "$(BUILD_PRINT)Expecting to find sem-covid repo in .airflow2/sem-covid folder"
	@ cp airflow2/sem-covid/requirements-dev.txt notebook/
	@ docker stop `docker ps -q --filter ancestor=notebook_meaningfy` || true
	@ docker container prune -f
	@ docker image rm notebook_meaningfy || true
	@ docker-compose --file ./notebook/docker-compose.yml --env-file ../.env build --no-cache --force-rm
	@ docker-compose --file ./notebook/docker-compose.yml --env-file ../.env up -d --force-recreate
	@ rm notebook/requirements-dev.txt || true

stop-notebook:
	@ echo "$(BUILD_PRINT)Stopping the Jupyter Notebook services"
	@ docker-compose --file ./notebook/docker-compose.yml --env-file ../.env down

start-vault: build-externals-extra
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

start-services-all: | build-externals start-storage start-elk start-mlflow start-airflow2 start-tika start-notebook start-vault import-kibana-dashboards

stop-services-all: | export-kibana-dashboards stop-storage stop-elk stop-mlflow stop-airflow2 stop-vault stop-tika stop-notebook

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
	@ vault kv get -format="json" mfy/vault | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" >> .env

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
	@ vault kv get -format="json" mfy/vault | jq -r ".data.data" > tmp8.json
	@ jq -s '.[0] * .[1] * .[2] * .[3] * .[4] * .[5] * .[6] * .[7]' tmp*.json> variables.json
	@ rm tmp*.json

vault_secret_to_json_separated: guard-VAULT_ADDR guard-VAULT_TOKEN vault-installed
	@ echo "Writing the mfy/sem-covid secret from Vault to own files"
	@ vault kv get -format="json" mfy/sem-covid-infra | jq -r ".data.data" > sem-covid-infra.json
	@ vault kv get -format="json" mfy/jupyter-notebook | jq -r ".data.data" > jupyter-notebook.json
	@ vault kv get -format="json" mfy/ml-flow | jq -r ".data.data" > ml-flow.json
	@ vault kv get -format="json" mfy/air-flow | jq -r ".data.data" > air-flow.json
	@ vault kv get -format="json" mfy/min-io | jq -r ".data.data" > min-io.json
	@ vault kv get -format="json" mfy/elastic-search | jq -r ".data.data" > elastic-search.json
	@ vault kv get -format="json" mfy/sem-covid | jq -r ".data.data" > sem-covid.json
	@ vault kv get -format="json" mfy/vault | jq -r ".data.data" > vault.json

vault_secret_to_json_separated_dev: guard-VAULT_ADDR guard-VAULT_TOKEN vault-installed
	@ echo "Writing the mfy/sem-covid secret from Vault to own files"
	@ vault kv get -format="json" mfy-dev/sem-covid-infra | jq -r ".data.data" > sem-covid-infra.json
	@ vault kv get -format="json" mfy-dev/jupyter-notebook | jq -r ".data.data" > jupyter-notebook.json
	@ vault kv get -format="json" mfy-dev/ml-flow | jq -r ".data.data" > ml-flow.json
	@ vault kv get -format="json" mfy-dev/air-flow | jq -r ".data.data" > air-flow.json
	@ vault kv get -format="json" mfy-dev/min-io | jq -r ".data.data" > min-io.json
	@ vault kv get -format="json" mfy-dev/elastic-search | jq -r ".data.data" > elastic-search.json
	@ vault kv get -format="json" mfy-dev/sem-covid | jq -r ".data.data" > sem-covid.json
	@ vault kv get -format="json" mfy-dev/vault | jq -r ".data.data" > vault.json

vault_secret_fetch: vault_secret_to_dotenv vault_secret_to_json


backup:
	@ echo "$(BUILD_PRINT)Creating backup for all services..."
	@ ./resources/scripts/backup_docker_volume_and_data.sh


restore:
	@ echo "$(BUILD_PRINT)Restoring backups for all services..."
	@ ./resources/scripts/restore_docker_volumes_and_data.sh $(source)

#
# The Airflow Enterprise for the Sem Covid project
#

# downloading the sem-covid repository
get-sem-covid-repository:
	@ echo "$(BUILD_PRINT)Getting the latest version fo teh repository..."
	@ if [ ! -d 'airflow2/sem-covid' ]; then \
		mkdir -p airflow2/sem-covid; \
		git clone https://github.com/meaningfy-ws/sem-covid.git airflow2/sem-covid; \
	 else \
	   	echo "$(BUILD_PRINT)Folder **sem-covid** already exists"; \
  	 fi
	@ cd airflow2/sem-covid && git checkout main && git pull origin

start-airflow2-build: build-externals get-sem-covid-repository
	@ echo "$(BUILD_PRINT)Rebuildig the image and then starting the AirFlow services. "
	@ echo "$(BUILD_PRINT)Expecting to find sem-covid repo in .airflow2/sem-covid folder"
	@ echo "$(BUILD_PRINT)The Dockerfile will be fetched from teh sem-covid repository"
	@ echo "$(BUILD_PRINT)Warning: the Airflow shared folders, mounted as volumes, need R/W permissions"
	@ cp airflow2/sem-covid/docker/airflow/Dockerfile airflow2/
	@ cp airflow2/sem-covid/requirements-airflow.txt airflow2/
	@ docker stop `docker ps -q --filter ancestor=airflow2_meaningfy` || true
	@ docker container prune -f
	@ docker image rm airflow2_meaningfy || true
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file .env build --no-cache --force-rm
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file .env up -d --force-recreate
	@ rm airflow2/requirements-airflow.txt || true

start-airflow2: build-externals
	@ echo "$(BUILD_PRINT)Starting the AirFlow services"
	@ echo "$(BUILD_PRINT)Warning: the Airflow shared folders, mounted as volumes, need R/W permissions"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env up -d

stop-airflow2:
	@ echo "$(BUILD_PRINT)Stopping the AirFlow services"
	@ docker-compose --file ./airflow2/docker-compose.yml --env-file ../.env down

start-lang-model-explorer-build: get-sem-covid-repository vault_secret_to_dotenv
	@ echo "$(BUILD_PRINT)Starting the lang-model-explorer services"
	@ cp -rf airflow2/sem-covid lang-model-explorer
	@ cp .env lang-model-explorer
	@ docker container prune -f
	@ docker image rm lang-model-explorer_lang-model-explorer || true
	@ docker-compose --file ./lang-model-explorer/docker-compose.yml --env-file ../.env build --no-cache --force-rm
	@ docker-compose --file ./lang-model-explorer/docker-compose.yml --env-file ../.env up -d --force-recreate

stop-lang-model-explorer:
	@ echo "$(BUILD_PRINT)Stopping the lang-model-explorer services"
	@ docker-compose --file ./lang-model-explorer/docker-compose.yml --env-file ../.env down

start-semantic-similarity-explorer-build: get-sem-covid-repository vault_secret_to_dotenv
	@ echo "$(BUILD_PRINT)Starting the semantic-similarity-explorer services"
	@ cp -rf airflow2/sem-covid semantic-similarity-explorer
	@ cp .env semantic-similarity-explorer
	@ docker container prune -f
	@ docker image rm semantic-similarity-explorer_semantic-similarity-explorer || true
	@ docker-compose --file ./semantic-similarity-explorer/docker-compose.yml --env-file ../.env build --no-cache --force-rm
	@ docker-compose --file ./semantic-similarity-explorer/docker-compose.yml --env-file ../.env up -d --force-recreate

stop-semantic-similarity-explorer:
	@ echo "$(BUILD_PRINT)Stopping the semantic-similarity-explorer services"
	@ docker-compose --file ./semantic-similarity-explorer/docker-compose.yml --env-file ../.env down

start-topic-modeling-build: get-sem-covid-repository vault_secret_to_dotenv
	@ echo "$(BUILD_PRINT)Starting the topic-modeling services"
	@ cp -rf airflow2/sem-covid topic-modeling
	@ cp .env topic-modeling
	@ docker container prune -f
	@ docker image rm topic-modeling_topic-modeling || true
	@ docker-compose --file ./topic-modeling/docker-compose.yml --env-file ../.env build --no-cache --force-rm
	@ docker-compose --file ./topic-modeling/docker-compose.yml --env-file ../.env up -d --force-recreate

stop-topic-modeling:
	@ echo "$(BUILD_PRINT)Stopping the topic-modeling services"
	@ docker-compose --file ./topic-modeling/docker-compose.yml --env-file ../.env down

start-topic-explorer-build: get-sem-covid-repository vault_secret_to_dotenv
	@ echo "$(BUILD_PRINT)Starting the topic-explorer services"
	@ cp -rf airflow2/sem-covid topic-explorer
	@ cp .env topic-explorer
	@ docker container prune -f
	@ docker image rm topic-explorer_topic-explorer || true
	@ docker-compose --file ./topic-explorer/docker-compose.yml --env-file ../.env build --no-cache --force-rm
	@ docker-compose --file ./topic-explorer/docker-compose.yml --env-file ../.env up -d --force-recreate

stop-topic-explorer:
	@ echo "$(BUILD_PRINT)Stopping the topic-explorer services"
	@ docker-compose --file ./topic-explorer/docker-compose.yml --env-file ../.env down

# when the Airflow service runs, this target deploys a fresh version of teh sem-covid repos
deploy-to-airflow: | build-externals-extra get-sem-covid-repository
	@ echo "$(BUILD_PRINT)Deploying into running Airflow ..."
	@ rm -rf airflow2/dags/*
	@ cp -rf airflow2/sem-covid/sem_covid airflow2/dags
	@ cp -rf airflow2/sem-covid/resources airflow2/dags


export-kibana-dashboards:
	@ echo "$(BUILD_PRINT)Exporting Kibana dashboards..."
	@ ./resources/scripts/export-kibana-dashboards.sh ../kibana_dashboards

import-kibana-dashboards:
	@ echo "$(BUILD_PRINT)Importing Kibana dashboards..."
	@ ./resources/scripts/import-kibana-dashboards.sh ../kibana_dashboards


start-rml-mapper-build:
	@ echo "$(BUILD_PRINT)Starting the rml-mapper services"
	@ rm -rf ./rml-mapper/build
	@ mkdir -p ./rml-mapper/build
	@ git clone https://github.com/RMLio/rmlmapper-webapi-js.git ./rml-mapper/build
	@ docker container prune -f
	@ docker-compose --file ./rml-mapper/docker-compose.yaml up -d --force-recreate

stop-rml-mapper:
	@ echo "$(BUILD_PRINT)Stopping the rml-mapper services"
	@ docker-compose --file ./rml-mapper/docker-compose.yaml down

