from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from PIL import Image
import torch
import cv2
import numpy as np
import io
import base64

app = FastAPI()

# Load YOLOv9 model
model = torch.hub.load('ultralytics/yolov5', 'custom', path='path/to/gelan-c.pt')  # Update with your YOLOv9 model path

class Detection(BaseModel):
    label: str
    confidence: float
    box: list

@app.websocket("/ws/detect")
async def detect_objects(websocket: WebSocket):
    await websocket.accept()
    
    while True:
        try:
            # Receive the frame as a base64 string from the client
            data = await websocket.receive_text()
            img_data = base64.b64decode(data)
            
            # Convert the image data to an OpenCV image
            np_arr = np.frombuffer(img_data, np.uint8)
            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
            
            # Run object detection on the frame
            results = model(frame)
            
            # Process results and prepare the response
            detections = []
            for pred in results.xyxy[0]:  # xyxy format
                label = model.names[int(pred[5])]
                confidence = float(pred[4])
                box = [float(pred[0]), float(pred[1]), float(pred[2]), float(pred[3])]
                detections.append({"label": label, "confidence": confidence, "box": box})
            
            # Send the detection results back as JSON
            await websocket.send_json(detections)
        
        except Exception as e:
            print(f"Error: {e}")
            break  # Exit on error

    await websocket.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


//pip install fastapi uvicorn torch torchvision opencv-python
