"""
get_token.py — Gets a Firebase ID token for API testing.

Usage:
  .venv/bin/python get_token.py

You need:
  1. FIREBASE_WEB_API_KEY in .env
  2. A registered user email + password in your Firebase project

The script prints a Bearer token you can paste into Swagger UI or curl.
"""
import os
import sys
import json
import urllib.request
import urllib.error
from dotenv import load_dotenv

# Load .env from the backend directory
_here = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(_here, ".env"))

API_KEY = os.getenv("FIREBASE_WEB_API_KEY")
if not API_KEY:
    print("\n[ERROR] FIREBASE_WEB_API_KEY is not set in your .env file.")
    print("  → Go to Firebase Console → Project Settings → General → Web API Key")
    print("  → Add it to backend/.env as:  FIREBASE_WEB_API_KEY=AIza...")
    sys.exit(1)

email    = input("Email: ").strip()
password = input("Password: ").strip()

url     = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
payload = json.dumps({
    "email": email,
    "password": password,
    "returnSecureToken": True,
}).encode()

req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})

try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
        token = data["idToken"]
        print("\n" + "="*60)
        print("✅ Token (valid for 1 hour):")
        print("="*60)
        print(token)
        print("="*60)
        print("\nPaste this into Swagger UI → Authorize → Bearer <token>")
        print("Or use with curl:")
        print(f'  curl -H "Authorization: Bearer {token[:30]}..." http://localhost:8000/auth/me')
except urllib.error.HTTPError as e:
    err = json.loads(e.read())
    print(f"\n[ERROR] {err.get('error', {}).get('message', 'Unknown error')}")
    print("Make sure the email/password is registered in Firebase Auth.")
