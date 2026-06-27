#!/bin/bash
set -e

echo "=== 0. 環境のクリーンアップを実行中 ==="
# 既存のファイル、ディレクトリを削除して空の環境を作る
dirs=(
  avs
  bat
  config
  data
  drcs
  JL
  logo
  profile
  input
  output
  temp
  compose.yml
  Dockerfile
)

for d in "${dirs[@]}"; do
  [ -e "$d" ] && rm -rf -- "$d"
done