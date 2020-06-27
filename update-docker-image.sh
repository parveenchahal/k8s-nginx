tag=$1
if [ -z $tag ]
then
  tag='latest'
fi
sudo docker pull pchahal24/k8s-nginx:$tag
sudo docker ps | grep k8s-nginx | awk '{print $1}' | xargs sudo docker stop
sudo docker rm k8s-nginx
sudo docker run -d -p 80:80 -p 443:443 --restart=always --name k8s-nginx  pchahal24/k8s-nginx:$tag

