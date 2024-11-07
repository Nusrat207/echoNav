from flask import Flask, request, jsonify
import numpy as np
import cv2
from scipy.spatial import distance as dist
import base64

app = Flask(__name__)

# Constants
KNOWN_DISTANCE = 30  # Distance to reference object in inches
KNOWN_WIDTH = 5.7    # Width of reference object in inches
THRESHOLD = 0.5
NMS_THRESHOLD = 0.2

# Load model files for object detection
weights_path = "frozen_inference_graph.pb"
config_path = "ssd_mobilenet_v3_large_coco_2020_01_14.pbtxt"
class_names = []
with open('coco.names', 'r') as f:
    class_names = f.read().splitlines()

# Initialize model
net = cv2.dnn_DetectionModel(weights_path, config_path)
net.setInputSize(320, 320)
net.setInputScale(1.0 / 127.5)
net.setInputMean((127.5, 127.5, 127.5))
net.setInputSwapRB(True)

# Load face detector for distance calculation
face_detector = cv2.CascadeClassifier("haarcascade_frontalface_default.xml")

# Function to calculate focal length based on reference image
def focal_length_calculator(known_distance, real_width, width_in_image):
    return (width_in_image * known_distance) / real_width

# Distance calculation function
def distance_finder(focal_length, real_width, width_in_frame):
    return (real_width * focal_length) / width_in_frame

# Setup focal length using a reference image
ref_image = cv2.imread("lena.png")
gray_ref_image = cv2.cvtColor(ref_image, cv2.COLOR_BGR2GRAY)
faces = face_detector.detectMultiScale(gray_ref_image, 1.3, 5)
if len(faces) > 0:
    ref_face_width = faces[0][2]  # Width of face in reference image
    focal_length_found = focal_length_calculator(KNOWN_DISTANCE, KNOWN_WIDTH, ref_face_width)
else:
    raise Exception("Reference face not found in the reference image.")

@app.route('/check', methods=['GET'])
def checkwork():
    return 'okk'

# API endpoint for object detection and distance estimation
@app.route('/detect', methods=['POST'])
def detect_objects():
    #return 'ok'
    if 'image' not in request.json:
        return jsonify({"error": "No image uploaded"}), 400

    # Decode base64 image
    image_data = request.json['image']
    file = np.frombuffer(base64.b64decode(image_data), np.uint8)
    frame = cv2.imdecode(file, cv2.IMREAD_COLOR)

    # Perform object detection
    class_ids, confidences, boxes = net.detect(frame, confThreshold=THRESHOLD)
    confidences = list(map(float, np.array(confidences).reshape(1, -1)[0]))
    indices = cv2.dnn.NMSBoxes(boxes, confidences, THRESHOLD, NMS_THRESHOLD)

    # Prepare response
    detections = []
    for i in indices:
        i = i[0]
        box = boxes[i]
        (x, y, w, h) = box
        label = class_names[class_ids[i][0] - 1]  # Map class ID to label

        # Distance estimation (for faces only in this example)
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_detector.detectMultiScale(gray_frame, 1.3, 5)
        distance = None
        if len(faces) > 0:
            face_width_in_frame = faces[0][2]  # Width of the detected face
            distance = distance_finder(focal_length_found, KNOWN_WIDTH, face_width_in_frame)

        detections.append({
            "label": label,
            "confidence": round(confidences[i], 2),
            "bounding_box": {"x": x, "y": y, "width": w, "height": h},
            "distance": round(distance, 2) if distance else None
        })

    return jsonify({"detections": detections})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
