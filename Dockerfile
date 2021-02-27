FROM nginx:1.19.0-alpine
RUN mkdir /app
COPY startup.sh /app
WORKDIR /app
RUN apk add wget
RUN apk add jq
RUN apk add openssl
EXPOSE 80 443
RUN chmod +x startup.sh
CMD ["./startup.sh"]