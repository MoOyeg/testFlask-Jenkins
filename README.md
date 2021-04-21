# testFlask-Jenkins
Sample Jenkins Pipeline for a Flask Python Applications<br/>
Application will show how we can use Jenkins to deploy/test a flask application running on openshift, the Application being used is [testFlask](https://github.com/MoOyeg/testFlask.git)<br/>
Environment variables used in Commands have samples in the sample_env file.<br/>
So this example assumes a pipeline scenario where there is a running production application represented by our Production Project($NAMESPACE_PROD) and at build time we deploy the same exact infrastructure in our devlopment project ($NAMESPACE_DEV) and test, when all satisfied we promote our dev image to production which is automatically deployed based on a trigger on the imagestream.

### Steps to Run<br/>
**Steps 1 is only necessary if you don't have jenkins installed and want to install it in the cluster**<br/>
0 **Source Sample Environment**<br/>
```eval "$(curl https://raw.githubusercontent.com/MoOyeg/testFlask/master/sample_env)"```<br/>

1 **Create a new project and start a jenkins pod in openhshift,we will create a new project also for jenkins**<br/>
  - Create a Jenkins namespace<br/>
  ```oc new-project $JENKINS_NAMESPACE```<br/>
    
  - Create Jenkins<br/>
  ```oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true -n $JENKINS_NAMESPACE```<br/>
      
2 **Confirm you can login to Jenkins with the credentials you used to log into openshift**
  - To get the route for the Jenkins login url<br/>
  ```oc get route jenkins -n $JENKINS_NAMESPACE -o jsonpath='{ .spec.host }'```

  - Open the URL in a browser and login<br/>
 
3 **Create prod and test projects for your pipeline and add permissions for the jenkins Service Account to be able to build on thos projects**<br/>
  - Create Projects <br/>
  ```oc new-project $NAMESPACE_DEV```<br/>
  ```oc new-project $NAMESPACE_PROD```<br/>
 
  - Add Permissions for Jenkins service account to Projects<br/>
  ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE_DEV```<br/>
  ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE_PROD```<br/>
  ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $JENKINS_NAMESPACE```<br/>
  
  - Add Permissions for Default service accountin jenkins namespace to Projects<br/>
  ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:default -n $NAMESPACE_DEV```<br/>
  ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:default -n $NAMESPACE_PROD```<br/>
  
  - Create our Infrastructure Secret in our Development and Production<br/>
  ```oc create secret generic my-secret --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $NAMESPACE_DEV```<br/>
  ```oc create secret generic my-secret --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $NAMESPACE_PROD```<br/>
  
  - Create our Database in Production<br/>
  ```oc new-app $MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE -l db=mysql -l app=testflask --as-deployment-config=true -n $NAMESPACE_PROD```<br/>
  
  - Set our Secret on the Production Database<br/>
  ```oc set env dc/$MYSQL_HOST --from=secret/my-secret -n $NAMESPACE_PROD```<br/>
   
  - Create our Production Application<br/>
  ```oc new-app https://github.com/MoOyeg/testFlask.git --name=$APP_NAME -l app=testflask --strategy=source --env=APP_CONFIG=gunicorn.conf.py --env=APP_MODULE=testapp:app --env=MYSQL_HOST=$MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE --as-deployment-config=true -n $NAMESPACE_PROD```<br/>
  
  - Set our Secret on the Production Application<br/>
  ```oc set env dc/$APP_NAME --from=secret/my-secret -n $NAMESPACE_PROD```
 
  - Expose our Production Application to the External World<br/>
  ```oc expose svc/$APP_NAME -n $NAMESPACE_PROD```
  
  - Label our Projects for the Development Console
  ```
     oc label dc/$APP_NAME app.kubernetes.io/part-of=$APP_NAME -n $NAMESPACE_PROD
     oc label dc/$MYSQL_HOST app.kubernetes.io/part-of=$APP_NAME -n $NAMESPACE_PROD
     oc annotate dc/$APP_NAME app.openshift.io/connects-to=$MYSQL_HOST -n $NAMESPACE_PROD
  ```
  
4 **Create Jenkins Slave for Python**<br/>
The Jenkins slave will be used to run the jenkins pipeline, while not necessary to always create your own slave as 
Openshift comes out of the box with some, I am using this example to show you can build yours and if you have dependencies 
to test or build your application you can add them into your image.I am using the Dockerfile above to build my image, because the image uses an image in registry.redhat.io remember to create a service account, create a service account secret and link that secret to your builder service account in Jenkins, please see https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/configuring_clusters/install-config-configuring-red-hat-registry<br/>
Also you might not be able to build this image if your cluster is not entitled, please do this at cloud.redhat.com. If you have redhat subscriptions but have not entitled your cluster you can use this process to pass your entitlement into the BuildConfig, see https://docs.openshift.com/container-platform/4.4/builds/running-entitled-builds.html<br/>
To build a jenkins image without a subscription please read https://github.com/openshift/jenkins. 
  - Pass DockerFile Value into Variable(Openshift Subscription Required)<br/>
  ```export PYTHON_DOCKERFILE=$(curl https://raw.githubusercontent.com/MoOyeg/testFlask-Jenkins/master/Dockerfile)```<br/>

  - Build Slave Image in Jenkins Project<br/>
  ```oc new-build --strategy=docker -D="$PYTHON_DOCKERFILE" --name=python-jenkins -n $JENKINS_NAMESPACE```<br/>

  - Expose Jenkins Service as a route<br/>
  ```oc expose svc/jenkins -n $JENKINS_NAMESPACE```

  - You can Login to Jenkins WebPage to see how it is configures, get jenkins route by<br/>
  ```oc get route jenkins -n $JENKINS_NAMESPACE -o jsonpath='{ .spec.host }' ```

5 **Create Our BuildConfig with our buildstrategy as Pipeline**<br/>
  - We can create our BuildConfig below<br/>
  ```
  echo "apiVersion: v1
items:
- kind: "BuildConfig"
  apiVersion: "v1"
  metadata:
    name: "$APP_NAME-pipeline"
  spec:
    source:
      type: "Git"
      git:
        uri: https://github.com/MoOyeg/testFlask-Jenkins.git
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        jenkinsfilePath: Jenkinsfile
kind: List
metadata: []" | oc apply -f - -n $JENKINS_NAMESPACE
```
<br/>
 - On newer cluster versions use <br/>

```
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
<br/>

6 **Pass our variables to our pipeline, they will show up as parameters in jenkins**<br/>
- Set environment  variables on BuildConfig<br/>
```
  oc set env bc/$APP_NAME-pipeline \
--env=JENKINS_NAMESPACE=$JENKINS_NAMESPACE \
--env=REPO="https://github.com/MoOyeg/testFlask.git" \
--env=DEV_PROJECT=$NAMESPACE_DEV --env=APP_NAME=$APP_NAME \
--env=APP_CONFIG=$APP_CONFIG --env=APP_MODULE=$APP_MODULE \
--env=MYSQL_HOST=$MYSQL_HOST --env=MYSQL_DATABASE=$MYSQL_DATABASE --env=PROD_PROJECT=$NAMESPACE_PROD -n $JENKINS_NAMESPACE
```
7 **Start build in Jenkins**
- We can start build using<br/>
```oc start-build $APP_NAME-pipeline -n $JENKINS_NAMESPACE```<br/>

- Log into Jenkins to follow the build, you can use the route provided earlier<br/>

- Build has approval stage to simulate approval, we need to accept that to move forward<br/>

- We can confirm that prod version got updated with new application image<br/>

8 **This pipeline can also be automically started with a code change via a webhook**<br/>
- We can add a webhook by<br/>
```oc set triggers bc/$APP_NAME-pipeline --from-github -n $JENKINS_NAMESPACE```


