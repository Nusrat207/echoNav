
from flask import Flask, request, jsonify
from deepface import DeepFace
from qdrant_client import QdrantClient
from qdrant_client.http import models
import uuid  # For generating UUIDs

app = Flask(__name__)

# Initialize Qdrant Cloud client
QDRANT_CLOUD_URL = "https://d1b3ebed-15e1-4348-909b-90b03116c9fc.europe-west3-0.gcp.cloud.qdrant.io"  # Replace with your cluster URL
QDRANT_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3MiOiJtIiwiZXhwIjoxNzQ3ODEwNjMzfQ.a3CTikLOMSKZtqQPLr_bPZMhBM8JUFyn8qmwfY9ZqhI"  # Replace with your API key

client = QdrantClient(
    url=QDRANT_CLOUD_URL,
    api_key=QDRANT_API_KEY,
)

collection_name = "face_embeddings"

# Create collection (if it doesn't exist)
try:
    client.get_collection(collection_name)
except Exception:
    client.recreate_collection(
        collection_name=collection_name,
        vectors_config=models.VectorParams(
            size=128,  # Match your embedding size
            distance=models.Distance.COSINE,
        ),
    )

@app.route('/register', methods=['POST'])
def register():
    if 'image' not in request.files:
        #print("No image file provided")
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']
    if file.filename == '':
       # print("Empty file name")
        return jsonify({'error': 'Empty file name'}), 400

    image_path = 'temp.jpg'
    file.save(image_path)
    print(f"Image saved to {image_path}")

    # Generate embedding
    try:
        embedding = DeepFace.represent(img_path=image_path, model_name='Facenet')[0]['embedding']
        #print(f"Generated embedding: {embedding}")
    except Exception as e:
        print(f"Embedding error: {str(e)}")
        return jsonify({'error': f'Embedding error: {str(e)}'}), 500

    # Check if the embedding already exists in the database
    try:
        results = client.search(
            collection_name=collection_name,
            query_vector=embedding,
            limit=1,  # Get the closest match
            score_threshold=0.6,  # Adjust based on your needs
        )

        if results:
            best_match = results[0]
            print(f"User already exists: ID: {best_match.id}, Confidence: {best_match.score}")
            return jsonify({
                'message': 'User already exists!',
                'user': best_match.payload,
                'user_id': best_match.id,
                'confidence': best_match.score,
            }), 200
    except Exception as e:
        print(f"Search error: {str(e)}")
        return jsonify({'error': f'Search error: {str(e)}'}), 500

    # If no match is found, store the new user's data
    try:
        user_name = request.form['name']
        user_id = str(uuid.uuid4())  # Generate a UUID for the user
        client.upsert(
            collection_name=collection_name,
            points=[
                models.PointStruct(
                    id=user_id,  # Use UUID as the ID
                    vector=embedding,
                    payload={"name": user_name},  # Store the name in the payload
                ),
            ],
        )
        print(f"New user registered: {user_name}, ID: {user_id}")
        return jsonify({'message': 'User registered!', 'user_id': user_id})
    except Exception as e:
        print(f"Qdrant error: {str(e)}")
        return jsonify({'error': f'Qdrant error: {str(e)}'}), 500


@app.route('/login', methods=['POST'])
def login():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'Empty file name'}), 400

    image_path = 'temp.jpg'
    file.save(image_path)

    # Generate embedding
    try:
        query_embedding = DeepFace.represent(img_path=image_path, model_name='Facenet')[0]['embedding']
        #print(f"Generated query embedding: {query_embedding}")  # Print the query embedding
    except Exception as e:
        return jsonify({'error': f'Embedding error: {str(e)}'}), 500

    # Search Qdrant Cloud
    try:
        results = client.search(
            collection_name=collection_name,
            query_vector=query_embedding,
            limit=1,  # Get the closest match
            score_threshold=0.6,  # Adjust based on your needs
        )

        if not results:
            return jsonify({'message': 'No match found'}), 404

        best_match = results[0]
        return jsonify({
            'message': 'Login successful!',
            'user': best_match.payload,
            'user_id': best_match.id,
            'confidence': best_match.score,
        })
    except Exception as e:
        return jsonify({'error': f'Search error: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)