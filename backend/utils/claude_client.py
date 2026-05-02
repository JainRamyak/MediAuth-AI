# backend/utils/claude_client.py
# NOTE: File name kept as claude_client.py so existing imports don't break.
# Internally uses Groq API instead of Anthropic.

import os
import json
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# Best free model on Groq — fast and capable
MODEL = "llama-3.3-70b-versatile"


def call_claude(system_prompt: str, user_message: str, max_tokens: int = 2000) -> str:
    """
    Call the LLM and return the text response.
    Drop-in replacement for the Anthropic version.
    """
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ],
        temperature=0.3,
        max_tokens=max_tokens,
    )
    return response.choices[0].message.content


def call_claude_for_json(system_prompt: str, user_message: str) -> dict:
    """
    Call the LLM and parse the response as JSON.
    Strips markdown fences if the model adds them.
    Raises json.JSONDecodeError if response is not valid JSON.
    """
    raw = call_claude(system_prompt, user_message, max_tokens=2000)
    
    # Strip markdown code fences if model wraps JSON in them
    clean = raw.strip()
    if clean.startswith("```"):
        lines = clean.split("\n")
        # Remove first line (```json or ```) and last line (```)
        clean = "\n".join(lines[1:-1]).strip()
    
    return json.loads(clean)