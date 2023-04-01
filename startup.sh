extract_pfx() {
  name=$1
  path=$2
  reverse=$3
  if [ $reverse -eq 1 ]
  then
    openssl pkcs12 -nokeys -in $path -out "$name.crt.temp" -password pass: -passin pass:
    arrayb=$(grep -n "\-\-\-\-\-BEGIN CERTIFICATE\-\-\-\-\-" "$name.crt.temp" | grep -Eo '^[^:]+' | xargs)
    arraye=$(grep -n "\-\-\-\-\-END CERTIFICATE\-\-\-\-\-" "$name.crt.temp" | grep -Eo '^[^:]+')
    arrayb=($arrayb)
    arraye=($arraye)
    l=(9 8 7 6 5 4 3 2 1 0)

    if [ -f "$name.crt" ]
    then
      rm "$name.crt"
    fi
    touch "$name.crt"

    for i in ${l[@]}
    do
      b=${arrayb[$i]}
      e=${arraye[$i]}
      if [ ! -z $b ]
      then
        echo "-----BEGIN CERTIFICATE-----" >> "$name.crt"
        awk -v s="$b" -v e="$e" 'NR>s&&NR<e' "$name.crt.temp" >> "$name.crt"
        echo "-----END CERTIFICATE-----" >> "$name.crt"
      fi
    done
    rm "$name.crt.temp"
  else
    openssl pkcs12 -nokeys -in $path -out "$name.crt" -password pass: -passin pass:
  fi

  openssl pkcs12 -nocerts -in $path -out "$name.key" -password pass: -passin pass: -passout pass:
}

echo "Fetching access token for keyvault..."
identity_url="http://aad-identity-service.default:2424/$AAD_IDENTITY_TENANT?client_id=$AAD_IDENTITY_CLIENTID&secret=$AAD_IDENTITY_SECRET"
identity_url="$identity_url&resource=https://vault.azure.net"
access_token=$(curl -sS $identity_url | jq -r '.access_token')

github_token=$(curl -sS "https://pckv1.vault.azure.net/secrets/github-token?api-version=7.1" -H "Authorization: Bearer $access_token" | jq -r '.value')

echo "Downloading nginx conf list..."
list=$(curl -sS -H "Authorization: token $github_token" -S https://raw.githubusercontent.com/parveenchahal/pc-ingress-configs/main/list | tr -d '\r')
for i in $list; do
  echo "Downloading $i..."
  output_path="/etc/nginx/conf.d/$i"
  if [ $i == 'nginx.conf' ]
  then
    output_path="/etc/nginx/$i"
  fi
  curl -sS -o $output_path -H "Authorization: token $github_token" "https://raw.githubusercontent.com/parveenchahal/pc-ingress-configs/main/$i"
done

cert_name_list=$(curl -sS "https://pckv1.vault.azure.net/secrets/certificate-name-list?api-version=7.1" -H "Authorization: Bearer $access_token" | jq -r '.value')

if [ "$cert_name_list" != "null" ]
then
  for s in $cert_name_list; do
    echo "Downloading certificates $s..."
    pfx="$s.pfx"
    curl -sS "https://pckv1.vault.azure.net/secrets/$s?api-version=7.1" -H "Authorization: Bearer $access_token" | jq -r '.value' | base64 -d > $pfx
    extract_pfx "$s" $pfx 0
    mv "$s.crt" "$s.key" /etc/ssl/
    rm $pfx
  done
fi

cert_name_list=$(curl -sS "https://pckv1.vault.azure.net/secrets/certificate-name-list-reverse?api-version=7.1" -H "Authorization: Bearer $access_token" | jq -r '.value')

if [ "$cert_name_list" != "null" ]
then
  for s in $cert_name_list; do
    echo "Downloading certificates $s..."
    pfx="$s.pfx"
    curl -sS "https://pckv1.vault.azure.net/secrets/$s?api-version=7.1" -H "Authorization: Bearer $access_token" | jq -r '.value' | base64 -d > $pfx
    extract_pfx "$s" $pfx 1
    mv "$s.crt" "$s.key" /etc/ssl/
    rm $pfx
  done
fi

nginx

http_status=$(curl -LI http://127.0.0.1 --max-time 10 -o /dev/null -w '%{http_code}\n' -s)
if [ "$http_status" -ne "200" ]
then
  echo "nginx did not started, exiting"
  exit 1
fi

tail -F /var/log/nginx/error.log
