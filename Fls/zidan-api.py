from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
import subprocess, json, os

API_TOKEN = "GANTI_TOKEN_RAHASIA_KAMU"

app = FastAPI(title="Zidan VPN API")

def check_token(x_api_key: str | None):
    if x_api_key != API_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")

def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        output = result.stdout.strip()
        if not output:
            output = result.stderr.strip()
        try:
            return json.loads(output)
        except:
            return {"status": "error", "raw": output}
    except Exception as e:
        return {"status": "error", "message": str(e)}

class CreateSSH(BaseModel):
    username: str
    password: str
    ip_limit: int
    expired_days: int

class RenewSSH(BaseModel):
    username: str
    days: int

class UsernameOnly(BaseModel):
    username: str

class TrialSSH(BaseModel):
    minutes: int

class SendWA(BaseModel):
    to: str
    message: str

class TrialXray(BaseModel):
    minutes: int = 60

class CreateXray(BaseModel):
    username: str
    quota_gb: int = 1
    ip_limit: int = 2
    expired_days: int = 30

class UsernameOnly(BaseModel):
    username: str

  
@app.post("/wa/send")
def send_wa(data: SendWA, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["send-wa-api", data.to, data.message])

@app.get("/")
def home():
    return {"status": "online", "service": "Zidan VPN API"}

@app.post("/ssh/create")
def create_ssh(data: CreateSSH, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "add-ssh-api",
        data.username,
        data.password,
        str(data.ip_limit),
        str(data.expired_days)
    ])

@app.post("/ssh/renew")
def renew_ssh(data: RenewSSH, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["renew-ssh-api", data.username, str(data.days)])

@app.post("/ssh/delete")
def delete_ssh(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["del-ssh-api", data.username])

@app.post("/ssh/unlock")
def unlock_ssh(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["unlock-ssh-api", data.username])

@app.post("/ssh/trial")
def trial_ssh(data: TrialSSH, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["trial-ssh-api", str(data.minutes)])

@app.get("/ssh/member")
def member_ssh(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["member-ssh-api"])

@app.get("/ssh/online")
def cek_ssh(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["cek-ssh-api"])

@app.delete("/ssh/expired")
def delete_expired(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["delexp-api"])

  @app.post("/xray/trial/vmess")
def trial_vmess(data: TrialXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["trial-vme-api", str(data.minutes)])

  @app.post("/xray/trial/vless")
def trial_vless(data: TrialXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["trial-vle-api", str(data.minutes)])

  @app.post("/xray/create/vmess")
def create_vmess(data: CreateXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "add-vme-api",
        data.username,
        str(data.quota_gb),
        str(data.ip_limit),
        str(data.expired_days)
    ])

@app.post("/xray/create/vless")
def create_vless(data: CreateXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "add-vle-api",
        data.username,
        str(data.quota_gb),
        str(data.ip_limit),
        str(data.expired_days)
    ])

@app.post("/xray/delete/vmess")
def delete_vmess(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["del-vme-api", data.username])

@app.post("/xray/delete/vless")
def delete_vless(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["del-vle-api", data.username])

@app.get("/xray/online")
def xray_online(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["cek-xray-api"])