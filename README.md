# Basis Server + WebSocket transport (Docker)

A Docker build that fetches its source code itself. You do not need to clone Basis or install basispm on the host.

## What the image build does

1. Clones [BasisVR/Basis](https://github.com/BasisVR/Basis) at BASIS_REF.
2. Clones [BasisPackageManager](https://github.com/BasisVR/BasisPackageManager) and builds its basispm CLI.
3. Runs basispm server-install for [Basis-TCP-Transport-Package](https://github.com/dooly123/Basis-TCP-Transport-Package).
4. Restores and publishes the standalone Basis server.
5. Copies only the published server into the runtime image.

The default Basis ref is developer. Override it with a known branch, tag, or commit if needed. The transport repository must be compatible with the selected Basis revision.

## Build

~~~sh
docker build -t basis-tcp-server:local .
~~~

To select a different Basis revision:

~~~sh
docker build --build-arg BASIS_REF=developer -t basis-tcp-server:local .
~~~

## Run

~~~sh
mkdir -p config initialresources storage logs
docker run -d --name basis-server --restart unless-stopped \
  -e Password='replace-with-a-long-random-password' \
  -e NetworkStackId='litenetlib,websocket' \
  -p 4296:4296/udp -p 4296:4296/tcp \
  -p 10666:10666/tcp -p 1234:1234/tcp \
  -v "$PWD/config:/app/config" \
  -v "$PWD/initialresources:/app/initialresources:ro" \
  -v "$PWD/storage:/app/storage" -v "$PWD/logs:/app/logs" \
  basis-tcp-server:local
~~~

## Docker Compose / Coolify

Copy .env.example to .env and set a strong BASIS_PASSWORD, then run:

~~~sh
mkdir -p config initialresources storage logs
docker compose up -d --build
~~~

For Coolify, use this repository as a Docker Compose application. Ensure UDP port 4296 is reachable for LiteNetLib; WebSocket clients use TCP 4296. For TLS/WSS, put a TLS-capable reverse proxy in front of the WebSocket listener and configure the public URL accordingly.

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| 4296 | UDP | LiteNetLib |
| 4296 | TCP | WebSocket transport |
| 10666 | TCP | Health endpoint |
| 1234 | TCP | Statistics / metrics |

## Notes

- The Dockerfile clones sources and installs the transport during docker build; no source checkout is required on the host.
- The first build requires internet access to GitHub and NuGet.
- For reproducible production builds, pin BASIS_REF, BASISPM_REPOSITORY, and TCP_TRANSPORT_REPOSITORY to known tags or commit SHAs.
- A successful container build has not yet been verified. If upstream CLI commands or the transport package interface change, the build may need adjustment.
