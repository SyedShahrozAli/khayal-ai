"""
API Gateway — single entry point for all Flutter clients.
Proxies requests to the correct microservice based on URL prefix.
Runs on port 8000.
"""
import httpx
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from routes import ROUTE_MAP

app = FastAPI(title="Khayal AI — API Gateway", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # Tighten this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

_client: httpx.AsyncClient | None = None


@app.on_event("startup")
async def startup():
    global _client
    _client = httpx.AsyncClient(timeout=30.0)
    print("[Gateway] Started — listening on port 8000")


@app.on_event("shutdown")
async def shutdown():
    if _client:
        await _client.aclose()


def _resolve(path: str) -> tuple[str, str] | None:
    """
    Find the downstream base URL and strip the prefix from the path.
    Returns (downstream_url, remaining_path) or None if no match.
    """
    for prefix, base_url in ROUTE_MAP.items():
        if path == prefix or path.startswith(prefix + "/"):
            remaining = path[len(prefix):]
            return base_url, remaining or "/"
    return None


@app.api_route(
    "/{full_path:path}",
    methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
)
async def proxy(request: Request, full_path: str):
    path = "/" + full_path
    resolved = _resolve(path)

    if resolved is None:
        return Response(
            content='{"detail": "Service not found"}',
            status_code=404,
            media_type="application/json",
        )

    base_url, remaining_path = resolved
    target_url = base_url + path

    # Preserve query string
    if request.url.query:
        target_url += f"?{request.url.query}"

    # Forward the request
    body = await request.body()
    headers = dict(request.headers)
    headers.pop("host", None)  # Remove host so httpx sets the correct one

    response = await _client.request(
        method=request.method,
        url=target_url,
        headers=headers,
        content=body,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=dict(response.headers),
        media_type=response.headers.get("content-type"),
    )


@app.get("/health")
async def health():
    return {"status": "ok", "service": "gateway"}
