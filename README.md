# EchoNav

EchoNav is a mobile application built with Flutter, designed to empower visually impaired individuals by offering accessible tools for daily tasks, navigation, and communication. The app utilizes voice control for hands-free interaction and AI-driven object recognition to provide real-time descriptions of surroundings.
![App Logo/Banner Image](.@DEMO/@landing.jpg)

## Key Features

### 1. Face Authentication
- Secure user login using facial recognition
- Flask-based backend for fast and accurate face detection
- Automatic user session management

### 2. Voice Assistant
- Natural language processing for user commands
- Speech-to-text and text-to-speech capabilities
- Hands-free navigation throughout the app
- Voice command recognition for all app features

![Voice Assistant Interface](./@DEMO/va.jpg)

### 3. Vision Recognition
- Real-time object detection and scene recognition
- Text recognition and reading
- Environment description for visually impaired users
- FastAPI backend for quick processing
- Support for both static images and real-time camera feed

![Vision Recognition Demo Image](./@DEMO/vision.jpg)

### 4. Navigation Assistance
- Voice-guided navigation
- Integration with Google Maps
- Real-time location tracking
- Accessible route planning and directions
- Audio feedback for navigation cues

![Navigation Interface Image](./@DEMO/navigation.jpg)

### 5. Task Management
- Voice-controlled task creation and management
- Reminder system with audio notifications
- Calendar integration
- Priority-based task organization
- SQLite database for local storage

![Task Management Interface Image](./@DEMO/task.jpg)

### 6. Premium Features (Subscription Plans)

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

![Subscription Plans Interface Image](./@DEMO/subscription_1.jpg)

All premium plans include:
- Faster object recognition
- Unlimited prompts
- Priority support
- Advanced navigation features
- Enhanced voice commands
- Premium user support


![Subscription Plans Interface Image](./@DEMO/subscription_2.jpg)
![Subscription Plans Interface Image](./@DEMO/subscription_3.jpg)


### 7. Voice-Controlled Interface
- Complete hands-free operation
- Natural language command processing
- Voice feedback for all actions
- Customizable voice settings
- Multiple language support

![Voice Control Interface Image](./@DEMO/menu.jpg)

### Frontend (Flutter)
- Material Design UI
- Responsive layout
- Accessibility features
- Cross-platform compatibility
- Local data persistence using Hive

### Backend Services

#### 1. Facial Recognition Server (Flask)
- User authentication
- Face detection and recognition
- Session management
- Runs on port 5000

#### 2. Vision Model Server (FastAPI)
- Object detection
- Scene recognition
- Navigation assistance
- Task management
- Runs on port 8000

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

## API Documentation

### Facial Recognition Endpoints (Flask - Port 5000)

#### User Registration and Authentication
- `POST /register`
  - Registers a new user with facial data
  - Parameters:
    - `image`: Base64 encoded facial image
    - `name`: User name (optional)
  - Returns:
    - `user_id`: Unique identifier for the registered user
    - Success/failure message

- `POST /login`
  - Authenticates user using facial recognition
  - Parameters:
    - `image`: Base64 encoded facial image
  - Returns:
    - `user_id`: User identifier if authentication successful
    - Authentication status
    - Error message (if authentication fails)

- `GET /user/{user_id}`
  - Retrieves user profile information
  - Parameters:
    - `user_id`: User identifier
  - Returns:
    - User profile data
    - Registration timestamp
    - Last login information

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

### Error Handling
The API includes comprehensive error handling for:
- Invalid image formats
- Failed face detection
- Database connection issues
- Authentication failures
- Missing or invalid parameters

### Testing
To test the facial recognition endpoints:
1. Ensure the server is running
2. Send a POST request with an image to `/register` or `/login`
3. Image should be base64 encoded
4. Check response for success/failure status

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

### Vision Model Endpoints (FastAPI - Port 8000)

#### Object Detection and Scene Recognition
- `POST /api/detect`
  - Processes images for object detection
  - Returns detected objects, their positions, and distances
  - Parameters:
    - `image`: Base64 encoded image
  - Returns:
    - List of detected objects
    - Object coordinates
    - Distance measurements
    - Warning messages if objects are too close

#### Voice Assistant
- `POST /api/ask`
  - Processes natural language queries
  - Parameters:
    - `question`: String containing the user's query
  - Returns:
    - AI-generated response formatted for visually impaired users

#### Task Management
- `GET /api/tasks`
  - Retrieves all tasks
  - Returns list of tasks with priorities and status

- `POST /api/tasks`
  - Creates a new task
  - Parameters:
    - `title`: Task title
    - `description`: Task description
    - `priority`: Task priority level

- `PUT /api/tasks/{task_id}`
  - Updates existing task
  - Parameters:
    - `task_id`: Task identifier
    - Task update data

- `DELETE /api/tasks/{task_id}`
  - Deletes a task
  - Parameters:
    - `task_id`: Task identifier

- `POST /api/tasks/command`
  - Processes voice commands for task management
  - Parameters:
    - `command`: Voice command string
  - Returns:
    - Action confirmation
    - Updated task status

#### Navigation
- `POST /api/navigate`
  - Provides navigation assistance
  - Parameters:
    - `current_location`: Current coordinates
    - `destination`: Destination coordinates
  - Returns:
    - Navigation instructions
    - Distance information
    - Audio cues

## Security Features
- Secure facial data storage
- Encrypted communication
- Session management
- Payment data protection
- Regular security updates

## Performance Optimization
- Efficient image processing
- Optimized API calls
- Local data caching
- Background processing
- Memory management

## Troubleshooting

### Common Issues and Solutions
1. Camera Access Issues
   - Check app permissions
   - Restart the application
   - Verify camera hardware

2. Voice Recognition Problems
   - Check microphone permissions
   - Verify internet connection
   - Adjust voice settings

3. Backend Connection Errors
   - Verify server addresses
   - Check network connectivity
   - Ensure proper API configuration

## Contributing

We welcome contributions! Please see our contributing guidelines for more details.

## License

[Insert License Information]

## Support and Contact

[Insert Support Information]

## Acknowledgments

[Insert Acknowledgments]

---

[Insert Footer Image/Logo]