#This script will import all kibana dashboards that were exported in a folder. The script will not run if the folder
#doesn't exist or if empty. If the dashboards will exist in Kibana this will overwrite them

FOLDER_PATH=$1

export_dot_env() {
  cd ../..
  export $(cat .env | xargs)
}

import_dashboard() {
  FILE_CONTENT=$(cat $1 | jq -r '.')

  curl -X POST -u $ELASTICSEARCH_USERNAME:$ELASTICSEARCH_PASSWORD http://$ELASTICSEARCH_HOST_NAME:5601/api/saved_objects/_import?overwrite=true \
    -H 'kbn-xsrf: true' --form file=@$1
}

import_all_dashboards() {

  cd $1
  for file in *.ndjson; do
    import_dashboard $file
  done
}

# if the folder exists and is not empty
if [ -d "$FOLDER_PATH" ] && [ "$(ls -A $FOLDER_PATH)" ]; then
  export_dot_env
  import_all_dashboards $FOLDER_PATH

else
  echo "Nothing to import as there is no folder with exported dashboards or the folder is empty."
fi
