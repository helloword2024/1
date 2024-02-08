#!/usr/bin/env bash
#原项目看不懂的地方
#PORT=${PORT:-'8080'}
#UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}

# 默认各参数值，请自行修改.(注意:伪装路径不需要 / 符号开始,为避免不必要的麻烦,请不要使用特殊符号.)

#设定环境代码
PORT=8080
UUID=de04add9-5c68-8bab-950c-08cd5320df18


# 生成 Xray 配置文件
cat > config.json << EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":${PORT},
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-direct"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":3001
                    },
                    {
                        "path":"/${UUID}-vless",
                        "dest":3002
                    },
                    {
                        "path":"/${UUID}-vmess",
                        "dest":3003
                    },
                    {
                        "path":"/${UUID}-trojan",
                        "dest":3004
                    },
                    {
                        "path":"/${UUID}-shadowsocks",
                        "dest":3005
                    },
                    {
                        "path":"/${UUID}-socks",
                        "dest":3006
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0,
                        "email":"argo@xray"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/${UUID}-vless"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/${UUID}-vmess"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/${UUID}-trojan"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/${UUID}-shadowsocks"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3006,
            "listen":"127.0.0.1",
            "protocol": "socks",
            "settings": {
                "auth": "password",
                "accounts": [
                    {
                        "user": "${UUID}",
                        "pass": "${UUID}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                  "path": "/${UUID}-socks"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        }
    ]
}
EOF

# 下载 Xray，并伪装 xray 执行文件
RANDOM_NAME=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
wget -O temp.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip temp.zip xray geosite.dat geoip.dat
mv xray ${RANDOM_NAME}
rm -f temp.zip

# 运行 xray
./${RANDOM_NAME} run -config config.json