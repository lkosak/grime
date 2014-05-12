#!/bin/bash

USERNAME="test"
PASSWORD="test"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36"
ACCEPT="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
ACCEPT_ENCODING="gzip,deflate,sdch"
ACCEPT_LANGUAGE="en-US,en;q=0.8,de;q=0.6,fr;q=0.4"

HEADERS="Accept: $ACCEPT; Accept-Encoding: $ACCEPT_ENCODING; Accept-Language: $ACCEPT_LANGUAGE; Cache-Control: max-age=0; Connection: keep-alive; Origin: https://api.ussquash.com"

rm cookies.txt

curl -IL -c cookies.txt -A "$USER_AGENT" -v -XGET "https://api.ussquash.com/verify_login?redirectTo=https://modules.ussquash.com/ssm/pages/verify_login.asp"
curl -H "$HEADERS" -b cookies.txt --referer https://api.ussquash.com/embedded_login -c cookies.txt --location -A "$USER_AGENT" -v --data "username=$USERNAME&password=$PASSWORD" "https://api.ussquash.com/embedded_login"
curl -v -b cookies.txt "http://modules.ussquash.com/ssm/pages/player_profile.asp?wmode=transparent&program=player&id=79799" > resp.html
open resp.html
