#!/bin/bash
# ============================================================
# 360V6 (qihoo_360v6) Slim Firmware Build Script
# Source: laipeng668/openwrt-6.x main-nss branch (kernel 6.12)
# Keep: LuCI + NSS accel + OpenClash + Aurora theme
# ============================================================

set -e

echo "=== Loading custom config ==="

# --- 1. Set hostname ---
sed -i "s/hostname='.*'/hostname='Openwrt'/g" package/base-files/files/bin/config_generate

# --- 2. Set firmware version ---
date_version=$(date +"%y.%m.%d")
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
    if [ -n "$orig_version" ]; then
        sed -i "s/${orig_version}/R${date_version}/g" package/lean/default-settings/files/zzz-default-settings
        echo "Version set to: R${date_version}"
    fi
fi

# --- 3. Remove unwanted LuCI app sources ---
# PassWall (duplicate of OpenClash)
rm -rf feeds/luci/applications/luci-app-passwall 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-passwall2 2>/dev/null || true
rm -rf package/passwall-packages 2>/dev/null || true
rm -rf package/luci-app-passwall 2>/dev/null || true
rm -rf package/luci-app-passwall2 2>/dev/null || true

# Intranet penetration
rm -rf feeds/luci/applications/luci-app-frpc 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-frps 2>/dev/null || true
rm -rf feeds/packages/net/frp 2>/dev/null || true

# Other uncommon apps
rm -rf feeds/luci/applications/luci-app-wechatpush 2>/dev/null || true
rm -rf package/luci-app-wechatpush 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-appfilter 2>/dev/null || true
rm -rf feeds/packages/net/open-app-filter 2>/dev/null || true
rm -rf package/OpenAppFilter 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-diskman 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-hd-idle 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-samba4 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-wol 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-vlmcsd 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-aria2 2>/dev/null || true
rm -rf feeds/packages/net/ariang 2>/dev/null || true
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

# --- 4. Clone Aurora theme ---
echo "=== Cloning Aurora theme ==="
rm -rf feeds/luci/themes/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora feeds/luci/themes/luci-theme-aurora

# --- 5. Clone latest OpenClash ---
echo "=== Cloning OpenClash ==="
rm -rf feeds/luci/applications/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# --- 5.5 Integrate custom LuCI dashboard ---
echo "=== Integrating custom LuCI dashboard ==="
rm -rf package/luci-app-dashboard
cp -r $GITHUB_WORKSPACE/packages/luci-app-dashboard package/luci-app-dashboard
chmod +x package/luci-app-dashboard/files/www/cgi-bin/dashboard-data
echo "Dashboard package copied to package/luci-app-dashboard"

# --- 6. Add helloworld feed ---
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# --- 7. Update and install feeds ---
echo "=== Updating feeds ==="
./scripts/feeds update -a
./scripts/feeds install -a

# --- 8. Set default home page to dashboard ---
echo "=== Setting default home to /admin/dashboard ==="
LUCI_CONFIG="package/feeds/luci/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CONFIG" ]; then
    if ! grep -q "option home" "$LUCI_CONFIG"; then
        sed -i "/config internal 'main'/a\\\toption home '/admin/dashboard'" "$LUCI_CONFIG"
        echo "Default home set to /admin/dashboard"
    else
        sed -i "s|option home.*|option home '/admin/dashboard'|" "$LUCI_CONFIG"
        echo "Default home updated to /admin/dashboard"
    fi
else
    echo "WARNING: LuCI config not found: $LUCI_CONFIG"
fi

echo "=== Custom config loaded ==="
