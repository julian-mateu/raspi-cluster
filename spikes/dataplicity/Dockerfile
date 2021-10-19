FROM ubuntu

ARG CODE

RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1001 ubuntu
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo 'ubuntu:ubuntu' | chpasswd

RUN apt-get update -y
RUN apt-get install -y sudo curl
RUN apt-get install -y python-is-python3
RUN apt-get install -y less
RUN apt-get install -y openssh-server
RUN apt-get install -y supervisor

RUN service ssh start

RUN service supervisor start
RUN curl -s https://www.dataplicity.com/${CODE}.py | python 

USER ubuntu
WORKDIR /home/ubuntu

