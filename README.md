# Meaningfy infrastructure stack 

A docker-compose suite of service configurations representing the Meaningfy infrastructure stack for Machine Learning and Data Driven applications.

This suite contains teh following services (and related dependencies):
* Elasticsearch, Logstash & Kibana (ELK) service stack
* Jupiter Notebook & a SFTP service with a common `/work` space
* Min.io object storage service 
* MLFlow experiment management service
* AirFlow workflow management system (currently deployed with Celery & Redis services)

## Installation

```shell script
git clone https://github.com/meaningfy-ws/docker-elk-ml
```

Install Docker and Docker-compose
* Install [Docker Community Edition (CE)](https://docs.docker.com/engine/installation/)
* Install [Docker Compose v1.27.0 and newer](https://docs.docker.com/compose/install/)

Note: Older versions of `docker-compose` do not support all features required by `docker-compose.yaml` file, so double check that it meets the minimum version requirements.

## Usage

Starting all services at once
```shell script
make start-services-all
```
Stopping all the services can be done with 
```shell script
make stop-services-all
```
##### ELK services
```shell script
make start-elk
```
```shell script
make stop-elk
```
##### Jupyter Notebook services
```shell script
make start-notebook
```
```shell script
make stop-notebook
```
##### Storage services
```shell script
make start-storage
```
```shell script
make stop-storage
```
##### MLFlow experiment management service
```shell script
make start-mlflow
```
```shell script
make stop-mlflow
```

Make sure that there is a bucket called `mlflow` in the Min.io service.

To test that the MLFlow service works as expected by running on a local machine (not the server) teh script `./mlflow/test_bash_ml_flow.sh`. 

Make sure that the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables are set in order to grant access to the Min.io bucket. Also make sure that teh Min.io hostname is also set properly.    


##### Airflow services
```shell script
make start-airflow2
```
```shell script
make stop-airflow2
```


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0)
