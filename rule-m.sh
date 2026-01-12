#!/bin/bash

set -ex

# 创建存放文件的目录
DOWNLOAD_DIR="${GITHUB_WORKSPACE}/adguard/blocklists"
mkdir -p "$DOWNLOAD_DIR"
cd ${GITHUB_WORKSPACE}/adguard

# 定义 URL 列表
URLS=(
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/doh.txt"
    "https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/domain.txt"
)

# 下载文件
for url in "${URLS[@]}"; do
    filename="$DOWNLOAD_DIR/$(basename "$url")"

    echo "正在下载: $url"

    # 使用 wget 下载，最多重试 3 次
    wget --timeout 30 --tries 3 -qO "$filename" "$url"

    # 检查是否下载成功
    if [[ $? -ne 0 ]]; then
        echo "❌ 下载失败: $url" >> $GITHUB_STEP_SUMMARY
        exit 1
    else
        echo "✅ 下载成功: $filename"
    fi
done

# 合并所有文件
echo "🔄 正在合并文件..."
cat "$DOWNLOAD_DIR"/* > merged.txt

# 去重
echo "🧹 正在去重..."
sort merged.txt | uniq > adblockdns.txt

mihomo convert-ruleset domain text "adblockdns.txt" "adblockdns-ios.mrs"
mv -f "adblockdns-ios.mrs" ${GITHUB_WORKSPACE}/mihomo/rule_set_site



# 定义 URL 列表
URLS=(
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/tif.txt"
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/ultimate.txt"
    "https://raw.githubusercontent.com/ppfeufer/adguard-filter-list/master/blocklist"
    "https://raw.githubusercontent.com/badmojr/1Hosts/refs/heads/master/Xtra/domains.txt"
)

# 下载文件
for url in "${URLS[@]}"; do
    filename="$DOWNLOAD_DIR/$(basename "$url")"

    echo "正在下载: $url"

    # 使用 wget 下载，最多重试 3 次
    wget --timeout 30 --tries 3 -qO "$filename" "$url"

    # 检查是否下载成功
    if [[ $? -ne 0 ]]; then
        echo "❌ 下载失败: $url" >> $GITHUB_STEP_SUMMARY
        exit 1
    else
        echo "✅ 下载成功: $filename"
    fi
done

# 合并所有文件
echo "🔄 正在合并文件..."
cat "$DOWNLOAD_DIR"/* > merged.txt

# 去重
echo "🧹 正在去重..."
sort merged.txt | uniq > adblockdns.txt

mihomo convert-ruleset domain text "adblockdns.txt" "adblockdns.mrs"
mv -f "adblockdns.mrs" ${GITHUB_WORKSPACE}/mihomo/rule_set_site

# 清理临时文件
rm -rf ./*

echo "🎉 处理完成！"



mkdir -p "$DOWNLOAD_DIR"
# 定义 URL 列表
URLS=(
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/ips/doh.txt"
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/ips/tif.txt"
)

# 下载文件
for url in "${URLS[@]}"; do
    filename="$DOWNLOAD_DIR/$(basename "$url")"

    echo "正在下载: $url"

    # 使用 wget 下载，最多重试 3 次
    wget --timeout 30 --tries 3 -qO "$filename" "$url"

    # 检查是否下载成功
    if [[ $? -ne 0 ]]; then
        echo "❌ 下载失败: $url" >> $GITHUB_STEP_SUMMARY
        exit 1
    else
        echo "✅ 下载成功: $filename"
    fi
done

# 合并所有文件
echo "🔄 正在合并文件..."
cat "$DOWNLOAD_DIR"/* > merged.txt

# 去重
echo "🧹 正在去重..."
sort merged.txt | uniq > adblock-ip.txt

sed -Ei 's/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)$/\1\/32/' adblock-ip.txt
mihomo convert-ruleset ipcidr text "adblock-ip.txt" "adblock-ip.mrs"
mv -f "adblock-ip.mrs" ${GITHUB_WORKSPACE}/mihomo/rule_set_site

# 清理临时文件
rm -rf ${GITHUB_WORKSPACE}/adguard

echo "🎉 处理完成！"
