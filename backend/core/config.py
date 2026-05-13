from pydantic_settings import BaseSettings
import os

# Absolute path to backend/ directory — works no matter where uvicorn is invoked from
_BACKEND_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
_ENV_FILE = os.path.join(_BACKEND_DIR, ".env")


class Settings(BaseSettings):
    MONGODB_URI: str
    MONGODB_DB_NAME: str = "khayal-ai"
    FIREBASE_CREDENTIALS_PATH: str

    model_config = {
        "env_file": _ENV_FILE,
        "env_file_encoding": "utf-8",
    }


settings = Settings()

