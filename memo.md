# Bazzite 44 (Podman) apt-get 署名エラー対応記録 (2026-06-27)

Bazzite 44(rootless Podman) 環境で、Ubuntu 22.04 container 内
の `apt-get update` が常に

```
At least one invalid signature was encountered.
```

で失敗する問題が発生。

## 1. 概要

Bazzite 44 (rootless Podman) 環境にて、Ubuntu コンテナ内の
`apt-get update` が署名エラーで成敗する問題が発生。
原因は Kernel 7.0 系と btrfs 上の native overlayfs の不整合
が原因と思われるため、ストレージドライバーを btrfs ネイティブ
に変更することで対処する。

## 2. 環境

| 項目 | 内容 |
|---|---|
| Host OS | Bazzite 44 (Kinoite) |
| Kernel | `7.0.9-ogc3.2.fc44.x86_64` |
| Podman | `5.8.2` |
| Buildah | `1.43.1` |
| OCI Runtime | `crun 1.28` |
| Container mode | rootless |
| Storage | overlay on btrfs |
| Network backend | netavark + pasta |
| SELinux | enabled |

## 3. 症状・再現

Dockerfile ビルド時、または単体コンテナ実行時に下記エラーが発生。

```bash
podman run --rm ubuntu:22.04 bash -c 'apt-get update'
At least one invalid signature was encountered.
E: The repository 'http://archive.ubuntu.com/ubuntu jammy InRelease'
is not signed.
```

## 4. 切り分け履歴（検証により除外された要因）

- ビルドキャッシュ・イメージ破損 (system reset / 再 pull 後も再現)
- ホスト時刻の不整合 (timedatectl にて同期確認済み)
- ネットワーク/IPv6 (ForceIPv4, --network host でも再現)
- セキュリティ制限 (--security-opt seccomp=unconfined でも再現)

## 5. 原因

Kernel 7.0 系の rootless 環境において、btrfs 上で native overlayfs
を使用すると、メタデータ処理の不整合により特定ファイル（GPG 署名や
ライブラリ等）の正常な読み込みに失敗するため。

## 6. 対策手順

**【注意】** : この手順は、OS（Bazzite）デフォルトのストレージ
ドライバー（通常は overlay または適切に設定された btrfs）を
置き換える。
既存の（デフォルトのストレージドライバー）からの変更による
副作用は**未検証**であることに注意。
可能ならば、デフォルトのストレージドライバーのまま、別の手段
で署名エラーに対処することが望ましいと思われる。

#### [手順 1] 影響がある設定、コンテナをバックアップ

**【注意】** : 後続の手順で、全てのコンテナやボリューム等が削除される！
保存したいコンテナは、事前に podman export でバックアップすること。

1. Quadlet 設定の退避

systemd で管理しているコンテナが起動しないように
一時的に退避する。

  ```bash
  mv ~/.config/containers/systemd/*.container \
     ~/.config/containers/systemd.disabled/
  mv ~/.config/containers/systemd/*.pod \
     ~/.config/containers/systemd.disabled/
  ```
  
2. コンテナのバックアップ

重要な、再構築が困難なコンテナをバックアップする。

  ```bash
  podman export <コンテナ名> > ~/<コンテナ名>_backup.tar
  ```

3. 再起動

  ```bash
  # 再起動
  systemctl reboot
  ```

#### [手順 2] ストレージドライバーの変更


`~/.config/containers/storage.conf` の driver を以下に修正。

  ```ini
  [storage]
  driver = "btrfs"
  ```

#### [手順 3] ストレージの手動クリーンアップ


メタデータ崩れに伴うエラーや名前空間ロックを回避するため、
Podman のストレージを全て削除する。

   
1. Btrfs専用のサブボリューム削除（ゴーストデータ削除）

  ```bash
  # btrfs コマンドでサブボリューム（ゴーストデータ）を削除
  subvolumes=~/.local/share/containers/storage/btrfs/subvolumes
  sudo btrfs subvolume list -o ${subvolumes} | \
  awk -F/ '{print $NF}' | \
  while read -r subvol_id; do \
    sudo btrfs subvolume delete "${subvolumes}/${subvol_id}"; \
  done
  ```

2. 該当ストレージの強制アンマウントと削除

  ```bash
  # マウントされているボリュームをアンマウント
  systemctl --user stop podman.socket podman.service
  podman system migrate
  for m in $(mount | grep "~/.local/share/containers/storage" | awk '{print $3}'); do
      sudo umount -l "$m"
  done

  # ストレージを全て削除
  rm -rf ~/.local/share/containers/storage
  ```

3. システムのリセット

**【注意】** : 全てのコンテナやボリューム等が削除される！
保存したいコンテナは、事前に podman export でバックアップすること。

  ```bash
  # 【注意】全てのコンテナやボリュームが削除されます！
  podman system reset -f
  ```

#### [手順 4] Podman の初期化と再起動

Podman を初期化し、新しいディレクトリ構造を生成させる。 

  ```bash
  podman system df
  ```
  
#### [手順 5] バックアップしてあった設定、コンテナをリストア

1. Quadlet 設定のリストア

  ```bash
  mv ~/.config/containers/systemd.disabled/*.container \
     ~/.config/containers/systemd/
  mv ~/.config/containers/systemd.disabled/*.pod \
     ~/.config/containers/systemd/
  ```

※サービス起動時に必要なコンテナイメージが自動的に pull されるが、
サイズが大きいイメージは予め podman image pull しておくと起動が
スムーズに行われる。
  
2. コンテナのリストア

Podman でコンテナイメージをリストアする。

  ```bash
  podman import ~/<コンテナ名>_backup.tar <イメージ名>:latest
  ```

※イメージ名は任意です。コンテナ名と同じでもよい。


Distrobox コンテナの場合は、イメージから create する。

  ```bash
  distrobox create --image <イメージ名> --name <コンテナ名>
  ```

3. 再起動

  ```bash
  # 再起動
  $ systemctl reboot
  ```
