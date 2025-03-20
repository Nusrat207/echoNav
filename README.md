# EchoNav

EchoNav is a mobile application built with Flutter, designed to empower visually impaired individuals by offering accessible tools for daily tasks, navigation, and communication. The app utilizes voice control for hands-free interaction and AI-driven object and speech recognition to provide real-time descriptions of surroundings.
<img src="./DEMO/landing.jpg" alt="App Logo/Banner Image" width="300"/>

## Key Features

### 1. Face Authentication
- Secure user login using facial recognition
- Flask-based backend for fast and accurate face detection
- Automatic user session management

### 2. Voice-Controlled Interface
- Complete hands-free operation
- Voice feedback for all actions
- Hands-free navigation throughout the app
- Voice command recognition for all app features


<img src="./DEMO/menu.jpg" alt="Voice Control Interface Image" width="250"/>

### 3. Voice Assistant
- Natural language processing for user commands
- Speech-to-text and text-to-speech capabilities
- Context aware AI conversation assistant 


<img src="./DEMO/va.jpg" alt="Voice Assistant Interface" width="250"/>

### 4. Vision Recognition
- Real-time object detection and scene recognition
- Object text recognition and reading, directions to surroundings
- Environment description for visually impaired users
- FastAPI backend for quick processing 
- Support for camera feed

<img src="./DEMO/vision.jpg" alt="Vision Recognition Demo Image" width="250"/>

### 5. Navigation Assistance
- Voice-guided navigation
- Integration with Google Maps
- Real-time location tracking
- Accessible route planning and directions
- Audio feedback for navigation cues

<img src="./DEMO/navigation.jpg" alt="Navigation Interface Image" width="250"/>

### 6. Task Management
- Voice-controlled task creation and management
- Natural language based task overview, add, delete operations
- SQLite database for local storage

<img src="./DEMO/task.jpg" alt="Task Management Interface Image" width="250"/>

### 7. Premium Features (Subscription Plans)

EchoNav offers several subscription plans with enhanced features:

#### Yearly Plan (BEST VALUE)
- ৳600 (33% savings from original ৳900)
- 7 days free trial
- All premium features included

#### 3 Months Plan (MOST POPULAR)
- ৳220 (27% savings from original ৳300)
- 3 days free trial
- All premium features included

#### 1 Month Plan
- ৳80 (20% savings from original ৳100)
- All premium features included

<img src="./DEMO/subsciption_1.jpg" alt="Subscription Plans Interface Image" width="250"/>

All premium plans include:
- Faster object recognition
- Unlimited prompts
- Priority support
- Advanced navigation features
- Enhanced voice commands
- Premium user support

<img src="./DEMO/subsciption_2.jpg" alt="Subscription Plans Interface Image" width="250"/>
<img src="./DEMO/subsciption_3.jpg" alt="Subscription Plans Interface Image" width="250"/>

### Frontend (Flutter)
- Material Design UI
- Responsive layout
- Accessibility features
- Cross-platform compatibility

### Backend Services

#### 1. Facial Recognition Server (Flask)
- User authentication
- Face detection and recognition (Deepface Model)
- Session management
- Runs on port 5000

#### 2. Vision Model Server (FastAPI)
- Object detection and directions system
- Scene recognition
- Navigation assistance using Gemini Flash 2.0
- Task management
- Runs on port 8000
- Implemented with LangChain
## Prerequisites

Before running the application, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (2.0.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (2.12.0 or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Python](https://www.python.org/downloads/) (3.7+ for backends)
- [pip](https://pip.pypa.io/en/stable/installation/)

## Installation and Setup

### 1. Flutter Frontend
```bash
git clone https://github.com/yourusername/echonav.git
cd echonav
flutter pub get
```

### 2. Facial Recognition Backend (Flask)
```bash
cd facial_recognition_backend
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install flask opencv-python face_recognition dlib numpy
python app.py
```

### 3. Vision Model Backend (FastAPI)
```bash
cd vision_model
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt
python main.py
```

#### Face Recognition Configuration
The backend uses:
- DeepFace for facial recognition
- Qdrant Cloud for vector database storage
- Collection name: "face_embeddings"
- Vector size: 128
- Distance metric: Cosine similarity

### Environment Variables (.env)
The facial recognition backend requires:
```bash
QDRANT_CLOUD_URL=https://your-qdrant-cluster-url
QDRANT_API_KEY=your-qdrant-api-key
```

### Server Configuration
To run the Flask server:
```bash
python app.py
```
Server runs on `http://0.0.0.0:5000` by default

### Database Details
- Uses Qdrant Cloud for face embedding storage
- Collection automatically created if not exists
- Vectors configured for facial recognition:
  - Size: 128 dimensions
  - Distance: Cosine similarity
  - Optimized for facial recognition queries

### Security Features
- UUID-based user identification
- Secure face embedding storage
- API key authentication for Qdrant Cloud
- Debug mode configurable
- CORS support for cross-origin requests


### Dependencies
Key dependencies include:
- Flask
- DeepFace
- Qdrant Client
- OpenCV
- NumPy

Install all dependencies using:
```bash
pip install -r requirements.txt
```

