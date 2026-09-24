#!/bin/bash
# ============================================================
# 360V6 (qihoo_360v6) 精简固件 自定义编译脚本
# 源码: laipeng668/openwrt-6.x 25.12-nss 分支 (6.12内核, LibWrt/Kwrt NSS同源体系)
# 保留: LuCI管理界面 + NSS加速(ECM) + OpenClash + IPv6 + Aurora主题 + 系统仪表盘
# 第四版: 保留 Samba4共享 + aria2/AriaNG下载 + amule电驴 + USB U盘挂载
# 吸收 Kwrt diy.sh: 清理 shortcut-fe(与NSS ECM冲突) + wpad-mbedtls
# ============================================================

set -e

echo "=== 开始加载自定义配置 ==="

# --- 1. 修改默认IP和主机名 ---
# 默认IP保持 192.168.1.1
sed -i "s/hostname='.*'/hostname='Openwrt'/g" package/base-files/files/bin/config_generate

# --- 2. 修改固件版本号 ---
date_version=$(date +"%y.%m.%d")
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
    if [ -n "$orig_version" ]; then
        sed -i "s/${orig_version}/R${date_version}/g" package/lean/default-settings/files/zzz-default-settings
        echo "版本号已修改为: R${date_version}"
    fi
fi

# --- 3. 移除不需要的LuCI应用源码 ---
# PassWall 全套（与OpenClash功能重复）
rm -rf feeds/luci/applications/luci-app-passwall 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-passwall2 2>/dev/null || true
rm -rf package/passwall-packages 2>/dev/null || true
rm -rf package/luci-app-passwall 2>/dev/null || true
rm -rf package/luci-app-passwall2 2>/dev/null || true

# 内网穿透
rm -rf feeds/luci/applications/luci-app-frpc 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-frps 2>/dev/null || true
rm -rf feeds/packages/net/frp 2>/dev/null || true

# 其他不常用应用
rm -rf feeds/luci/applications/luci-app-wechatpush 2>/dev/null || true
rm -rf package/luci-app-wechatpush 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-appfilter 2>/dev/null || true
rm -rf feeds/packages/net/open-app-filter 2>/dev/null || true
rm -rf package/OpenAppFilter 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-diskman 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-hd-idle 2>/dev/null || true
# 保留: luci-app-samba4（局域网共享）、luci-app-aria2 + ariang（下载）
rm -rf feeds/luci/applications/luci-app-wol 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-vlmcsd 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-autoreboot 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-wifischedule 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-banip 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-acme 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-arpbind 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-usb-printer 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-watchcat 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-smartdns 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-zerotier 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-cpufreq 2>/dev/null || true
rm -rf package/luci-app-lucky 2>/dev/null || true
rm -rf package/openlist2 2>/dev/null || true
rm -rf package/luci-app-gecoosac 2>/dev/null || true
rm -rf package/luci-app-athena-led 2>/dev/null || true

# --- 3.5 NSS 冲突清理（吸收 kiddin9/Kwrt diy.sh）---
# shortcut-fe 是软件快速路径，与高通 NSS ECM 硬件快速路径冲突，必须移除
rm -rf feeds/kiddin9/shortcut-fe 2>/dev/null || true
rm -rf package/shortcut-fe 2>/dev/null || true
# wpad 默认切 mbedtls 版（体积更小，Kwrt 默认；WPA2/WPA3 个人版均支持）
sed -i "s/wpad-openssl/wpad-mbedtls/g" target/linux/qualcommax/Makefile 2>/dev/null || true

# --- 4. 克隆 Aurora 主题 ---
echo "=== 克隆Aurora主题 ==="
rm -rf feeds/luci/themes/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora feeds/luci/themes/luci-theme-aurora

# --- 5. 克隆最新 OpenClash ---
echo "=== 克隆最新OpenClash ==="
rm -rf feeds/luci/applications/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# --- 5.5 集成自定义 LuCI 仪表盘 ---
echo "=== 集成自定义 LuCI 仪表盘 ==="
rm -rf package/luci-app-dashboard
cp -r $GITHUB_WORKSPACE/packages/luci-app-dashboard package/luci-app-dashboard
chmod +x package/luci-app-dashboard/files/www/cgi-bin/dashboard-data
echo "仪表盘包已复制到 package/luci-app-dashboard"

# --- 6. 更新并安装 feeds ---
echo "=== 更新feeds ==="
./scripts/feeds update -a
./scripts/feeds install -a

# --- 7. 设置默认登录页为仪表盘 ---
echo "=== 设置默认首页为系统仪表盘 ==="
LUCI_CONFIG="package/feeds/luci/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CONFIG" ]; then
    # 在 config internal 'main' 段中添加 option home
    if ! grep -q "option home" "$LUCI_CONFIG"; then
        sed -i "/config internal 'main'/a\\\toption home '/admin/dashboard'" "$LUCI_CONFIG"
        echo "已设置默认首页为 /admin/dashboard"
    else
        sed -i "s|option home.*|option home '/admin/dashboard'|" "$LUCI_CONFIG"
        echo "已更新默认首页为 /admin/dashboard"
    fi
else
    echo "警告: 未找到 LuCI 配置文件 $LUCI_CONFIG"
fi

echo "=== 自定义配置加载完成 ==="
