# Python program to find current weather details of any city
# using openweathermap api
# From: https://www.geeksforgeeks.org/python-find-current-weather-of-any-city-using-openweathermap-api/

import os
import sys
import requests, json

def kelvinToCelsius(kelvin):
    return kelvin - 273.15

if len(sys.argv) > 1:
    city_name = sys.argv[1]
else:
    city_name = "Uppsala" # Default

api_key = os.getenv('OPENWEATHERMAP_KEY')
if not api_key:
    print("Error: 'OPENWEATHERMAP_KEY' environment variable not set.")
    sys.exit(1) # Exit the script if the API key is not found

base_url = "http://api.openweathermap.org/data/2.5/weather?"
complete_url = base_url + "appid=" + api_key + "&q=" + city_name
response = requests.get(complete_url)
x = response.json()

#print(x)

if x["cod"] != "404":
    # Store the value of "main" key in variable y
    y = x["main"]
 
    # Store the value corresponding to the "temp" key of y
    current_temperature = y["temp"]
 
    # Store the value corresponding to the "pressure" key of y
    current_pressure = y["pressure"]
 
    # Store the value corresponding to the "humidity" key of y
    current_humidity = y["humidity"]
 
    # Store the value of "weather" key in variable z
    z = x["weather"]
 
    # Store the value corresponding to the "description" key at the 0th index
    # of z
    weather_description = z[0]["description"]
 
    #print(" Temperature (in kelvin unit) = " + str(current_temperature) + "\n atmospheric pressure (in hPa unit) = " + str(current_pressure) + "\n humidity (in percentage) = " +
          #str(current_humidity) + "\n description = " + str(weather_description))

    temp = int(kelvinToCelsius(current_temperature))
    if '-' in str(temp):
        print(str(temp) + '°')
    else:
        print('+'+str(temp) + '°')
else:
    print(" City Not Found ")

