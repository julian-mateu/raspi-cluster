# https://github.com/shkoliar/docker-ngrok
FROM alpine as ngrok

# https://github.com/gliderlabs/docker-alpine/issues/218
RUN apk add --no-cache --virtual .bootstrap-deps ca-certificates && \
        wget -O /tmp/ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip && \
        unzip -o /tmp/ngrok.zip -d / && \
        apk del .bootstrap-deps && \
        rm -rf /tmp/* && \
        rm -rf /var/cache/apk/*

FROM busybox:glibc

ARG AUTH_TOKEN

COPY --from=ngrok /ngrok /bin/ngrok
COPY ./start.sh .
        
RUN mkdir -p /home/ngrok /home/ngrok/.ngrok2
RUN echo "web_addr: 0.0.0.0:4551" > /home/ngrok/.ngrok2/ngrok.yml
# NOTE! This should be using a secret to avoid the token to be logged and commited to the docker image
RUN if [[ ! -z "${AUTH_TOKEN}" ]]; then echo "authtoken: ${AUTH_TOKEN}" >> /home/ngrok/.ngrok2/ngrok.yml; fi
RUN addgroup -g 4551 -S ngrok && \
        adduser -u 4551 -S ngrok -G ngrok -h /home/ngrok -s /bin/ash && \
		chown -R ngrok:ngrok /home/ngrok
RUN chmod +x /start.sh

# no package manager in busy box, this only works if changing to another base image
# RUN apt-get install -y iputils

USER ngrok:ngrok

EXPOSE 4551

CMD /start.sh