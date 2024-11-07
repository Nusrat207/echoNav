"""
import numpy as np
import cv2
from scipy.spatial import distance as dist
from flask import Flask, request, jsonify
import base64
import io
from PIL import Image

app = Flask(__name__)

# Constants and settings
Known_distance = 30  # inches
Known_width = 5.7  # inches (average face width)
thres = 0.5  # Threshold for object detection
nms_threshold = 0.2

# Load class names
class_names = []
with open('coco.names', 'r') as f:
    class_names = f.read().splitlines()

# Load model configuration and weights
weightsPath = "frozen_inference_graph.pb"
configPath = "ssd_mobilenet_v3_large_coco_2020_01_14.pbtxt"
net = cv2.dnn_DetectionModel(weightsPath, configPath)
net.setInputSize(320, 320)
net.setInputScale(1.0 / 127.5)
net.setInputMean((127.5, 127.5, 127.5))
net.setInputSwapRB(True)

# Load face detector
face_detector = cv2.CascadeClassifier("haarcascade_frontalface_default.xml")

# Helper functions for distance calculation
def Distance_finder(Focal_Length, real_width, width_in_frame):
    #Calculates the distance between the object and the camera.
    return (real_width * Focal_Length) / width_in_frame

def face_data(image, CallOut=False, Distance_level=0):
    #Detects faces in an image, returning the width and position details.
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_detector.detectMultiScale(gray_image, 1.3, 5)
    face_width = 0
    face_center_x, face_center_y = 0, 0
    for (x, y, w, h) in faces:
        face_width = w
        face_center_x = int(w / 2) + x
        face_center_y = int(h / 2) + y
    return face_width, faces, face_center_x, face_center_y


# Focal length calculation (using a reference image of known size and distance)
ref_image = cv2.imread("lena.png")
ref_face_width, _, _, _ = face_data(ref_image, False, 0)
focal_length = (ref_face_width * Known_distance) / Known_width

def decode_image(image_data):
    # Decode base64 to bytes
    image_bytes = base64.b64decode(image_data)
    # Convert bytes to NumPy array
    np_array = np.frombuffer(image_bytes, np.uint8)
    # Decode NumPy array to OpenCV image
    image = cv2.imdecode(np_array, cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError("Failed to decode image from base64 input")
    return image


@app.route('/check', methods=['GET'])
def checkwork():
    return 'okk'

@app.route("/detect", methods=["POST"])
def detect():
    global focal_length_found
    data = request.get_json()
    image_data = data.get("image")
    Distance_level = 10
    
    try:
        # Decode the base64 image
        image = decode_image(image_data)
    except Exception as e:
        return jsonify({"error": "Image decoding failed", "details": str(e)}), 400

    # Detect objects in the image
    class_ids, confidences, boxes = net.detect(image, confThreshold=thres)
    
    # Convert boxes and confidences to lists for processing
    boxes = list(boxes)
    confidences = list(np.array(confidences).reshape(1, -1)[0])
    confidences = list(map(float, confidences))
    
    # Perform non-maximum suppression to filter boxes
    indices = cv2.dnn.NMSBoxes(boxes, confidences, thres, nms_threshold)

    detections = []
    for i in indices:  # No need to flatten, as we are iterating directly
        box = boxes[i[0]] if isinstance(i, (tuple, list)) else boxes[i]  # Handle tuple/list index
        x, y, w, h = boxes[i]
        detection = {
            "label": class_names[class_ids[i] - 1],  # Accessing class_ids directly
            "confidence": confidences[i],
            "bbox": [int(x), int(y), int(w), int(h)]
        }

        # Calculate distance if a face is detected
        face_width, faces, face_center_x, face_center_y = face_data(image, False, Distance_level)
        if face_width != 0:
            distance = Distance_finder(focal_length_found, Known_width, face_width)
            Distance_level = max(10, int(distance))
            detection["distance"] = round(distance, 2)
        
        detections.append(detection)
    
    # Calculate the distance between detected objects if applicable
    if len(boxes) == 2:
        distance_between_objects = dist.euclidean((boxes[0][0], boxes[0][1]), (boxes[1][0], boxes[1][1]))
        distance_between_objects_cm = round(distance_between_objects / 10, 2)
        warning = "!!MOVE AWAY!!" if distance_between_objects < 250 else ""
    else:
        distance_between_objects_cm = None
        warning = ""

    # Prepare response data
    response_data = {
        "detections": [
            {
                "label": detection["label"],
                "confidence": float(detection["confidence"]),
                "bbox": [int(coord) for coord in detection.get("bbox", [0, 0, 0, 0])],
                "distance": float(detection["distance"]) if "distance" in detection else None,
            }
            for detection in detections
        ],
        "distance_between_objects_cm": distance_between_objects_cm,
        "warning": warning
    }

    print(response_data)
    
    return jsonify(response_data)


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)



"""

from flask import Flask, request, jsonify
import numpy as np
import cv2
from scipy.spatial import distance as dist
import base64

# Initialize Flask app
app = Flask(__name__)

# Constants
KNOWN_DISTANCE = 30  # Distance to reference object in inches
KNOWN_WIDTH = 5.7    # Width of reference object in inches
THRESHOLD = 0.5
NMS_THRESHOLD = 0.2

# Load model files
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

# Calculate focal length based on a reference image
def focal_length_calculator(known_distance, real_width, width_in_image):
    return (width_in_image * known_distance) / real_width

# Distance calculation function
def distance_finder(focal_length, real_width, width_in_frame):
    return (real_width * focal_length) / width_in_frame

# Reference image setup
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
    if 'image' not in request.json:
        return jsonify({"error": "No image uploaded"}), 400

    # Decode base64 image
    try:
        image_data = base64.b64decode(request.json['image'])
        npimg = np.frombuffer(image_data, np.uint8)
        frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
    except Exception as e:
        return jsonify({"error": f"Failed to decode image: {e}"}), 400

    # Perform object detection
    class_ids, confidences, boxes = net.detect(frame, confThreshold=THRESHOLD)
    confidences = list(np.array(confidences).reshape(1, -1)[0])
    confidences = list(map(float, confidences))
    
    indices = cv2.dnn.NMSBoxes(boxes, confidences, THRESHOLD, NMS_THRESHOLD)
    
    detections = []
    
    if len(indices) > 0:
        for i in indices.flatten():
            box = boxes[i]
            (x, y, w, h) = map(int, box)  # Convert coordinates to int
            object_width = w

            # Check for face detection for distance estimation
            gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_detector.detectMultiScale(gray_frame, 1.3, 5)
            if len(faces) > 0:
                face_width_in_frame = int(faces[0][2])  # Convert width to int
                distance = distance_finder(focal_length_found, KNOWN_WIDTH, face_width_in_frame)
            else:
                distance = None

            detections.append({
                "label": class_names[int(class_ids[i]) - 1],  # Convert class_id to int
                "confidence": round(float(confidences[i]), 2),  # Convert confidence to float
                "bounding_box": {"x": x, "y": y, "width": w, "height": h},
                "distance": round(distance, 2) if distance else None
            })

    # Return JSON response
    return jsonify({"detections": detections})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

