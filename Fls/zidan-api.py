from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
import subprocess
import json
import os

DEFAULT_TOKEN = "default"
TOKEN_FILE = "/etc/bot/.api_key"

def load_api_token():
    env_token = os.getenv("ZIDAN_API_TOKEN")
    if env_token:
        return env_token.strip()

    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE, "r") as f:
            token = f.read().strip()
            if token:
                return token

    return DEFAULT_TOKEN

API_TOKEN = load_api_token()

app = FastAPI(title="Zidan VPN API", version="2.1.0")


def check_token(x_api_key: str | None):
    if not API_TOKEN or API_TOKEN == DEFAULT_TOKEN:
        raise HTTPException(status_code=500, detail="API token belum disetting")

    if x_api_key != API_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")


def run_cmd(cmd, timeout=60):
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )

        output = result.stdout.strip() or result.stderr.strip()

        if result.returncode != 0:
            return {
                "status": "error",
                "code": result.returncode,
                "raw": output
            }

        try:
            return json.loads(output)
        except Exception:
            return {
                "status": "error",
                "message": "Command output bukan JSON",
                "raw": output
            }

    except subprocess.TimeoutExpired:
        return {
            "status": "error",
            "message": "Command timeout"
        }

    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }


class CreateSSH(BaseModel):
    username: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)
    ip_limit: int = 2
    expired_days: int = 30


class CreateXray(BaseModel):
    username: str = Field(..., min_length=1)
    quota_gb: int = 0
    ip_limit: int = 2
    expired_days: int = 30


class RenewSSH(BaseModel):
    username: str = Field(..., min_length=1)
    days: int = 30


class RenewXray(BaseModel):
    username: str = Field(..., min_length=1)
    days: int = 30
    quota_gb: int = 0
    ip_limit: int = 2


class UsernameOnly(BaseModel):
    username: str = Field(..., min_length=1)


class TrialAccount(BaseModel):
    minutes: int = 60


@app.get("/")
def home():
    return {
        "status": "online",
        "service": "Zidan VPN API",
        "version": "2.1.0"
    }


@app.get("/health")
def health():
    return {
        "status": "success",
        "message": "API healthy"
    }


@app.get("/server/info")
def server_info(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["server-info-api"])


@app.get("/server/status")
def server_status(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["server-status-api"])


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
    return run_cmd([
        "renew-ssh-api",
        data.username,
        str(data.days)
    ])


@app.post("/ssh/delete")
def delete_ssh(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "del-ssh-api",
        data.username
    ])


@app.post("/ssh/lock")
def lock_ssh(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "lock-ssh-api",
        data.username
    ])


@app.post("/ssh/unlock")
def unlock_ssh(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "unlock-ssh-api",
        data.username
    ])


@app.post("/ssh/trial")
def trial_ssh(data: TrialAccount, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "trial-ssh-api",
        str(data.minutes)
    ])


@app.get("/ssh/member")
def member_ssh(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["member-ssh-api"])


@app.get("/ssh/online")
def online_ssh(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["cek-ssh-api"])


@app.delete("/ssh/expired")
def delete_expired_ssh(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["delexp-api"])


@app.post("/vmess/create")
def create_vmess(data: CreateXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "add-vme-api",
        data.username,
        str(data.quota_gb),
        str(data.ip_limit),
        str(data.expired_days)
    ])


@app.post("/vmess/renew")
def renew_vmess(data: RenewXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "renew-vme-api",
        data.username,
        str(data.days),
        str(data.quota_gb),
        str(data.ip_limit)
    ])


@app.post("/vmess/delete")
def delete_vmess(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "del-vme-api",
        data.username
    ])


@app.post("/vmess/trial")
def trial_vmess(data: TrialAccount, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "trial-vme-api",
        str(data.minutes)
    ])


@app.post("/vless/create")
def create_vless(data: CreateXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "add-vle-api",
        data.username,
        str(data.quota_gb),
        str(data.ip_limit),
        str(data.expired_days)
    ])


@app.post("/vless/renew")
def renew_vless(data: RenewXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "renew-vle-api",
        data.username,
        str(data.days),
        str(data.quota_gb),
        str(data.ip_limit)
    ])


@app.post("/vless/delete")
def delete_vless(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "del-vle-api",
        data.username
    ])


@app.post("/vless/trial")
def trial_vless(data: TrialAccount, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "trial-vle-api",
        str(data.minutes)
    ])


@app.post("/trojan/create")
def create_trojan(data: CreateXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "add-tro-api",
        data.username,
        str(data.quota_gb),
        str(data.ip_limit),
        str(data.expired_days)
    ])


@app.post("/trojan/renew")
def renew_trojan(data: RenewXray, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "renew-tro-api",
        data.username,
        str(data.days),
        str(data.quota_gb),
        str(data.ip_limit)
    ])


@app.post("/trojan/delete")
def delete_trojan(data: UsernameOnly, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "del-tro-api",
        data.username
    ])


@app.post("/trojan/trial")
def trial_trojan(data: TrialAccount, x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd([
        "trial-tro-api",
        str(data.minutes)
    ])


@app.get("/xray/member")
def member_xray(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["member-xray-api"])


@app.get("/xray/online")
def online_xray(x_api_key: str | None = Header(default=None)):
    check_token(x_api_key)
    return run_cmd(["cek-xray-api"])

@app.get("/ssh/limit")
def ssh_limit(x_api_key: str = Header(None)):
    check_api_key(x_api_key)

    result = subprocess.run(
        ["/usr/local/sbin/ceklim-api"],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        return {
            "status": "error",
            "message": result.stderr or result.stdout or "failed to check ssh limit"
        }

    try:
        return json.loads(result.stdout)
    except Exception:
        return {
            "status": "error",
            "message": "invalid json response",
            "raw": result.stdout
        }