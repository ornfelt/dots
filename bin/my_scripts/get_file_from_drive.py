# pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

from __future__ import print_function
import os.path
import io
import pickle
import json
import re
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

# If modifying these SCOPES, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/drive.readonly']
BASE_DIR = "/home/jonas/Documents/gdrive/"

def authenticate():
    """Shows basic usage of the Drive v3 API."""
    creds = None
    # The file token.pickle stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    token_path = os.path.join(BASE_DIR, 'token.pickle')
    if os.path.exists(token_path):
        with open(token_path, 'rb') as token_file:
            token_content = token_file.read()
            # Decode the binary content to string
            token_str = token_content.decode('utf-8', errors='ignore')
            # Extract the JSON content from the token string
            json_content = re.search(r'\{.*\}', token_str, re.DOTALL).group()
            creds = Credentials.from_authorized_user_info(json.loads(json_content), SCOPES)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(BASE_DIR + 'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open(BASE_DIR + 'token.pickle', 'wb') as token:
            pickle.dump(creds.to_json(), token)

    return creds

def search_file(service, file_name):
    """Search for a file by name and return its ID."""
    results = service.files().list(
        q=f"name='{file_name}'",
        spaces='drive',
        fields="files(id, name)",
        pageSize=10).execute()
    items = results.get('files', [])

    if not items:
        print('No files found.')
        return None
    else:
        for item in items:
            print(f"Found file: {item['name']} (ID: {item['id']})")
        return items[0]['id']  # Return the ID of the first file found

def download_file(file_id, file_name):
    """Download a file by its ID."""
    creds = authenticate()
    service = build('drive', 'v3', credentials=creds)

    # Construct the file path using BASE_DIR
    file_path = os.path.join(BASE_DIR, file_name)

    # Call the Drive v3 API
    request = service.files().get_media(fileId=file_id)
    fh = io.FileIO(file_path, 'wb')
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while done is False:
        status, done = downloader.next_chunk()
        print("Download %d%%." % int(status.progress() * 100))

if __name__ == '__main__':
    creds = authenticate()
    service = build('drive', 'v3', credentials=creds)

    # File to download
    FILE_NAME = '.bash_profile'

    file_id = search_file(service, FILE_NAME)
    if file_id:
        download_file(file_id, FILE_NAME)

