#!/bin/bash
# This script bootstraps the vault

DEFAULT_PASSWORD=changeme
DEFAULT_POLICY=default

TMP_ACCESSOR_FILE=tmp_accessor.txt
TMP_ID_FILE=tmp_id.txt

enable_features() {
  # Enable kv v2 called mfy
  vault secrets enable -version=2 -path=mfy kv
  vault auth enable userpass
  vault auth enable github
}

enable_github_to_meanigfy() {
  vault write auth/github/config organization=meaningfy-ws
}

update_default_policy() {
  vault policy write default default_vault_policy.hcl
}

tmp_accessor_userpass() {
  # create temporary accessor file with the userpass id
  rm -f $TMP_ACCESSOR_FILE
  vault auth list -format=json | jq -r '.["userpass/"].accessor' >$TMP_ACCESSOR_FILE
}

tmp_accessor_github() {
  # create temporary accessor file with the github id
  rm -f $TMP_ACCESSOR_FILE
  vault auth list -format=json | jq -r '.["github/"].accessor' >$TMP_ACCESSOR_FILE
}

create_dual_aliased_entity() {
  # create teh entities and assign the userpass and github aliases
  echo "Creating $1 named entity with userpass and GitHub alias $2"
  clean_tmp
  # creating teh entity
  vault write identity/entity -format=json name="$1" policies="default" metadata=organisation="Meaningfy.ws" metadata=team="Development" | jq -r '.data.id' >$TMP_ID_FILE
  # creating and assigning the userpass user to the entity
  tmp_accessor_userpass
  vault write auth/userpass/users/$2 password="$DEFAULT_PASSWORD" policies="$DEFAULT_POLICY"
  vault write identity/entity-alias name="$2" canonical_id=$(cat $TMP_ID_FILE) mount_accessor=$(cat $TMP_ACCESSOR_FILE)
  # assigning the github user to the entity
  tmp_accessor_github
  vault write identity/entity-alias name="$2" canonical_id=$(cat $TMP_ID_FILE) mount_accessor=$(cat $TMP_ACCESSOR_FILE)
}

create_github_aliased_entity() {
  # create teh entities and assign the GitHub aliases;
  echo "Creating $1 named entity with GitHub alias $2"
  clean_tmp
  # creating teh entity
  vault write identity/entity -format=json name="$1" policies="default" metadata=organisation="Meaningfy.ws" metadata=team="Development" | jq -r '.data.id' >$TMP_ID_FILE
  # creating and assigning the userpass user to the entity
  tmp_accessor_userpass
  vault write auth/userpass/users/$2 password="$DEFAULT_PASSWORD" policies="$DEFAULT_POLICY"
  vault write identity/entity-alias name="$2" canonical_id=$(cat $TMP_ID_FILE) mount_accessor=$(cat $TMP_ACCESSOR_FILE)
  # assigning the github user to the entity
  tmp_accessor_github
  vault write identity/entity-alias name="$2" canonical_id=$(cat $TMP_ID_FILE) mount_accessor=$(cat $TMP_ACCESSOR_FILE)
}

clean_tmp() {
  rm -f $TMP_ID_FILE
  rm -f $TMP_ACCESSOR_FILE
}

clean_tmp
enable_features
enable_github_to_meanigfy
update_default_policy

create_github_aliased_entity "Eugeniu Costetchi" costezki
create_github_aliased_entity "Laurentiu Mandru" mclaurentiu
create_github_aliased_entity "Stefan Stratulat" CaptainOfHacks
create_github_aliased_entity "Dan Chiriac" DanCh11
create_github_aliased_entity "Dragos Paun" Dragos0000
create_github_aliased_entity "Bogdan Donu" DonuBogdan
clean_tmp