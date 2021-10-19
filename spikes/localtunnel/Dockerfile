FROM node

WORKDIR /app

RUN npm install -g localtunnel

COPY ./index.js .

CMD [ "node", "index.js" ]