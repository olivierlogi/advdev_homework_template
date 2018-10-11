#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# # Code to set up the Jenkins project to execute the
# # three pipelines.
# # This will need to also build the custom Maven Slave Pod
# # Image to be used in the pipelines.
# # Finally the script needs to create three OpenShift Build
# # Configurations in the Jenkins Project to build the
# # three micro services. Expected name of the build configs:
# # * mlbparks-pipeline
# # * nationalparks-pipeline
# # * parksmap-pipeline
# # The build configurations need to have two environment variables to be passed to the Pipeline:
# # * GUID: the GUID used in all the projects
# # * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# # To be Implemented by Student

#oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-jenkins


oc new-app -f ./Infrastructure/templates/jenkins.json \
  --param ENABLE_OAUTH=true \
  --param MEMORY_LIMIT=2Gi \
  --param CPU_LIMIT=2 \
  --param VOLUME_CAPACITY=4Gi \
  -n "${GUID}-jenkins"

oc patch dc/jenkins \
  -p "{\"spec\":{\"strategy\":{\"recreateParams\":{\"timeoutSeconds\":1200}}}}" \
  -n "${GUID}-jenkins"

#docker build ../docker -t docker-registry-default.apps.${CLUSTER}/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9

#oc new-app --strategy=docker ./Infrastructure/docker/ -n ${GUID}-jenkins

#oc new-build --name=jenkins-slave-appdev \
#    --dockerfile="$(< ./Infrastructure/docker/skopeo/Dockerfile)" \
#    -n $GUID-jenkins
oc create imagestream jenkins-slave-appdev -n "${GUID}-jenkins"
oc create -f "${TEMPLATES_PATH:-./Infrastructure/templates}"/BuildConfig_Skopeo -n "${GUID}-jenkins"
oc start-build skopeo-build -n "${GUID}-jenkins"



#Parksmap pipeline BuildConfig
#oc create -f ./Infrastructure/templates/parksmap-pipeline.yaml -n ${GUID}-jenkins

#MLBPark pipeline BuildConfig
oc create -f ./Infrastructure/templates/mlbparks-pipeline.yaml -n ${GUID}-jenkins

#NationalParks pipeline BuildConfig
#oc create -f ./Infrastructure/templates/nationalparks-pipeline.yaml -n ${GUID}-jenkins

#Jenkins slave BuildConfig 
#oc new-app -f ./Infrastructure/templates/jenkins-configmap.yaml --param GUID=${GUID}
