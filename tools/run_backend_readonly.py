"""Temporary mobile QA server. Backend source is imported read-only; no seeds/migrations."""
import os
import secrets
import sys
from pathlib import Path

sys.dont_write_bytecode = True
mobile_root = Path(__file__).resolve().parents[1]
backend_root = Path(r"D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend")
sys.path.insert(0, str(backend_root))
os.environ["INTERNAL_API_SECRET"] = secrets.token_urlsafe(48)
os.environ["PGOPTIONS"] = "-c default_transaction_read_only=on"
os.environ["STORAGE_DIR"] = str(mobile_root / "docs" / "evidence" / "readonly-api-storage")
os.environ["NODE_ENV"] = "production"

from app.main import app
from starlette.responses import JSONResponse

@app.middleware("http")
async def restrict_qa_requests(request, call_next):
    allowed = request.method in {"GET", "HEAD", "OPTIONS"} or (
        request.method == "POST" and request.url.path in {"/auth/login", "/auth/logout"}
    )
    if not allowed:
        return JSONResponse({"detail": "Read-only mobile QA server"}, status_code=405)
    return await call_next(request)

if __name__ == "__main__":
    import uvicorn
    print("Temporary read-only QA API: http://127.0.0.1:3001", flush=True)
    uvicorn.run(app, host="127.0.0.1", port=3001, access_log=False, log_level="warning")
