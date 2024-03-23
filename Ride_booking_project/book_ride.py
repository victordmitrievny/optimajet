#Book a ride
from flask import Flask, request
import uuid
import requests
import json

app = Flask(__name__)

#Start server and wait for the data from the form
@app.route('/form', methods=['POST'])
def recieve_form():
    if request.method == 'POST':

        username = request.form['username']
        email = request.form['email']
        amount = request.form['amount']

        print(username,' ', email, ' ', amount)

        submit_data_WFS(username, email, amount)

        return 'Execution successful'


#Create WFS process instance, submit data as parameters and execute "Next" command
def submit_data_WFS(input1, input2, input3):
    
    #Create ProcessId
    headers = {'Content-Type': 'application/json'}
    processid = str(uuid.uuid4())
    print('******')
    print('ProcessId - ', processid)

    #Create a process Instance
    url = 'http://localhost:8077/workflowapi/createinstance/' + processid
    data = {"schemeCode": "Ride_booking_app_project", 
            "token": None,
            "parameters": [
                            {
                            "persist": True,
                            "name": "customer_name",
                            "value": input1
                            },
                            {
                            "persist": True,
                            "name": "customer_email",
                            "value": input2
                            },
                            {
                            "persist": True,
                            "name": "number_of_people",
                            "value": input3
                            }
                            ]
            }

    print('******')
    print('url is', url)

    response = requests.post(url, data=json.dumps(data), headers=headers)
    json_response = response.json()

    print('******')
    print(json_response)

    #Execute move forward command
    url = 'http://localhost:8077/workflowapi/executecommand/' + processid
    data = {"command": "Next", "token": None}; 

    response = requests.post(url, data=json.dumps(data), headers=headers)
    json_response = response.json()

    print('******')
    print(json_response)

    return 'Execution successful'


if __name__ == '__main__':
    app.run(debug=True, port=8080)