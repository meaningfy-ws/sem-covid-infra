#This script will export all kibana dashboards. As a parameter will take the full path to the folder that will be used
#to store the export files. Don't need to create the folder as the script will handle it.

FOLDER_PATH=$1

export_dot_env() {
  cd ../..
  export $(cat .env | xargs)
}

export_all_dashboards() {
  DASHBOARD_IDS=$(curl -u $ELASTICSEARCH_USERNAME:$ELASTICSEARCH_PASSWORD http://$ELASTICSEARCH_HOST_NAME:5601/api/saved_objects/_find?type=dashboard | jq -r ".saved_objects | .[] | .id")
  if [ -z "$DASHBOARD_IDS" ]; then
    echo "There are no dashboards to export from Kibana"
  else
    mkdir -p $1

    for DASHBOARD_ID in $DASHBOARD_IDS; do
      echo "Downloading dashboard with id = $DASHBOARD_ID"
      curl -u $ELASTICSEARCH_USERNAME:$ELASTICSEARCH_PASSWORD http://$ELASTICSEARCH_HOST_NAME:5601/api/kibana/dashboards/export?dashboard=$DASHBOARD_ID |
        jq -r '.objects' | jq -c '.' >$1/$DASHBOARD_ID.ndjson
    done
  fi
}

export_dot_env
export_all_dashboards $FOLDER_PATH
