FROM nginx:1.14.0-alpine

RUN apk --no-cache add curl
RUN rm -rf /usr/share/nginx/html/*

COPY /dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/

CMD ["nginx", "-g", "daemon off;"]
