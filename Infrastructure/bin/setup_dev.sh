#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student
#Deploy front end

#Build parks-map binary with maven
pushd ../../ParksMap
mvn -s ../nexus_settings.xml clean package spring-boot:repackage -DskipTests -Dcom.redhat.xpaas.repo.redhatga
popd

#Allow application permission to discover available routes
oc policy add-role-to-user view --serviceaccount=default

#Create build for parks-map and deploy
oc new-build --binary=true --name=parksmap-dev --image-stream=redhat-openjdk18-openshift:1.2
oc start-build parksmap-dev --from-file=../../ParksMap/target/parksmap.jar --follow
oc new-app parksmap-dev -l type=parksmap-frontend -e APPNAME="ParksMap (Blue)"
oc expose svc/parksmap-dev --port=8080
oc set probe dc/parksmap-dev --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=2
oc set probe dc/parksmap-dev --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=2


##Deploy mongo 
MEMORY_LIMIT="512Mi"
NAMESPACE="openshift"
DATABASE_SERVICE_NAME="mongodb"
MONGODB_USER="mongodb"
MONGODB_PASSWORD="mongodb"
MONGODB_DATABASE="parks"
MONGODB_ADMIN_PASSWORD="mongodb"
VOLUME_CAPACITY="1Gi"
MONGODB_VERSION="3.2" #could be latest

oc new-app -f ../templates/mongodb_persistent.json --param MEMORY_LIMIT=$MEMORY_LIMIT \
--param NAMESPACE=${NAMESPACE} \
--param DATABASE_SERVICE_NAME=${DATABASE_SERVICE_NAME} \
--param MONGODB_USER=${MONGODB_USER} \
--param MONGODB_PASSWORD=${MONGODB_PASSWORD} \
--param MONGODB_DATABASE=${MONGODB_DATABASE} \
--param MONGODB_ADMIN_PASSWORD=${MONGODB_ADMIN_PASSWORD} \
--param VOLUME_CAPACITY=${VOLUME_CAPACITY} \
--param MONGODB_VERSION=${MONGODB_VERSION} 


##Deploy back ends (TODO)

#Build and Deploy National Parks

#Build national-parks binary with maven
pushd ../../Nationalparks
mvn -s ../nexus_settings.xml clean package -DskipTests=true
popd

oc new-build --binary=true --name=national-parks-dev --image-stream=redhat-openjdk18-openshift:1.2
oc start-build national-parks-dev --from-file=../../Nationalparks/target/nationalparks.jar --follow
oc new-app national-parks-dev -l type=parksmap-backend -e APPNAME="National Parks (Blue)" \
-e DB_HOST=$DATABASE_SERVICE_NAME \
-e DB_PORT=27017 \
-e DB_USERNAME=$MONGODB_USER \
-e DB_PASSWORD=$MONGODB_PASSWORD \
-e DB_NAME=$MONGODB_DATABASE

oc set probe dc/national-parks-dev --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30
oc set probe dc/national-parks-dev --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30

#Add post deployment hook!

#Build and Deploy MLB Parks

#Build mlb-parks binary with maven
pushd ../../MLBParks
mvn -s ../nexus_settings.xml clean package -DskipTests=true
popd

oc new-build --binary=true --name=mlb-parks-dev --image-stream=jboss-eap70-openshift:1.7
oc start-build mlb-parks-dev --from-file=../../MLBParks/target/mlbparks.war --follow
oc new-app mlb-parks-dev -l type=parksmap-backend -e APPNAME="MLB Parks (Blue)" \
-e DB_HOST=$DATABASE_SERVICE_NAME \
-e DB_PORT=27017 \
-e DB_USERNAME=$MONGODB_USER \
-e DB_PASSWORD=$MONGODB_PASSWORD \
-e DB_NAME=$MONGODB_DATABASE

oc set probe dc/mlb-parks-dev --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30
oc set probe dc/mlb-parks-dev --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30

#Add post deployment hook!