export_dot_env() {
  cd ../..
  export $(cat .env | xargs)
}

import_dashboard() {
  FILE_CONTENT=$(cat $1 | jq -r '.')

  curl -X POST -u $ELASTICSEARCH_USERNAME:$ELASTICSEARCH_PASSWORD http://srv.meaningfy.ws:5601/api/saved_objects/_import?overwrite=true \
    -H 'kbn-xsrf: true' --form file=@$1
}

import_all_dashboard() {

  cd kibana_dashboards
  for file in *.ndjson; do
    import_dashboard $file
  done
}

export_dot_env
import_all_dashboard
