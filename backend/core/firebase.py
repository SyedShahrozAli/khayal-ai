import os
import firebase_admin
from firebase_admin import credentials, auth as firebase_auth
from .config import settings, _BACKEND_DIR


def _resolve_credentials_path() -> str:
    path = settings.FIREBASE_CREDENTIALS_PATH
    if not os.path.isabs(path):
        path = os.path.join(_BACKEND_DIR, path)
    return path


def init_firebase() -> None:
    """Initialise firebase-admin. Safe to call multiple times."""
    if not firebase_admin._apps:
        cred = credentials.Certificate(_resolve_credentials_path())
        firebase_admin.initialize_app(cred)
        print("[Firebase] firebase-admin initialised")


def verify_token(token: str) -> dict:
    """
    Verify a Firebase ID token and return its decoded claims.
    Raises firebase_admin.auth.InvalidIdTokenError on failure.
    """
    return firebase_auth.verify_id_token(token)

