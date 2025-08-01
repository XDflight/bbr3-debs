# Latest Linux kernels merged with Google BBR v3

**Choose Language:** &nbsp; [English](#) &nbsp; [中文](README_zh.md) &nbsp; [日本語](README_ja.md)

> **TL;DR:** BBR enables big throughput improvements on high-speed, long-haul links: BBR's throughput can be 2700x higher than today's best loss-based congestion control, CUBIC (CUBIC gets about 3.3 Mbps, while BBR gets over 9,100 Mbps); BBR also enables significant reductions in latency in last-mile networks that connect users to the internet: BBR can keep queuing delay 25x lower than CUBIC [(BBR v1 official blog in 2017)](https://cloud.google.com/blog/products/networking/tcp-bbr-congestion-control-comes-to-gcp-your-internet-just-got-faster). BBR v3, which has not yet been merged into the kernel, is an improved version of BBR v1.

### One-click install & update & repair
**Important notes:**
- You have to login your system as a privileged user (i.e., `sudo`-able) in order to run the following command.
- `dpkg` should be available on your system in order to install packages provided by this repo. `dpkg` comes with Debian/Ubuntu systems.
- If your system uses a bootloader other than GRUB, you have to manually update your bootloader to boot to the new kernel after the script finished.
- If able, please backup your data before proceeding. Although the script is designed to be robust and to not corrupt your system and data if anything went wrong, the developers of this repo hold no liability toward the users of this repo. 

To install the latest Linux kernel with Google BBR v3 integrated and enabled, simply run the following command:
```
curl -sL "https://raw.githubusercontent.com/XDflight/bbr3-debs/refs/heads/build/install_latest.sh" | sudo bash -s
```
Mainland China users may run the following command instead for faster download:
```
curl -sL "https://ghfast.top/https://raw.githubusercontent.com/XDflight/bbr3-debs/refs/heads/build/install_latest.sh" | sudo CDN_URL="https://ghfast.top/" bash -s
```
You are good to go if every step completed without error.
No post-installation configuration (except the mandatory reboot) is required.

To verify that everything is working properly after the reboot, just run the same command again.
You can expect to see `sysctl settings are correct.` in the script's output. 
The script will automatically help you repair your kernel and/or sysctl settings if any of the checks fails. 

The command can also be used to update the kernel.
It will check for kernel update every time it runs, and will update the kernel if a newer version is available.

**Currently supported CPU architectures:**
- `amd64` / `x86-64`
- `i386` / `i686` / `ia32` / `x86` / `x86-32`
- `arm64` / `aarch64`
- `armhf` / `armv7` / `arm` / `arm32` / `aarch32` (hard-float)
- `riscv64`

**Using the script in non-interactive flows:**
To prevent the script from prompting the user for reboot, one can supply `-y`(`--yes`) or `-n`(`--no`) as the first argument to the script to select whether or not the script should automatically reboot the system after installation, update, or repair. 

---

### What is BBR v3? Why does this repo exist?
You can find the research papers about BBR [here (2016)](https://research.google/pubs/bbr-congestion-based-congestion-control-2/) and [here (2017)](https://dl.acm.org/doi/10.1145/3009824). 
For simple explanation, [this article (2017)](https://cloud.google.com/blog/products/networking/tcp-bbr-congestion-control-comes-to-gcp-your-internet-just-got-faster) written by the development team of Google BBR is a good introduction.
Basically, BBR aims to improve network performance by considering both bandwidth and round-trip time (RTT) to optimize data transmission.
BBR v1 was already merged into the Linux kernel in `4.9`.
BBR v3 is an improved version of BBR v1, with the primary goal of addressing issues related to unfairness and high retransmission rates.
However, BBR v3 has not yet been merged into the kernel.
The current Linux kernel used in `google/bbr` is `6.13.7`. 
This repo intends to rebase all the commits made by the BBR development team onto the kernel source tree, so that people can use BBR v3 in newer Linux kernels (especially the latest stable & LTS versions).
For convenience, GitHub workflows have been setup to compile those "modded" kernels into `.deb` packages and release them on GitHub, so that Debian/Ubuntu users can install the kernels easily.

### Compilation highlights
- Four TCP congestion control algorithms are available: `bbr` (Google BBR3), `dctcp`, `cubic`, and `reno`. `bbr` is the default and is built-in, `dctcp` and `cubic` were compiled as modules, and `reno` is built-in because it is the "original" one that comes with the Linux kernel. In general, `bbr` is recommended for general purposes (especially high bandwidth and variable/high latency environments), while `dctcp` is recommended for low latency environments such as data centers; `cubic` and `reno` are included mainly for debugging and testing purposes (more information about them can be found online). Because `bbr` is the default algorithm, there is no need to set `net.ipv4.tcp_congestion_control = bbr` in `sysctl.d`.
- Two TCP active queue management algorithms are available: `fifo` and `fq_codel`. If you are not familiar with them, using the default one (`fq_codel`) will work in almost all scenarios. `fifo`, as its name suggests, is a very simple AQM algorithm that comes with the kernel originally, while `fq_codel` is configured as the default because it performs well with BBR, does not require careful parameter tuning, and is very robust in all network environments.
- Other configurations are basically inherited from the "currently latest" (likely not the case when you read this `README`) official Debian kernel `6.1.0-35-amd64` (which is based on Linux kernel `6.1.137`), with minors changes to adapt the configurations to newer kernels. The only two things worth highlighting are:
    1. Kernel debug information is omitted because it is too big to upload to and download from GitHub and generally not useful if one does not do kernel development. Don't worry, many distros also omit kernel debug info in their standard install and offer them as a standalone package. 
    1. Transparent Hugepage Support (THP) is disabled in the kernels by default since it is recommended by many database systems (and I think may people will install these kernels on servers). Anyway, you can always change the setting yourself at `/sys/kernel/mm/transparent_hugepage/`.

### Download
On the [GitHub Releases](https://github.com/XDflight/bbr3-debs/releases) page, you can find all the compiled kernels packaged into `.deb` files. 
Simply choose a version you'd like to use. 
Every release will come with a brief explanation of the kernel version to help you decide which version you'd like to use. 

Generally, look for any of the following versions:
- **For best compatibility & less headache:** Choose the latest kernel that has the same (or close to the) major version (first two numbers) as your current kernel. You can check the version of your kernel using `uname -a`.
- **For best stability & security:** Choose the latest LTS kernel.
- **For most features & best support for new hardware:** Choose the latest kernel.

In any case, please choose a kernel version that's higher/newer than your current kernel version, because many bootloaders (such as GRUB) will boot to the newest kernel by default. 

As for the architecture (`amd64`, `arm64`, ...), just choose the one used by your system.

Please download all three packages in the release, namely the following:
- `linux-headers-*`: The header files of the kernel. Useful for building external kernel modules.
- `linux-image-*`: The kernel binary - the most important one.
- `linux-libc-dev-*`: The standard C library `libc` and other user-space stuff critical for things to work.

### Installation
1. Run `sudo dpkg -i linux-*.deb` in your Linux terminal. Make sure you are in the directory where the downloaded files are located. 
1. Run `sudo update-grub` to update your GRUB bootloader. Note that this step may differ if you are using other bootloaders, like on Raspberry Pi or using uBoot. Check the instructions online for how to properly update your bootloader to boot to the new kernel.
1. You may want to check if the current `/etc/sysctl.conf` and `/etc/sysctl.d/*.conf` config files contain any `net.ipv4.tcp_congestion_control` or `net.core.default_qdisc` which can accidentally overwrite the default values set by the kernel. You can remove those quickly using the following commands:
    - `sudo sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf`
    - `sudo sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/*.conf`
    - `sudo sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf`
    - `sudo sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/*.conf`
1. You may want to enable TCP Fast Open (TFO) to further reduce RTT. TFO is proposed by a team from Google and described in RFC 7413. To do so, follow these steps:
    1. Run `sysctl net.ipv4.tcp_fastopen`. If the current value is `3`, no need to change.
    1. Otherwise, add `net.ipv4.tcp_fastopen = 3` to one of the `sysctl.d` files. Instructions to do so can be found online.
1. You may want to enable TCP ECN to further reduce packet loss. ECN allows routers to signal impending network congestion to endpoints without dropping packets. To do so, follow these steps:
    1. Run `sysctl net.ipv4.tcp_ecn`. If the current value is `1`, no need to change.
    1. Otherwise, add `net.ipv4.tcp_ecn = 1` to one of the `sysctl.d` files. Instructions to do so can be found online.
1. Reboot the system. To verify that the new kernel is working properly, please do the following checks:
    - Running `uname -r` should give you the new kernel version and the `-bbr3` version suffix. 
    - Running `sysctl net.ipv4.tcp_congestion_control` should give you `bbr`.
    - Running `sysctl net.core.default_qdisc` should give you `fq_codel`.
    - Running `sysctl net.ipv4.tcp_fastopen` should give you `3` (if configured).
    - Running `sysctl net.ipv4.tcp_ecn` should give you `1` (if configured).
1. Yay! Your system is now fully configured with BBR v3.
1. You may update the kernel using the same instructions above. 

---

### Release schedule
Compiled kernels will be released on a weekly basis, or whenever there is a new kernel version available.
Specifically, a GitHub workflow will be automatically triggered every *Monday at 07:21 UTC* to pull the source code of the latest stable kernel and compile it with BBR v3 integrated.
It will then upload the compiled `.deb` packages to the GitHub Releases page as a set of draft releases.
The draft releases will be published manually after their tags are assigned and their release notes are written.
If any abnormalities occur during the compilation, especially if the patch files fail to apply cleanly due to upstream conflicts, the workflow will fail and the patch files will later be reviewed and fixed.
This may take some time, so please be patient.
Updates from the BBR development team, particularly from the `google/bbr` repo, the BBR Development Google Group, and the RFC draft at `ietf-wg-ccwg/draft-ietf-ccwg-bbr`, will also be monitored closely, and changes will be made to the patch files to keep up with the latest developments on BBR.

### Contributing
If you have encountered any issues or are interested in contributing to this project, please feel free to open an issue or a pull request.
Any suggestions or improvements are welcome.
By the way, make sure to report any performance-related problems not only here but also to the BBR development team, so that they can investigate and fix the issues in the upstream code. Thanks!
