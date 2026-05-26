# Client SSH Config — Connect to Your Hardened Server

Add this to your **local machine's** `~/.ssh/config` to connect easily.

## ~/.ssh/config

```ssh-config
Host hardened-server
    HostName     YOUR_SERVER_IP
    Port         2222
    User         pentester
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    # Optional: Use 2FA (if module 10 was enabled)
    # PreferredAuthentications publickey,keyboard-interactive
```

## Connect

```bash
# With the config above — just use:
ssh hardened-server

# Without config — full command:
ssh -p 2222 -i ~/.ssh/id_ed25519 pentester@YOUR_SERVER_IP
```

## Copy Your SSH Key from the Server

After running module 02, copy the generated key to your local machine:

```bash
# From the SERVER — print the private key
sudo cat /home/pentester/.ssh/id_ed25519

# Save it locally on your machine
nano ~/.ssh/hardened_server_key
# Paste the key content, save

chmod 600 ~/.ssh/hardened_server_key

# Test connection
ssh -p 2222 -i ~/.ssh/hardened_server_key pentester@YOUR_SERVER_IP
```

## First Login Checklist

After hardening:

- [ ] Can connect via SSH key on port 2222
- [ ] Root login is refused
- [ ] Password login is refused
- [ ] Run `sudo ./status.sh` — all checks green
- [ ] Run `sudo ./tests/test-hardening.sh` — 25/25 pass
- [ ] Change temporary password: `passwd pentester`
