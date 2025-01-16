# vision_model

if virtul env isn't installed:
pip install virtualenv
 
to run the backend:
###
cd vision_model  
python -m venv venv  
./venv/bin/Scripts/Activate  
pip install -r requirements.txt  

###
uvicorn main:app --host 0.0.0.0 --port 8000
###
from vision.dart
###
var url = Uri.parse("http://192.168.0.104:8000/api/ask"); // for physcial phone (phone's ip)
###
var url = Uri.parse("http://10.0.2.2:8000/api/ask"); // for emulator
