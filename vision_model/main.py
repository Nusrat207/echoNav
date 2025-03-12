from fastapi import FastAPI, Form, HTTPException
from typing import Optional, List
import base64
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain.schema.messages import SystemMessage
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_google_genai import ChatGoogleGenerativeAI
from dotenv import load_dotenv
from langchain_community.chat_message_histories import ChatMessageHistory
import logging
import sqlite3
from pydantic import BaseModel
from fastapi.responses import JSONResponse

load_dotenv()

# Initialize FastAPI app
app = FastAPI()

# Set up logging
logging.basicConfig(level=logging.INFO)

# Initialize SQLite database
def init_db():
    conn = sqlite3.connect('tasks.db')
    cursor = conn.cursor()
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY
    )
    ''')
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        title TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''')
    conn.commit()
    conn.close()
    logging.info("Database initialized")

# Call init_db at startup
init_db()

# Global variable to store current user ID
current_user_id = None

# Task model
class Task(BaseModel):
    id: int
    title: str

class Assistant:
    def __init__(self, model):
        self.chain = self._create_inference_chain(model)

    def answer(self, prompt, image=None):
        if not prompt:
            return "No prompt provided."
        
        logging.info(f"Prompt: {prompt}")

        # Make the inference request to the model if a prompt is provided
        response = self.chain.invoke(
            {"prompt": prompt, "image_base64": image},
            config={"configurable": {"session_id": "unused"}}
        ).strip()

        logging.info(f"Response: {response}")

        return response

    def _create_inference_chain(self, model):
        SYSTEM_PROMPT = """
        You are an AI assistant helping visually impaired users navigate their environment.
        Your job is to:
        1. You will use the chat history and the (camera feed) image. Do not mention "image", just use the camera feed.
        2. Identify potential obstacles and hazards
        3. Describe the spatial layout of the environment
        4. Provide clear, concise directional guidance
        5. Use specific distances and directions (left/right/front/back)
        6. Prioritize safety-critical information
        7. DON'T say 'current instruction completed' if you determine that the user is not following your instructions or the user is indoors.
        8. Do not have any special characters in the response as it will be converted to speech.
        Keep responses brief and focused on navigation-relevant details.
        """

        prompt_template = ChatPromptTemplate.from_messages(
            [
                SystemMessage(content=SYSTEM_PROMPT),
                MessagesPlaceholder(variable_name="chat_history"),
                (
                    "human",
                    [
                        {"type": "text", "text": "{prompt}"},
                        {
                            "type": "image_url",
                            "image_url": "data:image/jpeg;base64,{image_base64}",
                        },
                    ],
                ),
            ]
        )

        chain = prompt_template | model | StrOutputParser()

        chat_message_history = ChatMessageHistory()

        return RunnableWithMessageHistory(
            chain,
            get_session_history=lambda _: chat_message_history,
            input_messages_key="prompt",
            history_messages_key="chat_history",
        )

# Initialize the assistant with the Gemini Flash model
model = ChatGoogleGenerativeAI(model="gemini-2.0-flash")
# model = ChatGoogleGenerativeAI(model="gemini-1.5-flash-latest")
assistant = Assistant(model)

@app.post("/api/ask")
async def ask_question(prompt: str = Form(...), image: Optional[str] = Form(None)):
    """
    Receive a prompt and an optional base64-encoded image.
    """
    # Log the received prompt
    logging.info(f"Received prompt: {prompt}")
    
    # If an image is provided, process it
    image_base64 = image  # The image is already expected to be base64 string
    if image_base64:
        logging.info(f"Received image (base64): {image_base64[:30]}...")  # Log first 30 characters of base64 for debug
    
    # If no prompt, return an empty response
    if not prompt:
        return {"response": "No prompt received, camera feed is being ignored."}

    # If a prompt is received, process the image and generate a response
    if image_base64:
        response = assistant.answer(prompt, image_base64)
    else:
        response = assistant.answer(prompt)

    return {"response": response}


@app.post("/api/ask/map")
async def ask_question(prompt: str = Form(...), image: Optional[str] = Form(None)):
    """
    Receive a prompt and an optional base64-encoded image.
    """
    # Log the received prompt
    logging.info(f"Received prompt: {prompt}")
    
    # If an image is provided, process it
    image_base64 = image  # The image is already expected to be base64 string
    if image_base64:
        logging.info(f"Received image (base64): {image_base64[:30]}...")  # Log first 30 characters of base64 for debug
    
    # If no prompt, return an empty response
    if not prompt:
        return {"response": "No prompt received, camera feed is being ignored."}

    # If a prompt is received, process the image and generate a response
    if image_base64:
        response = assistant.answer(prompt, image_base64)
    else:
        response = assistant.answer(prompt)

    return {"response": response}

@app.post("/api/receive_image")
async def receive_image(image: str):
    """
    Continuously receives base64 image frames but does nothing unless a voice prompt is received.
    """
    logging.info(f"Received image frame (base64): {image[:30]}...")  # Log first 30 characters for debugging
    return {"message": "Image received, waiting for voice command."}


@app.post("/api/ask/voice")
async def ask_question(prompt: str = Form(...)):
    """
    Receive a prompt and an optional base64-encoded image.
    """
    # Log the received prompt
    logging.info(f"Received prompt: {prompt}")
   
    if not prompt:
        return {"response": "No prompt received, camera feed is being ignored."}

    # If a prompt is received, process the image and generate a response
    llm = ChatGoogleGenerativeAI(model="gemini-2.0-flash")
    instructions = """You're a helpful assistant. 
    Answer the user's question based on the context provided. 
    Do not have any special characters like * or # in the response as it will be converted to speech.
    If you don't know the answer, say 'I don't know'.
    Do not mention "assistant" in the response.
    Here is the user's speech: {prompt}"""

    response = llm.invoke(instructions).content

    return {"response": response}

# User login endpoint
@app.post("/api/login")
async def login(user_id: str = Form(...)):
    """
    Login a user and set the current user ID
    """
    global current_user_id
    
    # Store user ID in the database if it doesn't exist
    conn = sqlite3.connect('tasks.db')
    cursor = conn.cursor()
    
    # Check if user exists
    cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,))
    user = cursor.fetchone()
    
    if not user:
        # Create new user
        cursor.execute("INSERT INTO users (id) VALUES (?)", (user_id,))
        conn.commit()
        logging.info(f"New user created with ID: {user_id}")
    
    conn.close()
    
    # Set current user ID
    current_user_id = user_id
    logging.info(f"User logged in: {current_user_id}")
    
    return {"user_id": user_id, "message": "Login successful"}

# Get tasks endpoint
@app.get("/api/tasks")
async def get_tasks():
    """
    Get all tasks for the current user
    """
    global current_user_id
    
    if not current_user_id:
        raise HTTPException(status_code=401, detail="No user is currently logged in")
    
    conn = sqlite3.connect('tasks.db')
    cursor = conn.cursor()
    
    cursor.execute("SELECT id, title FROM tasks WHERE user_id = ?", (current_user_id,))
    tasks_data = cursor.fetchall()
    
    conn.close()
    
    tasks = [{"id": task[0], "title": task[1]} for task in tasks_data]
    
    return {"user_id": current_user_id, "tasks": tasks}

# Add task endpoint
@app.post("/api/tasks/add")
async def add_task(task_title: str = Form(...)):
    """
    Add a new task for the current user
    """
    global current_user_id
    
    if not current_user_id:
        raise HTTPException(status_code=401, detail="No user is currently logged in")
    
    if not task_title:
        raise HTTPException(status_code=400, detail="Task title cannot be empty")
    
    conn = sqlite3.connect('tasks.db')
    cursor = conn.cursor()
    
    # Check if user exists
    cursor.execute("SELECT id FROM users WHERE id = ?", (current_user_id,))
    user = cursor.fetchone()
    
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")
    
    # Add task
    cursor.execute("INSERT INTO tasks (user_id, title) VALUES (?, ?)", (current_user_id, task_title))
    task_id = cursor.lastrowid
    conn.commit()
    
    conn.close()
    
    logging.info(f"Task added for user {current_user_id}: {task_title}")
    
    return {"id": task_id, "user_id": current_user_id, "title": task_title}

# Delete task endpoint
@app.delete("/api/tasks/{task_id}")
async def delete_task(task_id: int):
    """
    Delete a task for the current user
    """
    global current_user_id
    
    if not current_user_id:
        raise HTTPException(status_code=401, detail="No user is currently logged in")
    
    conn = sqlite3.connect('tasks.db')
    cursor = conn.cursor()
    
    # Check if task exists and belongs to the user
    cursor.execute("SELECT id FROM tasks WHERE id = ? AND user_id = ?", (task_id, current_user_id))
    task = cursor.fetchone()
    
    if not task:
        conn.close()
        raise HTTPException(status_code=404, detail="Task not found or doesn't belong to the user")
    
    # Delete task
    cursor.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
    conn.commit()
    
    conn.close()
    
    logging.info(f"Task {task_id} deleted for user {current_user_id}")
    
    return {"message": "Task deleted successfully"}

# Delete all tasks for a user
@app.delete("/api/tasks")
async def delete_all_tasks():
    """
    Delete all tasks for the current user
    """
    global current_user_id
    
    if not current_user_id:
        raise HTTPException(status_code=401, detail="No user is currently logged in")
    
    conn = sqlite3.connect('tasks.db')
    cursor = conn.cursor()
    
    # Check if user exists
    cursor.execute("SELECT id FROM users WHERE id = ?", (current_user_id,))
    user = cursor.fetchone()
    
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")
    
    # Delete all tasks for the user
    cursor.execute("DELETE FROM tasks WHERE user_id = ?", (current_user_id,))
    deleted_count = cursor.rowcount
    conn.commit()
    
    conn.close()
    
    logging.info(f"All tasks deleted for user {current_user_id} (count: {deleted_count})")
    
    return {"message": f"Deleted {deleted_count} tasks for user {current_user_id}"}