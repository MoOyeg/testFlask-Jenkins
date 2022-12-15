# testFlask-Jenkins

Sample Jenkins Pipeline for a Flask Python Application  
Application will show how we can use Jenkins to deploy/test a flask application running on openshift, the Application being used is [testFlask](https://github.com/MoOyeg/testFlask.git)  
Environment variables used in Commands have samples in the sample_env file.  
So this example assumes a pipeline scenario where there is a running production application represented by our Production Project 'NAMESPACE_PROD' and at build time we deploy the same exact infrastructure in our devlopment project 'NAMESPACE_DEV' and test, when all satisfied we promote our dev image to production which is automatically deployed based on a trigger on the imagestream.

## Steps to Run

**Steps 1 is only necessary if you don't have jenkins installed and want to install it in the cluster**  
0 **Source Sample Environment**  
`eval "$(curl https://raw.githubusercontent.com/MoOyeg/testFlask/master/sample_env)"`

1 **Create a new project and start a jenkins pod in openhshift,we will create a new project also for jenkins**

- Create a Jenkins namespace  
  `oc new-project $JENKINS_NAMESPACE`

- Create Jenkins either with storage or without
  
  With Storage  

  ```bash
  oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true -n $JENKINS_NAMESPACE
  ```

  Without Storage

  ```bash
  oc new-app jenkins-ephemeral --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true -n $JENKINS_NAMESPACE
  ```

2 **Confirm you can login to Jenkins with the credentials you used to log into openshift**

- To get the route for the Jenkins login url  
  `oc get route jenkins -n $JENKINS_NAMESPACE -o jsonpath='{ .spec.host }'`

- Open the URL in a browser and login

3 **Create prod and test projects for your pipeline and add permissions for the jenkins Service Account to be able to build on thos projects**

- Create Projects  
  `oc new-project $NAMESPACE_DEV`  
  `oc new-project $NAMESPACE_PROD`

- Add Permissions for Jenkins service account to Projects  
  `oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE_DEV`  
  `oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE_PROD`  
  `oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $JENKINS_NAMESPACE`

- Add Permissions for Default service accountin jenkins namespace to Projects  
  `oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:default -n $NAMESPACE_DEV`  
  `oc policy add-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:default -n $NAMESPACE_PROD`

- Create our Infrastructure Secret in our Development and Production  
  `oc create secret generic my-secret --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $NAMESPACE_DEV`  
  `oc create secret generic my-secret --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $NAMESPACE_PROD`

- Create our Database in Production  
  `oc new-app $MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE -l db=mysql -l app=testflask --as-deployment-config=true -n $NAMESPACE_PROD`

- Set our Secret on the Production Database  
  `oc set env dc/$MYSQL_HOST --from=secret/my-secret -n $NAMESPACE_PROD`

- Create our Production Application  
  `oc new-app https://github.com/MoOyeg/testFlask.git --name=$APP_NAME -l app=testflask --strategy=source --env=APP_CONFIG=gunicorn.conf.py --env=APP_MODULE=testapp:app --env=MYSQL_HOST=$MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE --as-deployment-config=true -n $NAMESPACE_PROD`

- Set our Secret on the Production Application  
  `oc set env dc/$APP_NAME --from=secret/my-secret -n $NAMESPACE_PROD`

- Expose our Production Application to the External World  
  `oc expose svc/$APP_NAME -n $NAMESPACE_PROD`

- Label our Projects for the Development Console

```bash
   oc label dc/$APP_NAME app.kubernetes.io/part-of=$APP_NAME -n $NAMESPACE_PROD
   oc label dc/$MYSQL_HOST app.kubernetes.io/part-of=$APP_NAME -n $NAMESPACE_PROD
   oc annotate dc/$APP_NAME app.openshift.io/connects-to=$MYSQL_HOST -n $NAMESPACE_PROD
```

4 **Create Jenkins Slave for Python**  
The Jenkins slave will be used to run the jenkins pipeline, while not necessary to always create your own slave as
Openshift comes out of the box with some, I am using this example to show you can build yours and if you have dependencies
to test or build your application you can add them into your image.I am using the Dockerfile above to build my image, because the image uses an image in registry.redhat.io remember to create a service account, create a service account secret and link that secret to your builder service account in Jenkins, please see https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/configuring_clusters/install-config-configuring-red-hat-registry  
Also you might not be able to build this image if your cluster is not entitled, please do this at cloud.redhat.com. If you have redhat subscriptions but have not entitled your cluster you can use this process to pass your entitlement into the BuildConfig, see https://docs.openshift.com/container-platform/4.4/builds/running-entitled-builds.html  
To build a jenkins image without a subscription please read https://github.com/openshift/jenkins.

- Pass DockerFile Value into Variable(Openshift Subscription Required)  
  `export PYTHON_DOCKERFILE=$(curl https://raw.githubusercontent.com/MoOyeg/testFlask-Jenkins/master/Dockerfile)`

- Build Slave Image in Jenkins Project  
  `oc new-build --strategy=docker -D="$PYTHON_DOCKERFILE" --name=python-jenkins -n $JENKINS_NAMESPACE`

<!-- - Expose Jenkins Service as a route  
  `oc expose svc/jenkins -n $JENKINS_NAMESPACE`

- You can Login to Jenkins WebPage to see how it is configures, get jenkins route by  
  `oc get route jenkins -n $JENKINS_NAMESPACE -o jsonpath='{ .spec.host }' ` -->

5 **Create Our BuildConfig with our buildstrategy as Pipeline**

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
      ref: working
      uri: 'https://github.com/MoOyeg/testFlask-Jenkins.git'
    type: Git
  strategy:
    type: "JenkinsPipeline"
    jenkinsPipelineStrategy:
      jenkinsfilePath: Jenkinsfile
""" | oc create -f -
```

6 **Pass our variables to our pipeline, they will show up as parameters in jenkins**

- Set environment variables on BuildConfig

```bash
  oc set env bc/$APP_NAME-pipeline \
--env=JENKINS_NAMESPACE=$JENKINS_NAMESPACE \
--env=REPO="https://github.com/MoOyeg/testFlask.git" \
--env=DEV_PROJECT=$NAMESPACE_DEV --env=APP_NAME=$APP_NAME \
--env=APP_CONFIG=$APP_CONFIG --env=APP_MODULE=$APP_MODULE \
--env=MYSQL_HOST=$MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE --env=PROD_PROJECT=$NAMESPACE_PROD -n $JENKINS_NAMESPACE
```

7 **Start build in Jenkins**

- We can start build using

  ```bash
  oc start-build $APP_NAME-pipeline -n $JENKINS_NAMESPACE
  ```

- Log into Jenkins to follow the build, you can use the route provided earlier

- Build has approval stage to simulate approval, we need to accept that to move forward

- We can confirm that prod version got updated with new application image

8 **This pipeline can also be automically started with a code change via a webhook**

- We can add a webhook by

`oc set triggers bc/$APP_NAME-pipeline --from-github -n $JENKINS_NAMESPACE`

## Use PodTemplates and Volumes as part of Pipeline

### Create PodTemplates

- PodTemplatesprovide a way to define the Pod Instance to run that will run the build process.Example here requires the use of a Storage Class that supports dynamic provisioning.This Pipeline requires that you provide elevated privileged to the Jenkins serviceaccount to allow dynamic provisioning of the pvc.

- Export your StorageClass Values

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

- Example builds application in JENKINS_NAMESPACE so we will add our secret

```bash
oc create secret generic my-secret --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $JENKINS_NAMESPACE
```

- You can create the pipeline object in Jenkins or or use a Buildconfig  

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
      ref: working
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
--env=DEV_PROJECT=$NAMESPACE_DEV --env=APP_NAME=$APP_NAME \
--env=APP_CONFIG=$APP_CONFIG --env=APP_MODULE=$APP_MODULE \
--env=MYSQL_HOST=$MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE --env=PROD_PROJECT=$NAMESPACE_PROD -n $JENKINS_NAMESPACE
```
