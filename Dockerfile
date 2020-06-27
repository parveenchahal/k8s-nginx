FROM nginx:1.19.0-alpine
COPY . /nginx-startup
WORKDIR /nginx-startup
RUN apk add wget
RUN apk add jq
EXPOSE 80 443
RUN chmod +x startup.sh
CMD ["./startup.sh"]