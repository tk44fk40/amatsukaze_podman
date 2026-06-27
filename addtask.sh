#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <arg>" >&2
    exit 1
fi

SCRIPT_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"

echo "[対象ファイル] $1"

filename="${1##*/}"
input_path="${SCRIPT_DIR}/input/${filename}"
output_path="${SCRIPT_DIR}/output"

mv "$1" "$input_path"
echo "対象ファイルを $input_path に移動しました。"

echo "[入力パス] $input_path"
echo "[出力パス] $output_path"

AmatsukazeAddTask -ip 127.0.0.1 -s default -o /app/output -f "/app/input/${filename}"

echo "タスクを追加しました。"
