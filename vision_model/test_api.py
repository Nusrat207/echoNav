import requests
import base64

# Set the API endpoint URL
url = "http://127.0.0.1:8000/api/ask"

# Test data
prompt = "What is in front of me? And how do I navigate this place"
image_path = r"./room.jpg"  # Update with the correct path

# Read the image and encode it to base64
with open(image_path, "rb") as img_file:
    image_base64 = base64.b64encode(img_file.read()).decode("utf-8")

# Prepare the POST data
data = {
    "prompt": prompt,
    "image": image_base64,  # Send the image as a base64 string
}

# Send the POST request
response = requests.post(url, data=data)

# Check the response status and print the response
if response.status_code == 200:
    print("Response:", response.json())
else:
    print(f"Failed to get a valid response. Status Code: {response.status_code}")
    print(response.text)
