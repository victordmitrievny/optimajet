##Assign driver
from flask import Flask, request
import requests
import json


app = Flask(__name__)

#Launch server
@app.route('/endpoint', methods=['POST'])
def handle_request():
    if request.method == 'POST':

        print('*************')
        print('You recieved a POST request from WFS to Assign XL Driver Service')
        posted_data = request.json
        print('*************')
        print(posted_data)
        return 'Post executed'
    
    else:
        return 'Unsupported HTTP method'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=True)