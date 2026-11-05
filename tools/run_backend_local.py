"""Local QA API using existing frontend auth settings; no migrations/seeds."""
import os, sys, argparse, ipaddress
from pathlib import Path
sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[1]
from dotenv import dotenv_values
config = dotenv_values(r"D:\DeXa_Assessment_fik\ai-assessment-copilot\apps\frontend\.env")
secret = next((config[k] for k in ("INTERNAL_API_SECRET", "AUTH_SECRET", "SECRET_KEY", "NEXTAUTH_SECRET") if config.get(k)), None)
if not secret or len(secret)<32: raise SystemExit("Frontend auth configuration missing; no changes made")
os.environ["INTERNAL_API_SECRET"]=secret
os.environ["DATABASE_URL"]=config["DATABASE_URL"]
os.environ["STORAGE_DIR"]=str(root/".local/backend-storage")
os.environ["NODE_ENV"]="production"
sys.path.insert(0,r"D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend")
import uvicorn
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--host', default='127.0.0.1', help='Explicit local interface IP for QA')
args = parser.parse_args()
bind_ip = ipaddress.ip_address(args.host)
if bind_ip.is_unspecified or bind_ip.is_multicast: raise SystemExit('Specify one local interface IP; wildcard binding is not allowed')
uvicorn.run("app.main:app",host=args.host,port=3001,access_log=False)
