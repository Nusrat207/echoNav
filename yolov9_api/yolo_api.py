from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from PIL import Image
import torch
import io

app = FastAPI()

# Load YOLOv9 model
model = torch.hub.load('ultralytics/yolov5', 'custom', path='path/to/gelan-c.pt')  # Replace with your YOLOv9 model

class DetectionResponse(BaseModel):
    label: str
    confidence: float
    box: list

@app.post("/detect", response_model=list[DetectionResponse])
async def detect_objects(file: UploadFile = File(...)):
    # Load image
    image_data = await file.read()
    image = Image.open(io.BytesIO(image_data))

    # Run object detection
    results = model(image)
    
    # Process results
    detections = []
    for pred in results.xyxy[0]:  # xyxy format
        label = model.names[int(pred[5])]
        confidence = float(pred[4])
        box = [float(pred[0]), float(pred[1]), float(pred[2]), float(pred[3])]
        detections.append({"label": label, "confidence": confidence, "box": box})
    
    return detections

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


//pip install fastapi uvicorn torch torchvision
