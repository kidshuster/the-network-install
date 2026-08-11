# The Network — install

Minimal files to run [The Network](https://github.com/kidshuster/the-network) Discord bot via Docker on any host (amd64 or arm64, including Raspberry Pi 4/5).

**Image:** `ghcr.io/kidshuster/the-network:1.2.15`

This repository is the install/runtime repo. Clone it alone — no application source required.

## Requirements

- Docker and Docker Compose plugin
- 64-bit Linux (Raspberry Pi OS 64-bit, or any amd64/arm64 host)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
# log out and back in
```

## Quick start

```bash
git clone git@github.com:kidshuster/the-network-install.git
cd the-network-install
cp .env.example .env
# Edit .env: DISCORD_TOKEN and GUILD_ID (required)
chmod +x scripts/*.sh
./scripts/enable.sh
./scripts/logs.sh
```

Verify in Discord: run `/status` in your central guild. Run `/server init` once on a new hub.

## Scripts

| Script | Purpose |
|--------|---------|
| `./scripts/start.sh` | Start container (compose, no systemd) |
| `./scripts/stop.sh` | Stop container |
| `./scripts/logs.sh` | Follow container logs |
| `./scripts/update.sh` | Pull latest image and recreate container |
| `./scripts/enable.sh` | Install systemd unit and start on boot |
| `./scripts/disable.sh` | Stop, disable systemd, remove unit file |

## Updates

```bash
git pull
./scripts/update.sh
```

With systemd:

```bash
git pull
sudo systemctl restart the-network-docker.service
```

## Data

SQLite persists in `./data/relay.db` (mounted into the container). Back up this directory before major updates.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `pull access denied` | `docker login ghcr.io` (PAT with `read:packages`) or make the GHCR package public |
| Bot offline after reboot | Run `./scripts/enable.sh` |
| Permission denied on Docker | Re-login after `usermod -aG docker`, or use `sudo` |

## Source

Bot source and development: https://github.com/kidshuster/the-network  
Releases are published from that repo with `./bin/publish.sh`.
