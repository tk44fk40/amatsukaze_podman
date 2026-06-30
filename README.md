# Amatsukaze を Bazzite 44(rootless Podman) 環境で使う

[オリジナルの Amatsukaze](https://github.com/rigaya/Amatsukaze/blob/master/docker/readme.md)
では、Docker での利用方法が想定されています。

Podman で利用するために、`compose.yml`, `Dockerfile` を修正しています。

### defaults のファイル群について

オリジナルの Amatsukaze では、`../defaults` に、以下の様なディレクトリ群が
提供されています。
これらのディレクトリが作業ディレクトリに無い場合はコピーするようになってい
ますが、本プロジェクトでは同梱していません。
必要ならオリジナルの Amatsukaze のリポジトリから取得して配置してください。
- avsディレクトリ
- batディレクトリ
- profileディレクトリ
- drcsディレクトリ

### VCEEnc による AMD GPU/APU への対応は未実施

AMD GPU/APU で検証する環境が用意できないため、VCEEnc 関連の記述はコメント
アウトしてあります。
Ubuntu 22.04 の場合は、本家の Dockerfile を参考にコメントアウト部分を有効
にすればビルドできるだろうと思われます。
Ubuntu 24.04 の場合は、対応するバージョンに関して未調査のため、コメントアウト
した箇所は、そのままコピペして使うことはできません。

## セットアップ

1. 作業ディレクトリ（例：`~/amatsukaze_podman`）に、git clone します。

```bash
cd  # ホームディレクトリ直下に取得して作業ディレクトリにする
git clone --depth=1 https://github.com/tk44fk40/amatsukaze_podman
```

1. compose.yml, Dockerfile を生成する

```bash
cd ~/amatsukaze_podman
./setup_amatsukaze.sh
```

2. コンテナをビルドする

コンテナのビルドにはしばらく時間が必要です。
一息いれて気長に待ちます。

```bash
cd ~/amatsukaze_podman
sudo $(which podman-compose) build --no-cache
```

## 起動と終了

### 起動

```bash
sudo $(which podman-compose) up -d
```

### 終了

```bash
sudo $(which podman-compose) down
```


## WebUI

ブラウザで `http://<コンテナを実行中のPCのIPアドレス>:32769/` を開く。


## タスクの追加

```bash
#  (コンテナ外) ./input  -> (コンテナ内) /app/input
#  (コンテナ外) ./output -> (コンテナ内) /app/output
AmatsukazeAddTask -ip <コンテナを実行中のPCのIPアドレス> -s <プロファイル名> -o /app/output -f /app/input/<入力tsファイル名>
```

- `addtask.sh` <入力TSファイル名>
  - AmatsukazeAddTask で、"デフォルト" プロファイルへタスク追加します。
  - 入力ファイルは input ディレクトリに移動されます。
  - inpup ディレクトリに既に同名ファイルが存在する場合は、
    サフィックス "_1" 等を付け加えたファイル名で移動します。


## コンテナのストレージドライバの変更

Amatsukaze が利用するライブラリやツールのビルド環境、実行環境の互換性を考慮して、
当面は Ubuntu は 22.04 を使いますが、私の環境（Kernel 7.0 系の rootless 環境）の
Podman ストレージドライバ設定（btrfs 上で native overlayfs を使用）では、
メタデータ処理の不整合により `apt-get` の使用に不都合（署名エラー）が発生しました。

試行錯誤の結果、Podman コンテナのストレージドライバ設定を変更することで、
apt-get の署名エラーが解消されました。

**【重要】** : この手順で対策すると、既存のコンテナ及び名前付きボリュームが
**削除されます**！
必ず、事前にバックアップ等の必要な処置を講じてください。

### 対策手順


### 経緯のメモ

`memo.md` を参照してください。
