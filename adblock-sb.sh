#!/bin/bash

# 检查是否传入了至少一个文件作为参数
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 adblock_file1.txt [adblock_file2.txt ...]"
    exit 1
fi

# 创建临时文件来存储域名和 IP 地址
DOMAIN_TMP=$(mktemp)
IP_TMP=$(mktemp)

# 遍历所有输入文件
for INPUT_FILE in "$@"; do
    # 使用 awk 处理每个输入文件
    awk '
    # 验证 IPv4 地址是否有效
    function is_valid_ipv4(ip) {
        n = split(ip, a, ".")
        if (n != 4) return 0
        for (i = 1; i <= 4; i++) {
            if (a[i] !~ /^[0-9]+$/ || a[i] < 0 || a[i] > 255) return 0
        }
        # 支持 CIDR 格式，例如：192.168.1.1/24
        return (ip ~ /\/[0-9]+$/ || ip !~ /\/.*/)
    }

    # 验证 IPv6 地址是否有效
    function is_valid_ipv6(ip) {
        # 支持 IPv6 CIDR 格式，例如：2001:0db8::ff00:42:8329/64
        return (ip ~ /^([0-9a-fA-F]{1,4}:){1,7}[0-9a-fA-F]{1,4}(\/[0-9]+)?$/)
    }

    # 验证域名是否有效
    function is_valid_domain(domain) {
        return (domain ~ /^[A-Za-z0-9.-]+$/ && domain ~ /\./)
    }

    # 处理每一行
    {
        # 清理掉方括号和逗号
        gsub(/\[|\]|,/, "", $0)

        # 提取所有 IP 地址（IPv4 和 IPv6）
        while (match($0, /([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]+)?|([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}(\/[0-9]+)?/)) {
            ip = substr($0, RSTART, RLENGTH)
            # 如果是有效的 IPv4 或 IPv6 地址，保存到临时文件
            if (is_valid_ipv4(ip) || is_valid_ipv6(ip)) {
                print ip >> "'"$IP_TMP"'"
            }
            # 移除已匹配的部分，继续查找下一个 IP 地址
            $0 = substr($0, RSTART + RLENGTH)
        }

        # 处理以 || 开头的域名规则
        if ($0 ~ /^\|\|/) {
            domain = substr($0, 3)
            sub(/[\$\^\/].*$/, "", domain)  # 移除域名中的特殊字符
            # 如果是合法的 IP 地址，保存到临时文件
            if (domain ~ /^[0-9a-fA-F:.]+$/) {
                if (is_valid_ipv4(domain) || is_valid_ipv6(domain)) {
                    print domain >> "'"$IP_TMP"'"
                }
            }
            # 如果是合法的域名，保存到域名临时文件
            else if (is_valid_domain(domain)) {
                print domain >> "'"$DOMAIN_TMP"'"
            }
        }
    }
    ' "$INPUT_FILE"
done

# 快速去重，确保域名和 IP 地址不重复
sort -u "$DOMAIN_TMP" -o "$DOMAIN_TMP"
sort -u "$IP_TMP" -o "$IP_TMP"

# 输出符合格式的 JSON 配置
{
    echo '{'
    echo '  "version": 3,'
    echo '  "rules": ['
    echo '    {'

    echo '      "domain_suffix": ['
    first=1
    while IFS= read -r domain; do
        if [ $first -eq 1 ]; then
            echo "        \"$domain\""
            first=0
        else
            echo "        ,\"$domain\""
        fi
    done < "$DOMAIN_TMP"
    echo '      ],'

    echo '      "ip_cidr": ['
    first=1
    while IFS= read -r ip; do
        if [ $first -eq 1 ]; then
            echo "        \"$ip\""
            first=0
        else
            echo "        ,\"$ip\""
        fi
    done < "$IP_TMP"
    echo '      ],'

    echo '      "invert": false'
    echo '    }'
    echo '  ]'
    echo '}'
}

# 删除临时文件
rm -f "$DOMAIN_TMP" "$IP_TMP"
