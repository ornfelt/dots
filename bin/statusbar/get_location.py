# pip install requests
import requests

def get_location():
    # Get the user's IP details
    response = requests.get('https://ipinfo.io/json')
    data = response.json()
    
    # Extract the city and location data
    city = data.get('city', 'City not found')
    location = data.get('loc', 'Location not found')
    
    print(f"Your city is: {city}")
    print(f"Your location coordinates are: {location}")

get_location()
