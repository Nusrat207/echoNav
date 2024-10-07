from flask import Flask, request, jsonify
import os
from langchain_community.llms import HuggingFaceHub
from langchain.prompts import PromptTemplate

app = Flask(__name__)

HUGGINGFACEHUB_API_TOKEN = "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"
model_id = "google/flan-t5-large"

llm = HuggingFaceHub(huggingfacehub_api_token=HUGGINGFACEHUB_API_TOKEN,
                     repo_id=model_id,
                     model_kwargs={"temperature": 0.8, "max_new_tokens": 150})

prompt_template = """
You are a helpful assistant who will answer the user's query as best as possible.
Question:
{question}
"""

prompt = PromptTemplate(input_variables=["question"], template=prompt_template)

@app.route('/ask', methods=['POST'])
def ask_query():
    data = request.json
    query = data.get('question', '')

    if not query:
        return jsonify({"error": "No question provided"}), 400

    answer = prompt | llm
    response = answer.invoke(input={"question": query})

    return jsonify({"answer": response})

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)
