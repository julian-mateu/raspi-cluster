Originally taken from https://github.com/shkoliar/docker-ngrok, with some extra modifications

There are some issues with networking in docker compose, where nginx, ngrok and others are not able to redirect requests to another service, but pings seem to be working (and the IP gets resolved correctly as per the logs).

- https://github.com/docker/compose/issues/3412

This did not work for my original purposes as with the free version of ngrok I'm not able to use several connections,
and it would not work for both TCP and UDP.