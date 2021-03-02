FROM registry.redhat.io/openshift4/ose-jenkins-agent-base:v4.7.0
USER root
RUN yum install -y git python36 \
&& curl -O https://raw.githubusercontent.com/MoOyeg/testFlask/master/requirements.txt \
&& pip install -r requirements.txt
USER 1001
