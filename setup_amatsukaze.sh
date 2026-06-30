#!/bin/bash
set -e

# compose.yml セットアップ関数
setup_compose_file() {
    echo ""
    echo "--- compose.yml ファイルの準備 ---"

    # compose.ymlファイルの存在確認
    if [[ ! -f "compose.yml" && ! -f "docker-compose.yml" ]]; then
        if [[ -f "compose.sample.yml" ]]; then
            echo "⚠️  compose.yml ファイルが見つかりません。compose.sample.yml をコピーします..."
            cp compose.sample.yml compose.yml
            echo "✅ compose.yml ファイルを作成しました"
        else
            echo "❌ compose.yml ファイルまたは compose.sample.yml が見つかりません"
            exit 1
        fi
    else
        echo "ℹ️  compose.yml ファイルは既に存在します"
    fi
}

# Dockerfile セットアップ関数
setup_dockerfile() {
    echo ""
    echo "--- Dockerfile の準備 ---"

    # Dockerfile の存在確認
    if [[ ! -f "Dockerfile" ]]; then
        if [[ -f "Dockerfile.sample" ]]; then
            echo "⚠️  Dockerfile が見つかりません。Dockerfile.sample をコピーします..."
            cp Dockerfile.sample Dockerfile
            echo "✅ Dockerfile を作成しました"
        else
            echo "❌ Dockerfile または Dockerfile.sampleが見つかりません"
            exit 1
        fi
    else
        echo "ℹ️  Dockerfile は既に存在します"
    fi
}

# ディレクトリセットアップ関数
setup_directories() {
    echo "=== Amatsukaze Podman Compose セットアップ ==="
    echo ""

    # setup_amatsukaze.sh のディレクトリを取得
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DEFAULTS_DIR="$SCRIPT_DIR/../defaults"
    CURRENT_DIR="$(pwd)"

    # ディレクトリのコピー
    echo "--- ディレクトリのコピー ---"

    # avsディレクトリのコピー
    if [[ ! -d "$CURRENT_DIR/avs" ]]; then
        if [[ -d "$DEFAULTS_DIR/avs" ]]; then
            cp -r "$DEFAULTS_DIR/avs" "$CURRENT_DIR/"
            echo "✅ avsディレクトリをコピーしました"
        else
            echo "⚠️  $DEFAULTS_DIR/avs が見つかりません"
        fi
    else
        echo "ℹ️  avsディレクトリは既に存在します"
    fi

    # batディレクトリのコピー（bat_linuxから）
    if [[ ! -d "$CURRENT_DIR/bat" ]]; then
        if [[ -d "$DEFAULTS_DIR/bat_linux" ]]; then
            cp -r "$DEFAULTS_DIR/bat_linux" "$CURRENT_DIR/bat"
            echo "✅ batディレクトリをコピーしました"
        else
            echo "⚠️  $DEFAULTS_DIR/bat_linux が見つかりません"
        fi
    else
        echo "ℹ️  batディレクトリは既に存在します"
    fi

    # profileディレクトリのコピー
    if [[ ! -d "$CURRENT_DIR/profile" ]]; then
        if [[ -d "$DEFAULTS_DIR/profile" ]]; then
            cp -r "$DEFAULTS_DIR/profile" "$CURRENT_DIR/"
            echo "✅ profileディレクトリをコピーしました"
        else
            echo "⚠️  $DEFAULTS_DIR/profile が見つかりません"
        fi
    else
        echo "ℹ️  profileディレクトリは既に存在します"
    fi

    # drcsディレクトリのコピー
    if [[ ! -d "$CURRENT_DIR/drcs" ]]; then
        if [[ -d "$DEFAULTS_DIR/drcs" ]]; then
            cp -r "$DEFAULTS_DIR/drcs" "$CURRENT_DIR/"
            echo "✅ drcsディレクトリをコピーしました"
        else
            echo "⚠️  $DEFAULTS_DIR/drcs が見つかりません"
        fi
    else
        if [[ ! -f "$CURRENT_DIR/drcs/drcs_map.txt" ]]; then
            cp "$DEFAULTS_DIR/drcs/drcs_map.txt" "$CURRENT_DIR/drcs/drcs_map.txt"
            echo "✅ drcs_map.txtをコピーしました"
        else
            echo "ℹ️  drcsディレクトリは既に存在します"
        fi
    fi

    # JLディレクトリのコピー
    if [[ ! -d "$CURRENT_DIR/JL" ]]; then
        echo "JLディレクトリをダウンロード中..."
        (wget -q https://github.com/tobitti0/join_logo_scp/archive/refs/tags/Ver4.1.0_Linux.tar.gz -O JL.tar.gz \
            && tar -xf JL.tar.gz \
            && mv join_logo_scp-Ver4.1.0_Linux/JL "$CURRENT_DIR/" \
            && rm -rf join_logo_scp-Ver4.1.0_Linux/ join_logo_scp-Ver4.1.0_Linux JL.tar.gz \
            && echo "✅ JLディレクトリを作成しました" \
        )
    else
        echo "ℹ️  JLディレクトリは既に存在します"
    fi

    # 必要なディレクトリの作成
    echo ""
    echo "--- ディレクトリの作成 ---"

    local dirs=("config" "data" "input" "logo" "output" "temp")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$CURRENT_DIR/$dir" ]]; then
            mkdir -p "$CURRENT_DIR/$dir"
            echo "✅ $dirディレクトリを作成しました"
        else
            echo "ℹ️  $dirディレクトリは既に存在します"
        fi
    done

    # compose.yml 準備
    setup_compose_file

    # Dockerfile 準備
    setup_dockerfile

    echo ""
    echo "================================"
    echo "✅ セットアップが完了しました！"
    echo ""
    echo "=== コマンド例 ==="
    echo ""
    echo "コンテナのビルド:"
    echo "  sudo $(which podman-compose) build --no-cache"
    echo "コンテナの起動:"
    echo "  sudo $(which podman-compose) up -d"
    echo "コンテナの停止:"
    echo "  sudo $(which podman-compose) down"
    echo "コンテナの再起動:"
    echo "  sudo $(which podman-compose) restart"
    echo "ログ表示:"
    echo "  sudo $(which podman-compose) logs -f"
    echo "シェル実行:"
    echo "  sudo $(which podman-compose) exec -it amatsukaze bash"
    echo ""
    echo "=== アクセス情報 ==="
    echo "Amatsukaze WebUI : http://localhost:32769"
    echo "Amatsukaze Server (API): http://localhost:32768"
    echo "================================"
}

# セットアップの実行
setup_directories
