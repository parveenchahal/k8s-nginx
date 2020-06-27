identity="31ff946c-1be9-492f-92ca-c6c3119f5b21"
imdsurl="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$identity"
echo "Downloading nginx.conf..."
wget -O /etc/nginx/nginx.conf "https://pchahal.blob.core.windows.net/nginx/nginx.conf"

echo "Fetching access token for keyvault..."
imdsurl_keyvault="$imdsurl&resource=https%3A%2F%2Fvault.azure.net"
accesstoken=$(curl -sS "$imdsurl_keyvault" -H Metadata:true | jq -r '.access_token')
secrets="richtable-cert richtable-key parveenchahal-cert parveenchahal-key key-pass"
for i in $secrets; do
    echo "Downloading secret $i..."
  curl -sS "https://pckv1.vault.azure.net/secrets/$i?api-version=2016-10-01" -H "Authorization: Bearer $accesstoken" | jq -r '.value' | base64 -d > "/etc/ssl/$i"
done
nginx
tail -F /var/log/nginx/error.log