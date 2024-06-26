# testFlask-Jenkins

Sample Jenkins Pipeline for a Flask Python Application  
Application will show how we can use Jenkins to deploy/test a flask application running on openshift, the Application being used is [testFlask](https://github.com/MoOyeg/testFlask.git)  
Environment variables used in Commands have samples in the sample_env file.  
So this example assumes a pipeline scenario where there is a running production application represented by our Production Project 'NAMESPACE_PROD' and at build time we deploy the same exact infrastructure in our devlopment project 'NAMESPACE_DEV' and test, when all satisfied we promote our dev image to production which is automatically deployed based on a trigger on the imagestream.

## prerequisites
- OCP Version >= 4.11

## Steps to Run

- Source Environment Variables
  ```bash
  eval "$(curl https://raw.githubusercontent.com/MoOyeg/testFlask/master/sample_env)"
  ```

- Create a Jenkins namespace  
  `oc new-project $JENKINS_NAMESPACE`

- Create Jenkins either with storage or without
  
  - With Storage  

    ```bash
    oc process -f ./jenkinsdeploytemplates/jenkins-persistent-deployment.yaml | oc apply -f - -n $JENKINS_NAMESPACE
    ```

  - Without Storage

    ```bash
    oc process -f ./jenkinsdeploytemplates/jenkins-ephemeral-deployment.yaml | oc apply -f - -n $JENKINS_NAMESPACE
    ```

- We used Openshift Oauth, so confirm you can login to Jenkins with the credentials you used to log into openshift

- To get the route for the Jenkins login url  
  ```bash
  oc get route jenkins -n $JENKINS_NAMESPACE -o jsonpath='{ .spec.host }'
  ```

- Open the URL in a browser and login

- Create prod and test projects for your pipeline and add permissions for the jenkins Service Account to be able to build on thos projects

- Create Projects  
  ```bash
  oc new-project $NAMESPACE_DEV
  ```  
  ```bash
  oc new-project $NAMESPACE_PROD
  ```

- Add Permissions for Jenkins service account to Projects  
  ```bash
  oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE_DEV 

  oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE_PROD
  ```

- Add Permissions for Default service account in jenkins namespace to Projects  
  ```bash
  oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:default -n $NAMESPACE_DEV

  oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:default -n $NAMESPACE_PROD
  ```

- [Run Installation Steps for Application](https://github.com/MoOyeg/testFlask#steps-to-build-and-run-application) - You can skip this step, pipeline will still run but wont show how to replace promoted application.
 
<!-- - Create our Infrastructure Secret in our Development and Production  
  `oc create secret generic my-secret --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $NAMESPACE_DEV`  
  `oc create secret generic my-secret --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $NAMESPACE_PROD`

- Create our Database in Production  
  `oc new-app $MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE -l db=mysql -l app=testflask --as-deployment-config=true -n $NAMESPACE_PROD`

- Set our Secret on the Production Database  
  `oc set env dc/$MYSQL_HOST --from=secret/my-secret -n $NAMESPACE_PROD`

- Create our Production Application  
  `oc new-app https://github.com/MoOyeg/testFlask.git --name=$APP_NAME -l app=testflask --strategy=source --env=APP_CONFIG=./gunicorn/gunicorn.conf.py --env=APP_MODULE=runapp:app --env=MYSQL_HOST=$MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE --as-deployment-config=true -n $NAMESPACE_PROD`

- Set our Secret on the Production Application  
  `oc set env dc/$APP_NAME --from=secret/my-secret -n $NAMESPACE_PROD`

- Expose our Production Application to the External World  
  `oc expose svc/$APP_NAME -n $NAMESPACE_PROD`

- Label our Projects for the Development Console

```bash
   oc label dc/$APP_NAME app.kubernetes.io/part-of=$APP_NAME -n $NAMESPACE_PROD
   oc label dc/$MYSQL_HOST app.kubernetes.io/part-of=$APP_NAME -n $NAMESPACE_PROD
   oc annotate dc/$APP_NAME app.openshift.io/connects-to=$MYSQL_HOST -n $NAMESPACE_PROD
``` -->

- Create Jenkins Slave for Python  
  The Jenkins slave will be used to run the jenkins pipeline, while not necessary to always create your own slave as
  Openshift comes out of the box with some, I am using this example to show you can build yours and if you have dependencies
  to test or build your application you can add them into your image.I am using the Dockerfile above to build my image, because the image uses an image in registry.redhat.io remember to create a service account, create a service account secret and link that secret to your builder service account in Jenkins, please see https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/configuring_clusters/install-config-configuring-red-hat-registry  
  Also you might not be able to build this image if your cluster is not entitled, please do this at cloud.redhat.com. If you have redhat subscriptions but have not entitled your cluster you can use this process to pass your entitlement into the BuildConfig, see https://docs.openshift.com/container-platform/4.4/builds/running-entitled-builds.html  
  To build a jenkins image without a subscription please read https://github.com/openshift/jenkins.

  - Pass DockerFile Value into Variable(Openshift Subscription Required)
    
    If you have access to RedHat catalog
    ```bash
    export BASE_IMAGE=registry.redhat.io/openshift4/ose-jenkins-agent-base:v4.10.0
    ``` 
    else:  
      - If you do not have access you can try this option
        ```bash
        export BASE_IMAGE=image-registry.openshift-image-registry.svc:5000/openshift/jenkins-agent-base:latest
        ``` 
    then create dockerfile with image
    ```bash
    export PYTHON_DOCKERFILE=$(curl https://raw.githubusercontent.com/MoOyeg/testFlask-Jenkins/master/Dockerfile | envsubst )
    ```

  - Build Slave Image in Jenkins Project  
    `oc new-build --strategy=docker -D="$PYTHON_DOCKERFILE" --name=python-jenkins -n $JENKINS_NAMESPACE`

<!-- - Expose Jenkins Service as a route  
  `oc expose svc/jenkins -n $JENKINS_NAMESPACE`

- You can Login to Jenkins WebPage to see how it is configures, get jenkins route by  
  `oc get route jenkins -n $JENKINS_NAMESPACE -o jsonpath='{ .spec.host }' ` -->

- Create Our BuildConfig with our buildstrategy as Pipeline

  - We can create our BuildConfig below

  ```bash
  echo """
  apiVersion: build.openshift.io/v1
  kind: BuildConfig
  metadata:
    name: "$APP_NAME-pipeline"
    namespace: $JENKINS_NAMESPACE
  spec:
    source:
      git:
        ref: master
        uri: 'https://github.com/MoOyeg/testFlask-Jenkins.git'
      type: Git
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        jenkinsfilePath: Jenkinsfile
  """ | oc create -f -
  ```

- Pass our variables to our pipeline, they will show up as parameters in jenkins**

  - Set environment variables on BuildConfig

    ```bash
      oc set env bc/$APP_NAME-pipeline \
    --env=JENKINS_NAMESPACE=$JENKINS_NAMESPACE \
    --env=REPO="https://github.com/MoOyeg/testFlask.git" \
    --env=BRANCH=master \
    --env=DEV_PROJECT=$NAMESPACE_DEV --env=APP_NAME=$APP_NAME \
    --env=MYSQL_USER=$MYSQL_USER --env=MYSQL_PASSWORD=$MYSQL_PASSWORD \
    --env=APP_CONFIG=$APP_CONFIG --env=APP_MODULE=$APP_MODULE \
    --env=MYSQL_HOST=$MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE --env=PROD_PROJECT=$NAMESPACE_PROD -n $JENKINS_NAMESPACE
    ```

- Start build in Jenkins

  - We can start build using

    ```bash
    oc start-build $APP_NAME-pipeline -n $JENKINS_NAMESPACE
    ```

- Log into Jenkins to follow the build, you can use the route provided earlier

- Build has approval stage to simulate approval, we need to accept that to move forward

- We can confirm that prod version got updated with new application image

- This pipeline can also be triggered with a a code change via a webhook

- We can add a webhook by

  ```bash
  oc set triggers bc/$APP_NAME-pipeline --from-github -n $JENKINS_NAMESPACE
  ```

## Use PodTemplates and Volumes for Pipeline

### Create PodTemplates

- PodTemplatesprovide a way to define the Pod Instance to run that will run the build process.Example here requires the use of a Storage Class that supports dynamic provisioning.  
This pipeline shows an example of how to provision a dynamic volume and share it between the workspace and a pod within the pipline steps. 
This Pipeline requires that you provide elevated privileged to the Jenkins serviceaccount to allow dynamic provisioning of the pvc.  
For this Example RWX is required for storage class

- Export your StorageClass Values, see example below:  

  ```bash
  export SC_NAME=sc-efs
  export PV_SIZE=300Mi
  export ACCESS_MODE=ReadWriteMany
  ```

- Create PodTemplates to use your above storage values

  ```bash
  envsubst '$SC_NAME $PV_SIZE $ACCESS_MODE' < ./podtemplates/podtemplate-dynamic-volume-rwx.yaml | oc create -n $JENKINS_NAMESPACE -f -
  ```

  ```bash
  envsubst '$SC_NAME $PV_SIZE $ACCESS_MODE' < ./podtemplates/podtemplate-python-inherit-dynamic-volume.yaml | oc create -n $JENKINS_NAMESPACE -f -
  ```

- This example shares workspace volume with application builds, Since the PVC can only exist in one namespace we will build in JENKINS_NAMESPACE. Let's add our application secret

  ```bash
  oc create secret generic my-secret --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $JENKINS_NAMESPACE
  ```

- Depending on how your cluster is configured you might need to apply RBAC permissions to allow Jenkins Agent use volumes.

  ```bash
   oc apply -k ./rbac
  ```

- You can manually create the pipeline object in Jenkins. Use the Jenkinsfile-with-volume(preferred) OR you can also use a Buildconfig.  

  ```bash
  echo """
  apiVersion: build.openshift.io/v1
  kind: BuildConfig
  metadata:
    name: "$APP_NAME-pipeline-volume"
    namespace: $JENKINS_NAMESPACE
  spec:
    source:
      git:
        ref: master
        uri: 'https://github.com/MoOyeg/testFlask-Jenkins.git'
      type: Git
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        jenkinsfilePath: Jenkinsfile-with-volume
  """ | oc create -f -
  ```

  ```bash
  oc set env bc/$APP_NAME-pipeline-volume \
  --env=JENKINS_NAMESPACE=$JENKINS_NAMESPACE \
  --env=REPO="https://github.com/MoOyeg/testFlask.git" \
  --env=BRANCH="master" \
  --env=DEV_PROJECT=$NAMESPACE_DEV --env=APP_NAME=$APP_NAME \
  --env=APP_CONFIG=$APP_CONFIG --env=APP_MODULE=$APP_MODULE \
  --env=MYSQL_USER=$MYSQL_USER --env=MYSQL_PASSWORD=$MYSQL_PASSWORD \
  --env=MYSQL_HOST=$MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE --env=PROD_PROJECT=$NAMESPACE_PROD -n $JENKINS_NAMESPACE
  ```
