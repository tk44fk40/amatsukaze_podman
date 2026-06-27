# Amatsukaze を Podman コンテナで使う

[オリジナルの Amatsukaze](https://github.com/rigaya/Amatsukaze/blob/master/docker/readme.md)
では、Docker での利用方法が想定されています。

Podman で利用するために、セットアップスクリプト（で作成される `compose.yml`,
`Dockerfile`）を修正しています。


# WebUI

ブラウザで `http://<コンテナを実行中のPCのIPアドレス>:32769/` を開く。


# タスクの追加

```bash
#  (コンテナ外) ./input  -> (コンテナ内) /app/input
#  (コンテナ外) ./output -> (コンテナ内) /app/output
AmatsukazeAddTask -ip <コンテナを実行中のPCのIPアドレス> -s <プロファイル名> -o /app/output -f /app/input/<入力tsファイル名>
```


# コンテナのストレージドライバの変更

Amatsukaze が利用するライブラリやツールのビルド環境、実行環境の互換性を考慮して、
Ubuntu は（本家の記述通り） 22.04 を使いますが、私の環境
（Kernel 7.0 系の rootless 環境）の Podman ストレージドライバ設定
（btrfs 上で native overlayfs を使用） では、メタデータ処理の不整合により
`apt-get` の使用に不都合（署名エラー）が発生しました。

試行錯誤の結果、以下の通りストレージドライバ設定を変更することで、
apt-get の署名エラーが解消されました。

対処方法として妥当なのか少々不安ですが、現状は問題なく利用できています。

**【重要】** : この手順で対策すると、既存のコンテナ及び名前付きボリュームが
**削除されます**！
必ず、事前にバックアップ等の必要な処置を講じてください。

## 対策手順

### [手順 1] ストレージドライバーの変更

`~/.config/containers/storage.conf` の driver を以下の通り修正する。

```ini
[storage]
driver = "btrfs"
```

### [手順 2] ストレージの手動クリーンアップ

メタデータ崩れに伴うエラーや名前空間ロックを回避するため、
退避・再起動を行った上で `podman unshare` 内で連続実行する。

1. Quadlet 設定の退避

    ```bash
    mv ~/.config/containers/systemd/*.container \
        ~/.config/containers/systemd.disabled/
    mv ~/.config/containers/systemd/*.pod \
        ~/.config/containers/systemd.disabled/
    ```

2. ホストの再起動

    ```bash
    sudo reboot
    ```

3. 該当ストレージの強制アンマウントと削除

    ```bash
    podman unshare bash -c '
    for m in $(mount | grep "containers/storage" | awk "{print \$3}"); do
        umount -l "$m"
    done
    rm -rf ~/.local/share/containers/storage
    '
    ```

4. システムのリセット

    ```bash
    podman system reset -f
    ```


## 経緯のメモ

`memo.md` を参照してください。
