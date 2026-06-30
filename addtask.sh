#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <arg>" >&2
    exit 1
fi

SCRIPT_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
input_dir="$(cd -- "${SCRIPT_DIR}/input" && pwd)"
output_dir="$(cd -- "${SCRIPT_DIR}/output" && pwd)"

# タスク登録処理を関数化
add_task_for_file() {
    local target_file="$1"

    echo "[対象ファイル] $target_file"

    local filename="${target_file##*/}"
    local src_dir="$(cd -- "$(dirname -- "$target_file")" && pwd)"

    local candidate_name="$filename"
    local candidate_path="$target_file"

    if [[ "$src_dir" == "$input_dir" ]]; then
        # すでに input にある → そのまま使う
        :
    else
        # 外部 → input に移動 + 衝突回避
        local base="${filename%.*}"
        local ext="${filename##*.}"

        if [[ "$base" == "$filename" ]]; then
            ext=""
        else
            ext=".$ext"
        fi

        candidate_path="${input_dir}/${filename}"
        local i=1

        while [[ -e "$candidate_path" ]]; do
            candidate_name="${base}_${i}${ext}"
            candidate_path="${input_dir}/${candidate_name}"
            ((i++))
        done

        mkdir -p "$input_dir"
        mv -- "$target_file" "$candidate_path"
    fi

    echo "[入力パス] ${candidate_path}"
    echo "[出力パス] ${output_dir}"

    local container_input="/app/input/${candidate_name}"
    local container_output="/app/output"

    AmatsukazeAddTask \
        -ip 127.0.0.1 \
        -s デフォルト \
        -o "$container_output" \
        -f "$container_input"

    echo "タスクを追加しました: $candidate_name"
    echo "----------------------------------------"
}

if [[ -f "$1" ]]; then
    # 通常ファイルの場合
    add_task_for_file "$1"

elif [[ -d "$1" ]]; then
    # フォルダの場合
    echo "[対象フォルダ] $1"

    # 対象フォルダ直下の .m2ts ファイルを検索
    shopt -s nullglob
    for f in "$1"/*.m2ts; do
        if [[ -f "$f" ]]; then
            add_task_for_file "$f"
        fi
    done
    shopt -u nullglob

else
    echo "error: 有効なファイルまたはフォルダを指定してください: $1" >&2
    exit 1
fi
