import anthropic
import os
from dotenv import load_dotenv

load_dotenv()
client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

def call_claude(system_prompt: str, user_message: str, max_tokens: int = 2000) -> str:
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=max_tokens,
        system=system_prompt,
        messages=[{"role": "user", "content": user_message}]
    )
    return message.content[0].text

def call_claude_for_json(system_prompt: str, user_message: str) -> dict:
    import json
    response_text = call_claude(system_prompt, user_message, max_tokens=2000)
    cleaned = response_text.strip()
    if cleaned.startswith("```"):
        lines = cleaned.split("\n")
        cleaned = "\n".join(lines[1:-1])
    return json.loads(cleaned)