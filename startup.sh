echo "Downloading nginx.conf..."
wget -O /etc/nginx/nginx.conf "https://pchahal.blob.core.windows.net/nginx/nginx.conf"

echo "Fetching access token for keyvault..."
identity_url="http://aad-identity-service.default:2424/$AAD_IDENTITY_TENANT?client_id=$AAD_IDENTITY_CLIENTID&secret=$AAD_IDENTITY_SECRET"
identity_url="$identity_url&resource=https://vault.azure.net"
accesstoken=$(curl -sS $identity_url | jq -r '.access_token')

curl -sS "https://pckv1.vault.azure.net/secrets/key-pass?api-version=2016-10-01" -H "Authorization: Bearer $accesstoken" | jq -r '.value' | base64 -d > /etc/ssl/key-pass

secrets="richtable-in parveenchahal-com authonline-net"
for i in $secrets; do
  echo "Downloading secret $i..."
  x=$(curl -sS "https://pckv1.vault.azure.net/secrets/$i?api-version=2016-10-01" -H "Authorization: Bearer $accesstoken" | jq -r '.value')
  crt="$(echo $x | cut -d'|' -f1)"
  name="$i.crt"
  echo $crt | base64 -d > /etc/ssl/$name

  key="$(echo $x | cut -d'|' -f2)"
  name="$i.key"
  echo $key | base64 -d > /etc/ssl/$name
done

nginx
tail -F /var/log/nginx/error.log