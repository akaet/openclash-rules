#!/bin/sh

# =====================================================
# MosDNS + OpenClash 安装脚本
# 两个组件完全独立，仅共享 gh_proxy 参数
#
# 用法：
#   sh install.sh
#   sh install.sh gh_proxy=https://gh-proxy.org/
# =====================================================

# 解析 gh_proxy（两个模块各自独立使用，互不依赖）
gh_proxy=""
for arg in "$@"; do
    case "$arg" in
        gh_proxy=*)
            gh_proxy="${arg#gh_proxy=}"
            [ -n "$gh_proxy" ] && case "$gh_proxy" in
                */) : ;;
                *) gh_proxy="$gh_proxy/" ;;
            esac
            ;;
    esac
done

# ---------- 系统依赖（通用工具、LuCI 中文包等）----------
apk update && apk add \
    zoneinfo-asia parted \
    luci-i18n-base-zh-cn \
    luci-i18n-attendedsysupgrade-zh-cn \
    luci-i18n-package-manager-zh-cn \
    luci-i18n-firewall-zh-cn

# ========================================
# MosDNS 安装
# 来源：https://github.com/sbwml/luci-app-mosdns
# ========================================
echo "[MosDNS]"

MOS_SCRIPT="https://raw.githubusercontent.com/sbwml/luci-app-mosdns/v5/install.sh"

if [ -n "$gh_proxy" ]; then
    sh -c "$(curl -ksS "$MOS_SCRIPT")" _ gh_proxy="$gh_proxy"
else
    sh -c "$(curl -ksS "$MOS_SCRIPT")"
fi

echo "[MosDNS] Done"

# ========================================
# OpenClash 安装
#   - https://raw.githubusercontent.com/sbwml/luci-app-mosdns/v5/install.sh
#     ↑ 参考此脚本的整体结构和写法（OpenWrt 安装脚本模版）
#   - https://github.com/vernesong/OpenClash/releases/latest
#     ↑ 获取最新版官方安装命令（真实的 OpenClash 安装逻辑来源）
# ========================================
echo "[OpenClash]"

# OpenClash 代理前缀（独立定义，不依赖外部函数）
_oc_proxy() {
    [ -n "$gh_proxy" ] && echo "${gh_proxy}$1" || echo "$1"
}

# 检测包管理器
if [ -x "/usr/bin/apk" ]; then
    PKG_MANAGER="apk"
    PKG_EXT="apk"
elif command -v opkg >/dev/null 2>&1; then
    PKG_MANAGER="opkg"
    PKG_EXT="ipk"
else
    echo "OpenClash: no supported package manager"
    exit 1
fi

# 检测防火墙后端
if [ -x "/usr/sbin/nft" ]; then
    firewall="nftables"
else
    firewall="iptables"
fi

echo "OpenClash: ${PKG_MANAGER} + ${firewall}"

# 安装依赖
case "$PKG_MANAGER" in
    apk)
        apk update || exit 1
        case "$firewall" in
            iptables)
                apk add bash iptables dnsmasq-full curl ca-bundle ipset ip-full \
                    iptables-mod-tproxy iptables-mod-extra ruby ruby-yaml \
                    kmod-tun kmod-inet-diag unzip luci-compat luci luci-base
                ;;
            nftables)
                apk add bash dnsmasq-full curl ca-bundle ip-full \
                    ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy \
                    luci-compat luci luci-base
                ;;
        esac
        ;;
    opkg)
        opkg update || exit 1
        case "$firewall" in
            iptables)
                opkg install bash iptables dnsmasq-full curl ca-bundle ipset ip-full \
                    iptables-mod-tproxy iptables-mod-extra ruby ruby-yaml \
                    kmod-tun kmod-inet-diag unzip luci-compat luci luci-base
                ;;
            nftables)
                opkg install bash dnsmasq-full curl ca-bundle ip-full \
                    ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy \
                    luci-compat luci luci-base
                ;;
        esac
        ;;
esac

# 获取最新版本信息
OC_API="https://api.github.com/repos/vernesong/OpenClash/releases/latest"
curl -L --retry 2 "$(_oc_proxy "$OC_API")" -o /tmp/openclash_version

[ -f "/tmp/openclash_version" ] && \
    download_url=$(cat /tmp/openclash_version | jsonfilter -e '@.assets[*].browser_download_url' | grep "\.${PKG_EXT}$") && \
    [ -n "$download_url" ] && \
    curl -L --retry 2 "$(_oc_proxy "$download_url")" -o "/tmp/openclash.${PKG_EXT}" || \
    echo "OpenClash last version get failed"

[ -f "/tmp/openclash.${PKG_EXT}" ] && \
    case "$PKG_MANAGER" in
        apk) apk add -q --force-overwrite --clean-protected --allow-untrusted "/tmp/openclash.${PKG_EXT}" ;;
        opkg) opkg install "/tmp/openclash.${PKG_EXT}" ;;
    esac || \
    echo "OpenClash download failed"

echo "[OpenClash] Done"
