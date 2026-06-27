# Bazzite 44 (Podman) apt-get 署名エラー対応記録 (2026-06-27)

Bazzite 44(rootless Podman) 環境で、Ubuntu container 内の `apt-get update` が常に

```text
At least one invalid signature was encountered.
```

で失敗する問題が発生。

原因は Kernel 7.0 系と btrfs 上の native overlayfs の不整合。
ストレージドライバーを btrfs ネイティブに変更することで解決。

# 環境

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



## 1. 概要
Bazzite 44 (rootless Podman) 環境にて、Ubuntu コンテナ内の
`apt-get update` が署名エラーで成敗する問題が発生。
原因は Kernel 7.0 系と btrfs 上の native overlayfs の不整合。
ストレージドライバーを btrfs ネイティブに変更することで解決。

## 2. 環境
- Host OS         : Bazzite 44 (Kinoite) / SELinux: enabled
- Kernel          : 7.0.9-ogc3.2.fc44.x86_64
- Podman / Runtime: 5.8.2 / crun 1.28
- Storage Driver  : overlay on btrfs -> btrfs (対策後)

## 3. 症状・再現
Dockerfile ビルド時、または単体コンテナ実行時に下記エラーが発生。
$ podman run --rm ubuntu:22.04 bash -c 'apt-get update'
---
At least one invalid signature was encountered.
E: The repository 'http://archive.ubuntu.com/ubuntu jammy InRelease'
is not signed.
---

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

### [手順 1] ストレージドライバーの変更
`~/.config/containers/storage.conf` の driver を以下に修正。
---
[storage]
driver = "btrfs"
---

### [手順 2] ストレージの手動クリーンアップ
メタデータ崩れに伴うエラーや名前空間ロックを回避するため、
退避・再起動を行った上で `podman unshare` 内で連続実行する。

1. Quadlet 設定の退避
   $ mv ~/.config/containers/systemd/*.container \
        ~/.config/containers/systemd.disabled/
   $ mv ~/.config/containers/systemd/*.pod \
        ~/.config/containers/systemd.disabled/

2. ホストの再起動
   $ sudo reboot

3. 該当ストレージの強制アンマウントと削除
   $ podman unshare bash -c '
     for m in $(mount | grep "containers/storage" | awk "{print \$3}"); do
       umount -l "$m"
     done
     rm -rf ~/.local/share/containers/storage
   '

4. システムのリセット
   $ podman system reset -f
