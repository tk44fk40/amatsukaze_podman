#!/usr/bin/env bash
sudo $(which podman-compose) down
sudo $(which podman-compose) build "$@" 2>&1 | tee build.log
sudo podman builder prune
