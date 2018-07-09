#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"
#oc project $GUID-sonarqube

# Code to set up the SonarQube project.
# Ideally just calls a template
#oc new-app -f ./Infrastructure/templates/sonar_template.yaml --param GUID=${GUID} POSTGRESQL_USER=sonar --param POSTGRESQL_PASSWORD=sonar --param POSTGRESQL_DATABASE=sonar --param POSTGRESQL_VOLUME_CAPACITY=4Gi 
oc new-app -f https://raw.githubusercontent.com/franredhat/appdev-mitzicom/master/Infrastructure/templates/sonarqube-postgresql-template.yaml -n $GUID-sonarqube
