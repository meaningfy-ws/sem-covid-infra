#!/bin/bash

# This script lookup all json files in the ./dag folder containing the word "variable"
# in their names and loads them as airflow variables.

# load airflow variables
# param1: variable_file.json
# param2: airflow_container
function load_variables() {
  local default_container_name="airflow2_airflow-webserver_1"
  local variable_file="${1}"
  local airflow_container="${2:-$default_container_name}"
  [[ -z "$variable_file" ]] && { echo "JSON file: Variable file not found"; exit 1; }
  echo "[ Info ] Loading the *$variable_file* variable file into the *$airflow_container* Airflow server"
  docker exec -ti airflow2_airflow-webserver_1 /bin/bash -c "airflow variables import /opt/airflow/dags/variables.json"
}

echo "[ Usage ] <variables_file.json> <airflow_container_name>"
echo "[ Note ] variables_file.json MUST be available in the *./dags* folder."
load_variables "$@"