FROM node:20-alpine
RUN apk add --no-cache curl bash
ARG VERSION=1
ENV VERSION=$VERSION
WORKDIR /app
COPY server.js .
EXPOSE 8080
CMD ["node", "server.js"]
