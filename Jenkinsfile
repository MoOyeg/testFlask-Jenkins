pipeline {
agent {
  kubernetes {
    label "python-agent"
    cloud "openshift"
    containerTemplate {
      name "jnlp"
      image "image-registry.openshift-image-registry.svc:5000/$JENKINS_NAMESPACE/python-jenkins:latest"  
      resourceRequestMemory "500Mi"
      resourceLimitMemory "500Mi"
      resourceRequestCpu "300m"
      resourceLimitCpu "300m"
      alwaysPullImage "True"
    }
  }
}

  stages {

    stage('Checkout Pipeline Source') {
     steps {
       echo "Checking out Code}"
       checkout scm
      }     
    }


    stage('Clone Application Source') {
     steps {
       echo "Clone our Application Source Code}"
       script {             
             sh "git clone ${REPO}"
          }
      }     
    }

    stage('Run Unit Testing') {
     steps {
       echo "Starting Unit Testing"
       script {
         try {
           sh "python ./testFlask/test.py"
         } catch (Exception e) {
           error("Build failed at Unittest")
         }
       echo "Unittest Passed"
       }
      }     
    }

    stage('Create Test Version of Application') {
     steps {
       script {
         openshift.withCluster() {
           openshift.withProject( "${DEV_PROJECT}" ){
           echo "Creating Mysql Application"
           def fromJSON = openshift.create( readFile( 'mysql.json' ) )
           
           echo "Creating Mysql Service"
           def fromJSON2 = openshift.create( readFile( 'mysql-svc.json' ) )

           echo "Wait until dc/mysql is available"
           def dcmysql = openshift.selector('dc', "mysql")
           dcmysql.rollout().status()
           echo "dc/mysql is available"
           
           echo "Creating Main Application"
           //apply = openshift.apply(openshift.raw("new-app ${REPO} --name=${APP_NAME} -l app=${APP_NAME} --env=APP_CONFIG=${APP_CONFIG} --env=APP_MODULE=${APP_MODULE} --env=MYSQL_HOST=${MYSQL_HOST} --env=MYSQL_DATABASE=${MYSQL_DATABASE} --as-deployment-config=true --strategy=source --dry-run --output=yaml").actions[0].out)
           apply = openshift.apply(openshift.raw("create configmap frontend-config --dry-run --from-literal=test=test --output=yaml").actions[0].out)
           echo "Created Main Application"
             
           echo "Configure Main Application"
           openshift.raw("set env dc/${APP_NAME} --from=secret/my-secret")
           openshift.raw("expose svc/${APP_NAME}")
           openshift.raw("expose svc/mysql")
           openshift.raw("label dc/mysql app=${APP_NAME}")
           openshift.raw("label dc/${APP_NAME} app.kubernetes.io/part-of=${APP_NAME}")
           openshift.raw("label dc/mysql app.kubernetes.io/part-of=${APP_NAME}")
           openshift.raw("annotate dc/${APP_NAME} app.openshift.io/connects-to=mysql")
           echo "Configured Main Application"

           echo "Wait until dc/${APP_NAME} is available"
           def dcmainapp = openshift.selector('dc', "${APP_NAME}")
           dcmainapp.rollout().status()
           echo "dc/${APP_NAME} is available"

          }
         }
       }

      }     
    }
    
    stage('Run System Testing') {
     steps {
       echo "Starting System Testing"
       script {
         echo "Obtain ${APP_NAME} service"
         def svc_name = "http://${APP_NAME}.${DEV_PROJECT}.svc:8080"
        //def latestDeploymentVersion = openshift.selector('dc',"simple-python").object().status.latestVersion       
         echo "Test Application Status Code == 200"         
         status_code1 = sh (script: "curl -s -o /dev/null -w \"%{http_code}\" ${svc_name}",returnStdout: true)
         echo "${status_code1}"
         if ( "${status_code1}" == "200" ){
           echo "Application Passed Service Response Test"
         } else {
           error("Application Failed Service Response Test")
         }

       }
      }           
    } 
    
    stage('Approve Promotion to Production') {
      steps {
        timeout(time: 30, unit: 'DAYS') {
        input message: "Promote Application to Production?"
      }
     }
    }

    stage('Promoting Application Code to Production') {
     steps {
       echo "Tagging Application Code For Stable Production"
       script {
         openshift.withCluster() {
         openshift.tag( '${DEV_PROJECT}/${APP_NAME}:latest', '${PROD_PROJECT}/${APP_NAME}:latest')
         }
       echo "Application Promoted to Production"
       }
      }     
    }

    stage('Remove all Deployments and Services in Testing Project') {
     steps {
       echo "Removing Deployments and Services for project ${DEV_PROJECT}"
       script {
         openshift.withCluster() {
           openshift.raw("delete dc/mysql -n ${DEV_PROJECT}")
           openshift.raw("delete svc/mysql -n ${DEV_PROJECT}")
           openshift.raw("delete dc/${APP_NAME} -n ${DEV_PROJECT}")
           openshift.raw("delete svc/${APP_NAME} -n ${DEV_PROJECT}")
           openshift.raw("delete route/${APP_NAME} -n ${DEV_PROJECT}")
         }
       echo "Application Promoted to Production"
       }
      }     
    }
   
  }
}
