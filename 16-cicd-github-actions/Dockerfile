FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY app/ ./app/
ARG BUILD_SHA=local
ENV BUILD_SHA=$BUILD_SHA
EXPOSE 3000
USER node
CMD ["node", "app/server.js"]
