import asyncio
import sys
import aiohttp

from pipecat.frames.frames import Frame, TranscriptionFrame, TextFrame
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.runner import PipelineRunner
from pipecat.pipeline.task import PipelineTask
from pipecat.processors.frame_processor import FrameDirection, FrameProcessor
from pipecat.transports.base_transport import TransportParams
from pipecat.transports.local.audio import LocalAudioTransport
from pipecat.services.deepgram import DeepgramSTTService, DeepgramTTSService
from loguru import logger

import os

from langchain_openai import AzureChatOpenAI
from langchain.prompts import PromptTemplate
from langchain_community.llms import HuggingFaceHub

logger.remove(0)
logger.add(sys.stderr, level="DEBUG")

DEEPGRAM_API_KEY = "d983b688bb5ee09749accb49cbe70c4453bb7ea1"
HUGGINGFACEHUB_API_TOKEN = "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"

# model_id = "gpt2-medium"
model_id = "google/flan-t5-large"

llm = HuggingFaceHub(huggingfacehub_api_token=
                            HUGGINGFACEHUB_API_TOKEN,
                            repo_id=model_id,
                            model_kwargs={"temperature":0.8, "max_new_tokens":150})

prompt_template = """ 
You are a helpful assistant who will answer the user's query as best as possible.
Question:
{question}
"""

prompt = PromptTemplate(input_variables=["question"], template=prompt_template,                      )

chain = prompt | llm

def ask_query(query):
    answer = chain.invoke(input = {
        "question": query
    })
    return answer

class TranscriptionToTTS(FrameProcessor):
    def __init__(self, tts_task):
        super().__init__()
        self.tts_task = tts_task

    async def process_frame(self, frame: Frame, direction: FrameDirection):
        await super().process_frame(frame, direction)

        if isinstance(frame, TranscriptionFrame):
            print(f"Transcription: {frame.text}")
            response = ask_query(frame.text)
            print(f'Assistant:  {response}')
            await self.tts_task.queue_frame(TextFrame(response))


async def main():
    transport_in = LocalAudioTransport(TransportParams(audio_in_enabled=True))
    transport_out = LocalAudioTransport(TransportParams(audio_out_enabled=True))

    stt = DeepgramSTTService(api_key=DEEPGRAM_API_KEY)

    async with aiohttp.ClientSession() as session:
        tts = DeepgramTTSService(api_key=DEEPGRAM_API_KEY, aiohttp_session=session)

        tts_pipeline = Pipeline([tts, transport_out.output()])
        tts_task = PipelineTask(tts_pipeline)

        tl = TranscriptionToTTS(tts_task)
        stt_pipeline = Pipeline([transport_in.input(), stt, tl])
        stt_task = PipelineTask(stt_pipeline)

        runner = PipelineRunner()

        await asyncio.gather(
            runner.run(stt_task), 
            runner.run(tts_task)   
        )


if __name__ == "__main__":
    asyncio.run(main())
