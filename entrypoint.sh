#!/bin/sh

# Global variables
DIR_CONFIG="/etc/v2ray"
DIR_RUNTIME="/usr/bin"
DIR_TMP="$(mktemp -d)"

mkdir -p /var/log/v2ray
: ${IPORT:=8080}
: ${ID:=a10c2d39-2d54-4648-9e2e-11dbfdccfd16}
: ${AID:=0}
: ${WSPATH:=/}
# Write V2Ray configuration
cat << EOF > ${DIR_TMP}/heroku.json
{
    "log": {
        "loglevel": "info",
        "access": "/dev/stdout",
        "error": "/dev/stderr"
    },

    "inbounds": [{
        "port": ${IPORT},
        "protocol": "vmess",
        "settings": {
            "clients": [{
                "id": "${ID}",
                "alterId": ${AID}
            }]
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": {
                "path": "${WSPATH}"
            }
        }
    }],
    "outbounds": [{
        "protocol": "freedom"
    }]
}
EOF

# Get V2Ray executable release
curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL github.com/v2fly/v2ray-core/releases/download/v4.41.0/v2ray-linux-64.zip -o ${DIR_TMP}/v2ray_dist.zip
busybox unzip ${DIR_TMP}/v2ray_dist.zip -d ${DIR_TMP}

# Convert to protobuf format configuration
mkdir -p ${DIR_CONFIG}
cp ${DIR_TMP}/heroku.json ${DIR_CONFIG}/config.json
# Install V2Ray
install -m 755 ${DIR_TMP}/v2ray ${DIR_RUNTIME}
rm -rf ${DIR_TMP}

# Run V2Ray
${DIR_RUNTIME}/v2ray -config=${DIR_CONFIG}/config.json
