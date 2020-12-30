build-volumes:
	@ docker volume create jupyter-notebook

start-services: build-volumes
	@ echo "$(BUILD_PRINT)Starting the Docker compose services"
	@ docker-compose --file docker-compose.yml  --env-file .env up -d
	@# docker logs --tail 3 jupyter-notebook-srv

stop-services:
	@ echo "$(BUILD_PRINT)Stopping the Docker compose services"
	@ docker-compose --file docker-compose.yml --env-file .env down
