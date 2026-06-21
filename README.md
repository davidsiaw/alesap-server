# alesap

## Dev Getting Started

First time?

Install Heighliner

```
# .zshrc
alias hl='docker run --rm -ti \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.heighliner:/root/.heighliner \
  -v `pwd`:`pwd` \
  -e _HEIGHLINER_USER_HOME=$HOME \
  -e _HEIGHLINER_POS=docker \
  -e CONTEXT_DIR="`pwd`" \
  davidsiaw/heighliner'
```

```bash
heighliner init alesap-server
```

Start attached

```bash
heighliner up -av
```

Start background

```bash
heighliner up
```

```bash
open http://alesap-server.lvh.me/api/v1/health
```

# Old docs

## Docker compose (old, no elasticsearch)

```
docker compose up --build
# http://localhost:3000
```

## How to edit database

Comes with PGAdmin at http://localhost:5050.

```
-user: admin@example.com
-pass: admin
```

