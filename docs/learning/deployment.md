# Ubuntu and Docker deployment

This guide covers only the operations used by PBlue Lab. It assumes Docker Engine and the repository are already present on Ubuntu.

## Develop and build

Node and pnpm are needed for local development, but not for the production container runtime.

```bash
pnpm install
pnpm dev
pnpm generate
```

`pnpm generate` writes the static site to `apps/web/.output/public`. The Docker build performs these steps again inside a pinned builder image, so a deploy does not depend on host `node_modules`.

## Build the image

From the repository root:

```bash
docker build -t pblue-web .
```

Docker executes two stages. `builder` installs dependencies and runs Nuxt static generation. `runtime` starts from Nginx Alpine and copies only the generated output plus the Nginx configuration.

Inspect the local image:

```bash
docker image ls pblue-web
docker image inspect pblue-web
```

## Run the container

```bash
docker run --rm --name pblue-web \
  -p 127.0.0.1:8037:80 \
  pblue-web
```

The left side of `8037:80` is the Ubuntu host port. The right side is the Nginx port inside the container. Binding to `127.0.0.1` keeps the service off public network interfaces; Cloudflare Tunnel can reach the local address without exposing it directly.

In another terminal:

```bash
curl -I http://127.0.0.1:8037/
curl -I http://127.0.0.1:8037/blog
curl http://127.0.0.1:8037/healthz
```

## Observe and operate

```bash
docker ps --filter name=pblue-web
docker logs pblue-web
docker logs --follow pblue-web
docker port pblue-web
docker stop pblue-web
```

`docker ps` shows running containers; add `-a` to include stopped ones. `docker logs` reads the process standard output and error streams. `docker stop` sends a termination signal and waits before forcing exit.

The example uses `--rm`, so Docker removes the container after it stops. Without `--rm`, remove the stopped container explicitly:

```bash
docker rm pblue-web
```

Removing a container does not remove its image. Use `docker image rm pblue-web` only when the image is no longer needed.

## What stays outside the repository

Cloudflare Tunnel credentials, tokens, DNS changes, the host's actual checkout path, and service management belong to the server environment. Do not place credential JSON or tokens in `.env` files committed to Git.
