# vision_server.py
from fastapi import FastAPI, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
import base64
import cv2
import numpy as np
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain.schema.messages import SystemMessage
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_community.chat_message_histories import ChatMessageHistory
import logging
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class VisionAssistant:
    def __init__(self):
        self.model = ChatGoogleGenerativeAI(model="gemini-1.5-flash-latest")
        self.chain = self._create_inference_chain()

    def _create_inference_chain(self):
        SYSTEM_PROMPT = """
        You are an AI assistant helping visually impaired users navigate their environment.
        Your job is to:
        1. Identify potential obstacles and hazards
        2. Describe the spatial layout of the environment
        3. Provide clear, concise directional guidance
        4. Use specific distances and directions (left/right/front/back)
        5. Prioritize safety-critical information
        
        Keep responses brief and focused on navigation-relevant details.
        """

        prompt_template = ChatPromptTemplate.from_messages([
            SystemMessage(content=SYSTEM_PROMPT),
            MessagesPlaceholder(variable_name="chat_history"),
            ("human", [
                {"type": "text", "text": "{prompt}"},
                {"type": "image_url", "image_url": "data:image/jpeg;base64,{image_base64}"},
            ]),
        ])

        chain = prompt_template | self.model | StrOutputParser()
        chat_history = ChatMessageHistory()
        
        return RunnableWithMessageHistory(
            chain,
            lambda _: chat_history,
            input_messages_key="prompt",
            history_messages_key="chat_history",
        )

    async def process_image(self, image_base64: str, prompt: str) -> str:
        try:
            response = self.chain.invoke(
                {"prompt": prompt, "image_base64": image_base64},
                config={"configurable": {"session_id": "navigation"}},
            )
            return response.strip()
        except Exception as e:
            logger.error(f"Error processing image: {e}")
            raise HTTPException(status_code=500, detail=str(e))

# Initialize the vision assistant
assistant = VisionAssistant()

@app.post("/api/analyze")
async def analyze_image(prompt: str = Form(...), image: Optional[str] = Form(None)):
    """
    Analyze an image and provide navigation guidance.
    """
    try:
        if not image:
            raise HTTPException(status_code=400, detail="No image provided")
            
        response = await assistant.process_image(image, prompt)
        return {"response": response}
        
    except Exception as e:
        logger.error(f"Error in analyze_image endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)