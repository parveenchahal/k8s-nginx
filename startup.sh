extract_pfx() {
  name=$1
  path=$2
  openssl pkcs12 -clcerts -nokeys -in $path -out "$name.crt" -password pass: -passin pass:
  openssl pkcs12 -nocerts -in $path -out "$name.key" -password pass: -passin pass: -passout pass:abcxyz
  openssl rsa -in "$name.key" -out "$name.key" -passin pass:abcxyz
}

echo "Downloading nginx.conf..."
wget -O /etc/nginx/nginx.conf "https://pchahal.blob.core.windows.net/nginx/nginx.conf"
wget -O /etc/nginx/conf.d/richtable.conf "https://pchahal.blob.core.windows.net/nginx/richtable.conf"
wget -O /etc/nginx/conf.d/authonline.conf "https://pchahal.blob.core.windows.net/nginx/authonline.conf"
wget -O /etc/nginx/conf.d/amitchahal.conf "https://pchahal.blob.core.windows.net/nginx/amitchahal.conf"
wget -O /etc/nginx/conf.d/parveenchahal.conf "https://pchahal.blob.core.windows.net/nginx/parveenchahal.conf"
wget -O /etc/nginx/conf.d/pcapis.conf "https://pchahal.blob.core.windows.net/nginx/pcapis.conf"

echo "Fetching access token for keyvault..."
identity_url="http://aad-identity-service.default:2424/$AAD_IDENTITY_TENANT?client_id=$AAD_IDENTITY_CLIENTID&secret=$AAD_IDENTITY_SECRET"
identity_url="$identity_url&resource=https://vault.azure.net"
access_token=$(curl -sS $identity_url | jq -r '.access_token')

secrets="richtable-in parveenchahal-com authonline-net pcapis-com"
for i in $secrets; do
  echo "Downloading secret $i..."
  pfx="$i.pfx"
  curl -sS "https://pckv1.vault.azure.net/secrets/$i?api-version=7.1" -H "Authorization: Bearer $access_token" | jq -r '.value' | base64 -d > $pfx
  extract_pfx "$i" $pfx
  mv "$i.crt" "$i.key" /etc/ssl/
  rm $pfx
done

nginx

http_status=$(curl -LI http://127.0.0.1 --max-time 10 -o /dev/null -w '%{http_code}\n' -s)
if [ "$http_status" -ne "200" ]
then
  echo "nginx did not started, exiting"
  exit 1
fi

tail -F /var/log/nginx/error.log