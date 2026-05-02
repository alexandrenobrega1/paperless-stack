# Paperless Stack

## Stack
| Container | Image | Port | Purpose |
|---|---|---|---|
| tailscale | tailscale/tailscale | — | Secure access via Tailscale |
| postgresql | postgres:16-alpine | — | Paperless database |
| redis | redis:7-alpine | — | Paperless broker |
| paperless-ngx | ghcr.io/paperless-ngx/paperless-ngx | 8010 | Document management |
| paperless-gpt | icereed/paperless-gpt | 8011 | AI tagging via Claude Haiku |

## Access
- **LAN:** `http://srv-ip:8010`
- **Tailscale/Remote:** `https://paperless.your-ts-domain.ts.net`

## Folder Structure
```
/data/paperless/
├── documents/    # processed document storage
├── consume/      # drop folder for auto-ingestion
├── export/       # export folder
└── media/        # media files

/container-data/
├── paperless-ngx/   # app config and index
├── paperless-gpt/   # custom AI prompts
├── postgresql/      # database files
├── redis/           # redis data
└── tailscale/       # tailscale state + config
```

## First-time Setup

### 1. Create folder scaffold
```bash
sudo mkdir -p \
  /data/paperless/documents \
  /data/paperless/consume \
  /data/paperless/export \
  /data/paperless/media \
  /container-data/paperless-ngx \
  /container-data/paperless-gpt \
  /container-data/redis \
  /container-data/postgresql \
  /container-data/tailscale/config

sudo chown -R docker:docker \
  /data/paperless \
  /container-data/paperless-ngx \
  /container-data/paperless-gpt \
  /container-data/redis \
  /container-data/postgresql \
  /container-data/tailscale
```

### 2. Copy Tailscale serve config
```bash
sudo cp tailscale/ts-serve.json /container-data/tailscale/config/ts-serve.json
```

### 3. Enable kernel module for Tailscale
```bash
sudo modprobe tun
echo "tun" | sudo tee /etc/modules-d/tailscale.conf
```

### 4. Fill in .env
```bash
cp .env.example .env
nano .env
# Generate secret key with: openssl rand -hex 32
```

### 5. Start the stack
```bash
docker compose up -d
```

### 6. Create Paperless admin user
```bash
docker exec -it paperless-ngx python3 manage.py createsuperuser
```

### 7. Get Paperless API token
- Log into Paperless UI → Profile → API Token
- Add to .env as PAPERLESS_API_TOKEN
- Restart paperless-gpt: `docker compose restart paperless-gpt`

### 8. Install rsync backup timer
```bash
sudo cp systemd/rsync-paperless.service /etc/systemd/system/
sudo cp systemd/rsync-paperless.timer /etc/systemd/system/
sudo sed -i 's/QNAP_IP/your.qnap.ip/' /etc/systemd/system/rsync-paperless.service
sudo touch /var/log/rsync-paperless.log
sudo chown docker:docker /var/log/rsync-paperless.log
sudo systemctl daemon-reload
sudo systemctl enable --now rsync-paperless.timer
```

## Paperless-GPT Usage
- Tag any document with `paperless-gpt` for manual AI processing
- Tag with `paperless-gpt-auto` for automatic processing
- Access GPT UI at `http://srv-ip:8011`

## Notes
- `PAPERLESS_API_TOKEN` must be filled in after first login
- `.env` is gitignored — never commit real credentials
- Tailscale provides HTTPS automatically via ts.net certificates
