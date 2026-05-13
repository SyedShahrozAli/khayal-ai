from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from .firebase import verify_token

_bearer = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
) -> dict:
    """
    FastAPI dependency — verifies the Firebase JWT and returns:
      {"uid": str, "email": str | None}

    Usage:
      @router.get("/me")
      async def me(user: dict = Depends(get_current_user)):
          return user
    """
    token = credentials.credentials
    try:
        payload = verify_token(token)
        return {
            "uid": payload["uid"],
            "email": payload.get("email"),
        }
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired token: {exc}",
        )
