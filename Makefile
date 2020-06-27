docker-build:
	sudo docker build . -t ${IMG}

docker-push:
	sudo docker push ${IMG}