`Failed to get device count from Vulkan interface.`
が表示される。
NVEncでの単純なエンコードなら問題ないが、
インタレ解除とかさせようとすると、エラーになってしまう（要Vulkanらしい）。

原因：
  1. コンテナ内にVulkanローダー（libvulkan1）がインストールされていない。

対策案：
  1. [Dockerfile] Runtime stageに `libvulkan1` を追加して再ビルド。
