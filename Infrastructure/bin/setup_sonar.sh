#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
oc new-app -f ./Infrastructure/templates/sonar_template.yaml --param=SONARQUBE_IMAGE=docker.io/wkulhanek/sonarqube --param=SONARQUBE_VERSION=7.3 -n $GUID-sonarqube
