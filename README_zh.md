# 最新 Linux 内核，集成 Google BBR v3

**选择语言：** [English](README.md) &nbsp; [中文](#) &nbsp; [日本語](README_ja.md)

> **一句话总结：** BBR 在高速、长距离网络中能带来巨大的吞吐量提升：BBR 的吞吐量比目前最好的基于丢包的拥塞控制算法 CUBIC 高 2700 倍（CUBIC 大约 3.3 Mbps，而 BBR 超过 9100 Mbps）；在连接用户到互联网的最后一公里网络中，BBR 还能显著降低延迟：BBR 可以将排队延迟保持在 CUBIC 的 1/25 [(BBR v1 官方博客，2017)](https://cloud.google.com/blog/products/networking/tcp-bbr-congestion-control-comes-to-gcp-your-internet-just-got-faster)。BBR v3 是 BBR v1 的改进版，但尚未合并到内核中。

### 一键安装 & 更新 & 修复
**重要提示：**
- 运行以下命令前，请确保你以有权限的用户登录系统（即可以使用 `sudo`）。
- 系统中需要安装 `dpkg`，它是 Debian/Ubuntu 系统自带的包管理工具。
- 如果你的系统使用的引导程序不是 GRUB，脚本运行完成后需要手动更新引导程序以加载新内核。
- 如果可以，请在操作前备份数据。虽然脚本设计得很稳健，出现问题时不会损坏系统和数据，但本仓库的开发者对使用脚本的用户不承担任何责任。

要安装集成并启用 Google BBR v3 的最新 Linux 内核，只需运行以下命令：
```
curl -sL "https://raw.githubusercontent.com/XDflight/bbr3-debs/refs/heads/build/install_latest.sh" | sudo bash -s
```
中国大陆用户可以运行以下命令以加快下载速度：
```
curl -sL "https://ghfast.top/https://raw.githubusercontent.com/XDflight/bbr3-debs/refs/heads/build/install_latest.sh" | sudo CDN_URL="https://ghfast.top/" bash -s
```
如果每一步都顺利完成，那就大功告成啦！
无需进行任何后续配置（除了必须的重启）。

要验证是否一切正常，只需再次运行上述命令。
你可以期待脚本输出中出现 `sysctl settings are correct.`。
如果任何检查失败，脚本会自动帮助你修复内核和/或 sysctl 设置。

上述命令也可用于更新内核。
每次运行时，它都会检查内核更新，并在有新版本时自动更新内核。

**当前支持的 CPU 架构：**
- `amd64` / `x86-64`
- `i386` / `i686` / `ia32` / `x86` / `x86-32`
- `arm64` / `aarch64`
- `armhf` / `armv7` / `arm` / `arm32` / `aarch32` (硬浮点)
- `riscv64`

**在非交互式流程中使用脚本：**
为了防止脚本提示用户重启，可以在脚本的第一个参数中提供 `-y`（`--yes`）或 `-n`（`--no`），以选择脚本是否在安装、更新或修复后自动重启系统。

---

### 什么是 BBR v3？为什么需要这个仓库？
你可以在 [这里（2016）](https://research.google/pubs/bbr-congestion-based-congestion-control-2/) 和 [这里（2017）](https://dl.acm.org/doi/10.1145/3009824) 找到关于 BBR 的研究论文。
简单来说，[这篇文章（2017）](https://cloud.google.com/blog/products/networking/tcp-bbr-congestion-control-comes-to-gcp-your-internet-just-got-faster) 是 Google BBR 开发团队写的一个很好的介绍。
基本上，BBR 通过同时考虑带宽和往返时间（RTT）来优化数据传输，从而提升网络性能。
BBR v1 已经在内核版本 `4.9` 中合并。
BBR v3 是 BBR v1 的改进版，主要目标是解决不公平性和高重传率问题。
然而，BBR v3 尚未合并到内核中。
`google/bbr` 当前使用的 Linux 内核版本是 `6.13.7`。
本仓库旨在将 BBR 开发团队的所有提交重新基于内核源码树，以便用户可以在更新的 Linux 内核（尤其是最新的稳定和 LTS 版本）中使用 BBR v3。
为了方便，GitHub 工作流已设置好，可以将这些“改版”内核编译成 `.deb` 包并发布到 GitHub，方便 Debian/Ubuntu 用户轻松安装内核。

### 编译亮点
- 提供四种 TCP 拥塞控制算法：`bbr`（Google BBR3）、`dctcp`、`cubic` 和 `reno`。`bbr` 是默认算法并内置，`dctcp` 和 `cubic` 编译为模块，`reno` 内置因为它是 Linux 内核自带的“原始”算法。一般来说，`bbr` 推荐用于通用场景（尤其是高带宽和可变/高延迟环境），而 `dctcp` 推荐用于低延迟环境（如数据中心）；`cubic` 和 `reno` 主要用于调试和测试（可以在线找到更多信息）。由于 `bbr` 是默认算法，无需在 `sysctl.d` 中设置 `net.ipv4.tcp_congestion_control = bbr`。
- 提供两种 TCP 主动队列管理算法：`fifo` 和 `fq_codel`。如果你不熟悉它们，使用默认的 `fq_codel` 几乎适用于所有场景。`fifo`，顾名思义，是一种非常简单的内核自带 AQM 算法，而 `fq_codel` 被配置为默认值，因为它与 BBR 配合良好，不需要仔细调整参数，并且在所有网络环境中都非常稳健。
- 其他配置基本继承自“当前最新”（可能不是你阅读此 `README` 时的情况）官方 Debian 内核 `6.1.0-35-amd64`（基于 Linux 内核 `6.1.137`），并对新内核进行了少量调整。值得注意的两点是：
    1. 内核调试信息被省略，因为它太大了，上传到 GitHub 和从 GitHub 下载都不方便，而且如果不进行内核开发一般没什么用。别担心，许多发行版也会在标准安装中省略内核调试信息，并将其作为独立包提供。
    2. 内核默认禁用透明大页支持（THP），因为许多数据库系统推荐禁用它（我认为许多人会在服务器上安装这些内核）。无论如何，你可以随时在 `/sys/kernel/mm/transparent_hugepage/` 中自行更改设置。

### 下载
在 [GitHub Releases](https://github.com/XDflight/bbr3-debs/releases) 页面，你可以找到所有编译好的内核 `.deb` 文件。
只需选择你想使用的版本。
每个发布版本都会附带内核版本的简要说明，帮助你决定选择哪个版本。

一般来说，可以选择以下版本：
- **为了最佳兼容性 & 最少麻烦：** 选择与你当前内核版本相同（或接近）的主版本号（前两个数字）的最新内核。你可以使用 `uname -a` 检查内核版本。
- **为了最佳稳定性 & 安全性：** 选择最新的 LTS 内核。
- **为了最多功能 & 最佳新硬件支持：** 选择最新的内核。

无论如何，请选择比当前内核版本更高/更新的内核版本，因为许多引导程序（如 GRUB）会默认加载最新的内核。

至于架构（`amd64`、`arm64` 等），只需选择与你系统使用的架构相同的版本。

请下载发布中的所有三个包，即以下内容：
- `linux-headers-*`：内核的头文件。这些文件在构建外部内核模块时会很有用。
- `linux-image-*`：内核二进制文件——最重要的部分。
- `linux-libc-dev-*`：标准 C 库 `libc` 和其他用户空间内容，确保系统正常运行。

### 安装
1. 在 Linux 终端中运行 `sudo dpkg -i linux-*.deb`。确保你位于下载文件所在的目录。
1. 运行 `sudo update-grub` 更新 GRUB 引导程序。注意，如果你使用其他引导程序（如 Raspberry Pi 或 uBoot），此步骤可能会有所不同。请在线查看如何正确更新引导程序以加载新内核。
1. 你可能需要检查当前 `/etc/sysctl.conf` 和 `/etc/sysctl.d/*.conf` 配置文件中是否包含任何 `net.ipv4.tcp_congestion_control` 或 `net.core.default_qdisc`，这些配置可能会意外覆盖内核设置的默认值。可以使用以下命令快速删除：
    - `sudo sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf`
    - `sudo sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/*.conf`
    - `sudo sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf`
    - `sudo sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/*.conf`
1. 你可能需要启用 TCP 快速打开（TFO）以进一步减少 RTT。TFO 由 Google 团队提出，并在 RFC 7413 中描述。启用方法如下：
    1. 运行 `sysctl net.ipv4.tcp_fastopen`。如果当前值为 `3`，无需更改。
    1. 否则，将 `net.ipv4.tcp_fastopen = 3` 添加到一个 `sysctl.d` 文件中。在线可以找到相关说明。
1. 你可能需要启用 TCP ECN 以进一步减少丢包。ECN 允许路由器在不丢弃数据包的情况下向端点发出网络拥塞的信号。启用方法如下：
    1. 运行 `sysctl net.ipv4.tcp_ecn`。如果当前值为 `1`，无需更改。
    1. 否则，将 `net.ipv4.tcp_ecn = 1` 添加到一个 `sysctl.d` 文件中。在线可以找到相关说明。
1. 重启系统。要验证新内核是否正常工作，请进行以下检查：
    - 运行 `uname -r` 应显示新内核版本和 `-bbr3` 版本后缀。
    - 运行 `sysctl net.ipv4.tcp_congestion_control` 应显示 `bbr`。
    - 运行 `sysctl net.core.default_qdisc` 应显示 `fq_codel`。
    - 运行 `sysctl net.ipv4.tcp_fastopen` 应显示 `3`（如果已配置）。
    - 运行 `sysctl net.ipv4.tcp_ecn` 应显示 `1`（如果已配置）。
1. 恭喜！你的系统现在已经完全配置为使用 BBR v3。
1. 你可以按照上述相同的说明更新内核。

---

### 发布计划
编译好的内核会以每周为周期发布，或者在有新内核版本时发布。
具体来说，GitHub 工作流会在每周一 07:21 UTC 自动触发，拉取最新稳定内核的源码，并集成 BBR v3 进行编译。
编译完成后，`.deb` 包会作为草稿发布到 GitHub Releases 页面。
草稿发布会在分配标签和撰写发布说明后手动发布。
如果编译过程中出现异常，尤其是补丁文件因上游冲突无法干净应用，工作流会失败，补丁文件会随后进行审查和修复。
这可能需要一些时间，请耐心等待。
同时会密切关注 BBR 开发团队的更新，特别是 `google/bbr` 仓库、BBR 开发 Google 组以及 `ietf-wg-ccwg/draft-ietf-ccwg-bbr` 的 RFC 草案，并对补丁文件进行修改以跟上 BBR 的最新进展。

### 贡献
如果你遇到任何问题或有兴趣为本项目贡献，请随时打开 issue 或 pull request。
任何建议或改进都欢迎。
顺便提一句，请确保不仅在这里报告任何性能相关问题，还要向 BBR 开发团队报告，以便他们调查并修复上游代码中的问题。谢谢！
