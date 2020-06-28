echo "Downloading nginx.conf..."
wget -O /etc/nginx/nginx.conf "https://pchahal.blob.core.windows.net/nginx/nginx.conf"

echo "Fetching access token for keyvault..."
identity_url="http://aad-identity-service:2424/$AAD_IDENTITY_TENANT?client_id=$AAD_IDENTITY_CLIENTID&secret=$AAD_IDENTITY_SECRET"
identity_url="$identity_url&resource=https://vault.azure.net"
accesstoken=$(curl -sS $identity_url | jq -r '.access_token')

secrets="richtable-cert richtable-key parveenchahal-cert parveenchahal-key key-pass"
for i in $secrets; do
    echo "Downloading secret $i..."
  curl -sS "https://pckv1.vault.azure.net/secrets/$i?api-version=2016-10-01" -H "Authorization: Bearer $accesstoken" | jq -r '.value' | base64 -d > "/etc/ssl/$i"
done

nginx
tail -F /var/log/nginx/error.log