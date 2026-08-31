#!/bin/sh

# =====================================================
# MosDNS + OpenClash 安装脚本
#
# 用法：
#   sh install.sh
#   sh install.sh gh_proxy=https://gh-proxy.org/
#
# =====================================================


# =====================================================
# 公共配置
# =====================================================

gh_proxy=""

for arg in "$@"; do
    case "$arg" in
        gh_proxy=*)
            gh_proxy="${arg#gh_proxy=}"
            ;;
    esac
done

# 自动补 /
if [ -n "$gh_proxy" ]; then
    case "$gh_proxy" in
        */) ;;
        *)  gh_proxy="$gh_proxy/" ;;
    esac
fi


# GitHub URL 代理
proxy_url() {
    if [ -n "$gh_proxy" ]; then
        echo "${gh_proxy}$1"
    else
        echo "$1"
    fi
}


# =====================================================
# 检测系统
# =====================================================

if command -v apk >/dev/null 2>&1; then
    PKG="apk"
    EXT="apk"
elif command -v opkg >/dev/null 2>&1; then
    PKG="opkg"
    EXT="ipk"
else
    echo "ERROR: 未找到 apk 或 opkg"
    exit 1
fi


if command -v nft >/dev/null 2>&1; then
    FIREWALL="nftables"
else
    FIREWALL="iptables"
fi


echo "========================================"
echo " MosDNS + OpenClash"
echo "========================================"
echo "Package Manager : $PKG"
echo "Firewall        : $FIREWALL"

if [ -n "$gh_proxy" ]; then
    echo "GitHub Proxy    : $gh_proxy"
else
    echo "GitHub Proxy    : disabled"
fi

echo ""


# =====================================================
# 公共 LuCI 中文包
# =====================================================

install_luci_language() {

    echo "========================================"
    echo " LuCI 中文包"
    echo "========================================"

    if [ "$PKG" = "apk" ]; then

        apk update || return 1

        apk add \
            luci-i18n-base-zh-cn \
            luci-i18n-package-manager-zh-cn \
            luci-i18n-firewall-zh-cn

    else

        opkg update || return 1

        opkg install \
            luci-i18n-base-zh-cn \
            luci-i18n-package-manager-zh-cn \
            luci-i18n-firewall-zh-cn

    fi
}


# =====================================================
# MosDNS
# =====================================================

install_mosdns() {

    echo ""
    echo "========================================"
    echo " [1/2] MosDNS"
    echo "========================================"


    # -------------------------------------------------
    # 检测
    # -------------------------------------------------

    if [ "$PKG" = "apk" ]; then
        apk info -e luci-app-mosdns >/dev/null 2>&1
    else
        opkg status luci-app-mosdns 2>/dev/null \
            | grep -q "Status: install"
    fi


    # -------------------------------------------------
    # 已安装
    # -------------------------------------------------

    if [ $? -eq 0 ]; then

        echo "检测到 MosDNS 已安装"

        printf "是否重新安装最新版 MosDNS？[y/N]: "
        read answer

        case "$answer" in
            y|Y|yes|YES)
                echo "重新安装 MosDNS"
                ;;
            *)
                echo "跳过 MosDNS"
                return 0
                ;;
        esac

    else

        echo "未检测到 MosDNS"

    fi


    # -------------------------------------------------
    # 下载官方安装脚本
    # -------------------------------------------------

    MOS_SCRIPT="https://raw.githubusercontent.com/sbwml/luci-app-mosdns/v5/install.sh"
    MOS_SCRIPT_URL="$(proxy_url "$MOS_SCRIPT")"

    rm -f /tmp/mosdns_install.sh

    echo "下载 MosDNS 安装脚本..."

    if ! curl -ksSfL --retry 2 \
        "$MOS_SCRIPT_URL" \
        -o /tmp/mosdns_install.sh; then

        echo "ERROR: MosDNS 安装脚本下载失败"
        return 1
    fi


    # -------------------------------------------------
    # 执行官方安装脚本
    # -------------------------------------------------

    echo "安装 MosDNS..."

    if [ -n "$gh_proxy" ]; then
        sh /tmp/mosdns_install.sh \
            gh_proxy="$gh_proxy"
    else
        sh /tmp/mosdns_install.sh
    fi

    result=$?

    rm -f /tmp/mosdns_install.sh

    if [ $result -eq 0 ]; then
        echo "MosDNS 安装完成 ✔"
    else
        echo "ERROR: MosDNS 安装失败"
    fi

    return $result
}


# =====================================================
# OpenClash
# =====================================================

install_openclash() {

    echo ""
    echo "========================================"
    echo " [2/2] OpenClash"
    echo "========================================"


    # -------------------------------------------------
    # 检测
    # -------------------------------------------------

    if [ "$PKG" = "apk" ]; then
        apk info -e luci-app-openclash >/dev/null 2>&1
    else
        opkg status luci-app-openclash 2>/dev/null \
            | grep -q "Status: install"
    fi


    # -------------------------------------------------
    # 已安装
    # -------------------------------------------------

    if [ $? -eq 0 ]; then

        echo "检测到 OpenClash 已安装"

        printf "是否重新安装最新版 OpenClash？[y/N]: "
        read answer

        case "$answer" in
            y|Y|yes|YES)
                echo "重新安装 OpenClash"
                ;;
            *)
                echo "跳过 OpenClash"
                return 0
                ;;
        esac

    else

        echo "未检测到 OpenClash"

    fi


    # -------------------------------------------------
    # 安装官方依赖
    # -------------------------------------------------

    echo "安装 OpenClash 依赖..."

    if [ "$PKG" = "apk" ]; then

        apk update || return 1

        if [ "$FIREWALL" = "iptables" ]; then

            apk add \
                bash \
                iptables \
                dnsmasq-full \
                curl \
                ca-bundle \
                ipset \
                ip-full \
                iptables-mod-tproxy \
                iptables-mod-extra \
                ruby \
                ruby-yaml \
                kmod-tun \
                kmod-inet-diag \
                unzip \
                luci-compat \
                luci \
                luci-base

        else

            apk add \
                bash \
                dnsmasq-full \
                curl \
                ca-bundle \
                ip-full \
                ruby \
                ruby-yaml \
                kmod-tun \
                kmod-inet-diag \
                unzip \
                kmod-nft-tproxy \
                luci-compat \
                luci \
                luci-base

        fi

    else

        opkg update || return 1

        if [ "$FIREWALL" = "iptables" ]; then

            opkg install \
                bash \
                iptables \
                dnsmasq-full \
                curl \
                ca-bundle \
                ipset \
                ip-full \
                iptables-mod-tproxy \
                iptables-mod-extra \
                ruby \
                ruby-yaml \
                kmod-tun \
                kmod-inet-diag \
                unzip \
                luci-compat \
                luci \
                luci-base

        else

            opkg install \
                bash \
                dnsmasq-full \
                curl \
                ca-bundle \
                ip-full \
                ruby \
                ruby-yaml \
                kmod-tun \
                kmod-inet-diag \
                unzip \
                kmod-nft-tproxy \
                luci-compat \
                luci \
                luci-base

        fi

    fi

    if [ $? -ne 0 ]; then
        echo "ERROR: OpenClash 依赖安装失败"
        return 1
    fi


    # -------------------------------------------------
    # 获取最新版 OpenClash
    # -------------------------------------------------

    OC_API="https://api.github.com/repos/vernesong/OpenClash/releases/latest"
    OC_API_URL="$(proxy_url "$OC_API")"

    rm -f /tmp/openclash_version
    rm -f "/tmp/openclash.$EXT"

    echo "获取 OpenClash 最新版本..."

    if ! curl -fL --retry 2 \
        "$OC_API_URL" \
        -o /tmp/openclash_version; then

        echo "ERROR: OpenClash 最新版本获取失败"
        return 1
    fi


    # -------------------------------------------------
    # 获取安装包地址
    # -------------------------------------------------

    download_url=$(cat /tmp/openclash_version \
        | jsonfilter -e '@.assets[*].browser_download_url' \
        | grep "\.${EXT}$" \
        | head -n 1)

    if [ -z "$download_url" ]; then
        echo "ERROR: 未找到 OpenClash .$EXT 安装包"
        rm -f /tmp/openclash_version
        return 1
    fi


    # -------------------------------------------------
    # 添加 GitHub Proxy
    # -------------------------------------------------

    download_url="$(proxy_url "$download_url")"

    echo "OpenClash 下载地址："
    echo "$download_url"


    # -------------------------------------------------
    # 下载
    # -------------------------------------------------

    echo "下载 OpenClash..."

    if ! curl -fL --retry 2 \
        "$download_url" \
        -o "/tmp/openclash.$EXT"; then

        echo "ERROR: OpenClash 下载失败"

        rm -f /tmp/openclash_version
        rm -f "/tmp/openclash.$EXT"

        return 1
    fi


    # -------------------------------------------------
    # 安装
    # -------------------------------------------------

    echo "安装 OpenClash..."

    if [ "$PKG" = "apk" ]; then

        apk add -q \
            --force-overwrite \
            --clean-protected \
            --allow-untrusted \
            "/tmp/openclash.$EXT"

    else

        opkg install "/tmp/openclash.$EXT"

    fi

    result=$?


    # -------------------------------------------------
    # 清理
    # -------------------------------------------------

    rm -f /tmp/openclash_version
    rm -f "/tmp/openclash.$EXT"


    if [ $result -eq 0 ]; then
        echo "OpenClash 安装完成 ✔"
    else
        echo "ERROR: OpenClash 安装失败"
    fi

    return $result
}


# =====================================================
# 执行
# =====================================================

install_luci_language

# MosDNS 和 OpenClash 相互独立
install_mosdns
MOSDNS_RESULT=$?

install_openclash
OPENCLASH_RESULT=$?


# =====================================================
# 总结
# =====================================================

echo ""
echo "========================================"
echo " 安装完成"
echo "========================================"

if [ $MOSDNS_RESULT -eq 0 ]; then
    echo "MosDNS    : OK"
else
    echo "MosDNS    : FAILED"
fi

if [ $OPENCLASH_RESULT -eq 0 ]; then
    echo "OpenClash : OK"
else
    echo "OpenClash : FAILED"
fi

echo "========================================"
