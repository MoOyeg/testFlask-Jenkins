FROM registry.redhat.io/openshift4/ose-jenkins-agent-base:v4.7.0
USER root
RUN curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py \
&& python get-pip.py \
&& curl -o requirements.txt https://raw.githubusercontent.com/MoOyeg/testFlask/master/requirements.txt \
&& pip install -r requirements.txt && dnf install -y glibc-langpack-en
RUN echo 'LC_ALL="en_US.UTF-8"' >> /etc/environment
RUN echo 'LC_CTYPE="en_US.UTF-8"' >> /etc/environment
RUN echo 'LANGUAGE="en_US.UTF-8"' >> /etc/environment
USER 1001

