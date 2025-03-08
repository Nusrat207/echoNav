from fastapi import FastAPI, Form
from typing import Optional
import base64
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain.schema.messages import SystemMessage
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_google_genai import ChatGoogleGenerativeAI
from dotenv import load_dotenv
from langchain_community.chat_message_histories import ChatMessageHistory
import logging

load_dotenv()

# Initialize FastAPI app
app = FastAPI()

# Set up logging
logging.basicConfig(level=logging.INFO)

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

@app.post("/api/receive_image")
async def receive_image(image: str):
    """
    Continuously receives base64 image frames but does nothing unless a voice prompt is received.
    """
    logging.info(f"Received image frame (base64): {image[:30]}...")  # Log first 30 characters for debugging
    return {"message": "Image received, waiting for voice command."}