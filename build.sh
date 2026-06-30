#!/usr/bin/env bash
sudo $(which podman-compose) build --no-cache 2>&1 | tee build.log
