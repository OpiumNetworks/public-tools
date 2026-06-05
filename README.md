# Omnicore Networks - Public Tools

Scripts we use internally at Omnicore Networks. You're welcome to use them too.

Everything here is free to use, fork, and modify. Pull requests probably won't get merged unless you've talked to a maintainer first. Reach out to **alex** (GitHub: [@squishylemon](https://github.com/squishylemon)).

## Requirements

- Ubuntu Server (scripts are written for that)
- `sudo` or root access where noted
- A network connection for package downloads

## Scripts

### `scripts/docker/setup-ubuntu-server.sh`

Installs Docker Engine on Ubuntu Server from Docker's official apt repo.

**What it does, step by step:**

1. Checks you're on Ubuntu and running as root (or via `sudo`).
2. Removes old `docker.io` / `docker-engine` packages if they're installed.
3. Installs `curl`, `ca-certificates`, and `gnupg`.
4. Adds Docker's GPG key and apt source (skips if already there).
5. Installs `docker-ce`, the CLI, `containerd`, Buildx, and the Compose plugin.
6. Enables and starts the `docker` service.
7. Adds your sudo user to the `docker` group so you can run Docker without `sudo` (after re-login).
8. Runs `docker run hello-world` to confirm it works.

**Run it:**

```bash
curl -fsSL https://raw.githubusercontent.com/OpiumNetworks/public-tools/main/scripts/docker/setup-ubuntu-server.sh -o setup-docker.sh
chmod +x setup-docker.sh
sudo ./setup-docker.sh
```

Or clone the repo and run the script from your checkout:

```bash
git clone https://github.com/OpiumNetworks/public-tools.git
cd public-tools
sudo bash scripts/docker/setup-ubuntu-server.sh
```

**After install:** log out and back in (or reboot) if you were added to the `docker` group. Then try:

```bash
docker ps
docker compose version
```

Tested on Ubuntu 22.04 and 24.04 LTS.

## Contributing

Fork and change what you need for your own setup. If you want something merged upstream, open an issue or message alex ([@squishylemon](https://github.com/squishylemon)) before sending a PR.

## License

Use these scripts however you like. No warranty - test on your own systems first.
