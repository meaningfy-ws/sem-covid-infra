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
The stack is pre-configured with the following **privileged** bootstrap user:

* user: *elastic*
* password: *changeme*

The ELK users and password MUST be changed. Please refer to [THIS page](https://github.com/deviantony/docker-elk#initial-setup) for additional information on how to increase the ELK security. 

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
To start teh services
```shell script
make start-airflow2
```
To stop teh services
```shell script
make stop-airflow2
```

In you need to rebuild teh services (for example because you changed teh dependencies in the requirements.txt) the use this make target

```shell script
make start-airflow2-build
```

The Airflow2 uses three bind mounts instead of volumes in order to facilitate managements of DAGs. Make sure that the three folders have R/W access for all users (this it probably bad idea, but it works for now). In the future recur to using Docker volumes.
 
This setup of Airflow uses Celery workers which can be monitored using Flower service (by default accessible on :5555 port). 

**Custom pip libraries**

The custom `Dockerfile` is there merely for injecting pip libraries into teh Airflow image. The `requirements.txt` is the place where necessary dependencies are specified. Use it at will but wisely.

**Loading variables**

In case you need to inject variables into the Airflow perform teh following steps.
1. copy the JSON with with variables into teh `./dags` folder
2. execute `load_variables.sh` to lad the variables into the Airflow

Usage:
```
load_variables.sh <variables_file.json> <airflow_container_name>"
```
Note: `variables_file.json` MUST be available in the *./dags* folder. 

**Loading custom modules**

Custom modules will be available to deployed DAGs if they are copied into one of these folders:
* `./dags`
* `./plugins`

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0)
