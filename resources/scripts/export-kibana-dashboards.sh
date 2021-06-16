export_dot_env() {
  cd ../..
  export $(cat .env | xargs)
}

export_all_dashboards() {
  DASHBOARD_IDS=$(curl -u $ELASTICSEARCH_USERNAME:$ELASTICSEARCH_PASSWORD http://srv.meaningfy.ws:5601/api/saved_objects/_find?type=dashboard | jq -r ".saved_objects | .[] | .id")

  echo $DASHBOARD_IDS
  mkdir kibana_dashboards

  for DASHBOARD_ID in $DASHBOARD_IDS; do
    echo "Downloading dashboard with id = $DASHBOARD_ID"
    curl -u $ELASTICSEARCH_USERNAME:$ELASTICSEARCH_PASSWORD http://srv.meaningfy.ws:5601/api/kibana/dashboards/export?dashboard=$DASHBOARD_ID |
      jq -r '.objects' | jq -c '.' >kibana_dashboards/$DASHBOARD_ID.ndjson
  done
}

export_dot_env
export_all_dashboards
