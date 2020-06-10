# testFlask-Jenkins
Sample Jenkins Pipeline for a Flask Python Application<br/>
Application will show how we can use Jenkins to deploy/test a flask application running on openshift, the Application being used is [testFlask](https://github.com/MoOyeg/testFlask.git)<br/>
Environment variables used in Commands have samples in the sample_env file.<br/>


### Steps to Run<br/>
**Steps 1 is only necessary if you don't have jenkins installed and want to install it in the cluster**<br/>

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
  ```oc adm new-project $NAMESPACE_DEV```<br/>
  ```oc adm new-project $NAMESPACE_PROD```<br/>
 
  - Add Permissions for Jenkins service account to Projects<br/>
  ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE_DEV```<br/>
  ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE_PROD```<br/>
  ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $JENKINS_NAMESPACE```<br/>
 
4 **Create Jenkins Slave for Python,**<br/>
The Jenkins slave will be used to run the jenkins pipeline, while not necessary to always create your own slave as 
Openshift comes out of the box with some, I am using this example to show you can build yours and if you have dependencies 
to test or build your application you can add them into your image.<br/>
  - Pass DockerFile Value into Variable<br/>
  ```export PYTHON_DOCKERFILE=$(curl https://raw.githubusercontent.com/MoOyeg/testFlask-Jenkins/master/Dockerfile)```<br/>

  - Build Slave Image in Jenkins Project<br/>
  ```oc new-build --strategy=docker -D="$PYTHON_DOCKERFILE" --name=python-jenkins -n $JENKINS_NAMESPACE```<br/>

  - Expose Jenkins Service as a route<br/>
  ```oc expose svc/jenkins -n $JENKINS_NAMESPACE```

  - You can Login to Jenkins WebPage to see how it is configures, get jenkins route by<br/>
  ```oc get route jenkins -n $JENKINS_NAMESPACE -o jsonpath='{ .spec.host }' ```

5 **Create Our BuildConfig with our buildstrategy as Pipeline**<br/>
  - We can create our BuildConfig below<br/>
