#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <arg>" >&2
    exit 1
fi

# 本スクリプトファイルがあるディレクトリに
# input, output ディレクトリがあり、
# Amatsukaze コンテナの /app/input, /app/output にマウントされている前提
SCRIPT_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"

echo "[対象ファイル] $1"

filename="${1##*/}"
src_dir="$(cd -- "$(dirname -- "$1")" && pwd)"
input_dir="$(cd -- "${SCRIPT_DIR}/input" && pwd)"
output_dir="$(cd -- "${SCRIPT_DIR}/output" && pwd)"

candidate_name="$filename"
candidate_path="$1"
if [[ "$src_dir" == "$input_dir" ]]; then
    # すでに input にある → そのまま使う
    # 何もしない
    :
else
    # 外部 → input に移動 + 衝突回避
    base="${filename%.*}"
    ext="${filename##*.}"

    if [[ "$base" == "$filename" ]]; then
        ext=""
    else
        ext=".$ext"
    fi

    candidate_path="${input_dir}/${filename}"
    i=1

    while [[ -e "$candidate_path" ]]; do
        candidate_name="${base}_${i}${ext}"
        candidate_path="${input_dir}/${candidate_name}"
        ((i++))
    done

    mkdir -p "$input_dir"
    mv -- "$1" "$candidate_path"
fi

echo "[入力パス] ${candidate_path}"
echo "[出力パス] ${output_dir}"

container_input="/app/input/${candidate_name}"
container_output="/app/output"
AmatsukazeAddTask \
    -ip 127.0.0.1 \
    -s デフォルト \
    -o "$container_output" \
    -f "$container_input"

echo "タスクを追加しました。"
