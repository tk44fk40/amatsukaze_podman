# Amatsukazeで、タスク実行時に Vulkan 参照エラー

ログに
`Failed to get device count from Vulkan interface.`
が出力される。

NVEncでの単純なエンコードなら問題ないが、
インタレ解除とかさせようとすると、エラーになる。

原因の推測：
- コンテナ内にVulkanローダー（libvulkan1）がインストールされていない
- CDI のパススルーにVulkanローダーは含まれない？

対策案：
- [Dockerfile] Runtime stageに `libvulkan1` を追加して再ビルド
- パススルーの設定を見直し？

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

# 参考ファイル

- compose.yml
- Dockerfile

# プロンプト作成

以上を踏まえて、対策を支援するためのプロンプトを作成してください。
プロンプトは日本語でコードブロックに表示してください。
