import yaml
import os

PROMPTS_DIR = os.path.join(os.path.dirname(__file__), "..", "prompts")

def load_prompt(agent_name: str) -> dict:
    file_path = os.path.join(PROMPTS_DIR, f"{agent_name}_prompt.yaml")
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Prompt file not found: {file_path}")
    with open(file_path, "r") as f:
        return yaml.safe_load(f)

def get_system_prompt(agent_name: str) -> str:
    return load_prompt(agent_name)["system"]

def get_user_prompt(agent_name: str, **kwargs) -> str:
    template = load_prompt(agent_name)["user_template"]
    return template.format(**kwargs)

def update_prompt(agent_name: str, system: str, user_template: str) -> bool:
    file_path = os.path.join(PROMPTS_DIR, f"{agent_name}_prompt.yaml")
    data = {"system": system, "user_template": user_template}
    with open(file_path, "w") as f:
        yaml.dump(data, f, default_flow_style=False)
    return True