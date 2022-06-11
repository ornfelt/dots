# Python program to find current
# weather details of any city
# using openweathermap api
# From: https://www.geeksforgeeks.org/python-find-current-weather-of-any-city-using-openweathermap-api/

def kelvinToCelsius(kelvin):
    return kelvin - 273.15

import requests, json

api_key = "83d7f99badc359fb59cd5f2101fddcad"
base_url = "http://api.openweathermap.org/data/2.5/weather?"
city_name = "Uppsala"
complete_url = base_url + "appid=" + api_key + "&q=" + city_name
response = requests.get(complete_url)
x = response.json()

#print(x)

if x["cod"] != "404":
 
    # store the value of "main"
    # key in variable y
    y = x["main"]
 
    # store the value corresponding
    # to the "temp" key of y
    current_temperature = y["temp"]
 
    # store the value corresponding
    # to the "pressure" key of y
    current_pressure = y["pressure"]
 
    # store the value corresponding
    # to the "humidity" key of y
    current_humidity = y["humidity"]
 
    # store the value of "weather"
    # key in variable z
    z = x["weather"]
 
    # store the value corresponding
    # to the "description" key at
    # the 0th index of z
    weather_description = z[0]["description"]
 
    # print following values
    #print(" Temperature (in kelvin unit) = " + str(current_temperature) + "\n atmospheric pressure (in hPa unit) = " + str(current_pressure) + "\n humidity (in percentage) = " +
          #str(current_humidity) + "\n description = " + str(weather_description))

    temp = int(kelvinToCelsius(current_temperature))
    if '-' in str(temp):
        print(temp)
    else:
        print('+'+str(temp))

 
else:
    print(" City Not Found ")
