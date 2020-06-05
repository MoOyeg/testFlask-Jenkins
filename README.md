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
 ```oc adm new-project $NAMESPACE```<br/>
 ```oc adm new-project $NAMESPACE1```<br/>
 
 - Add Permissions for Jenkins service account to Projects<br/>
 ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE```<br/>
 ```oc adm policy add-cluster-role-to-user edit system:serviceaccount:$JENKINS_NAMESPACE:jenkins -n $NAMESPACE1```<br/>
 
