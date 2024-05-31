#! /bin/bash

#curl -s https://ipinfo.io/json | grep loc | awk -F\" '{print "Your location coordinates are: "$4}'

# sudo pacman -S jq
data=$(curl -s https://ipinfo.io/json)

city=$(echo "$data" | jq -r '.city')
loc=$(echo "$data" | jq -r '.loc')

echo "your city is: $city"
echo "your location coordinates are: $loc"

