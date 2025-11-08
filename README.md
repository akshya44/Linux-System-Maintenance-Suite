# 🧰 Bash Maintenance Suite

A complete Bash scripting suite for automating Linux system maintenance tasks.  
It includes automated backups, software updates, log monitoring, and cleanup routines — all managed through a simple menu interface.

## ✨ Features
- 🗃️ **Automated Backups** — Compress and timestamp critical directories  
- 🔄 **System Updates & Cleanup** — Supports apt, dnf, and pacman  
- 📋 **Log Monitoring** — Alerts on keywords or errors in system logs  
- ⚙️ **Cron & Systemd Integration** — For scheduled background execution  
- 🖥️ **Interactive Menu** — One-click maintenance launcher  

## 🚀 Quick Start
```bash
git clone https://github.com/<your-username>/BashMaintenanceSuite.git
cd BashMaintenanceSuite
cp .env.example .env
chmod +x *.sh
./menu.sh

