#!/bin/bash

payram_files="payram_files"
conf="conf"
db="db"
logs="logs"
configFile="config.yaml"

mkdir "$payram_files"
cd "$payram_files"

mkdir "$conf" "$db" "$logs"


touch "$conf/$configFile" 

yaml_content="merchant-info:
  name: 123 Merchant
  domain: http://localhost:8081
  node-url-wss: wss://goerli.infura.io/ws/v3/28b33ed7018e422babdf313f3c0e9697
  success-url: http://localhost:8081/success.html
  cancel-url: http://localhost:8081/cancel.html

payram:
  domain: http://localhost:2357
  payments-domain: http://localhost:2358
"

echo "$yaml_content" > "$conf/$configFile"