# 检查mac是否安装brew，如果没有安装则安装brew
if ! command -v brew &>/dev/null; then
    echo "Homebrew未安装，准备安装..."
    # 是否使用国内镜像源
    read -p "是否使用国内镜像源？[y/n]: " use_mirror
    if [ "$use_mirror" = "y" ]; then
        echo "使用国内镜像源"
        /bin/bash -c "$(curl -fsSL https://gitee.com/shiyi_liu/script/blob/main/Homebrew.sh)"
    else
        echo "使用官方源"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
else
    echo "Homebrew已安装。"
fi

# 检查git是否安装，如果没有安装则安装git
if ! command -v git &>/dev/null; then
    echo "Git未安装，正在安装..."
    brew install git
else
    echo "Git已安装。"
fi

# 检查Docker Desktop是否安装如果没有安装则安装Docker Desktop
if ! [ -d "/Applications/Docker.app" ]; then
    if [ "$(uname -m)" = "arm64" ]; then
        echo "Mac使用芯片为M系列芯片, 安装Rosetta"
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    else
        echo "Mac使用芯片为Intel系列芯片。"
    fi
    echo "Docker Desktop未安装，正在安装..."
    brew install --cask --appdir=/Applications docker
else
    echo "Docker Desktop已安装。"
fi

if ! pgrep -q "Docker"; then
    echo "Docker Desktop未启动，正在启动..."
    open -a docker
    read -p "请确认Docker Desktop已完全启动，启动后请按任意键继续: "
else
    echo "Docker Desktop已启动。"
fi

function install_taiko() {
    # clone taiko仓库
    git clone https://github.com/taikoxyz/simple-taiko-node.git
    cd simple-taiko-node

    # 复制配置文件
    if [ ! -f .env ]; then
        cp .env.sample .env
    fi

    # 设置配置文件
    read -p "请输入holesky http链接: " l1_endpoint_http

    read -p "请输入holesky ws链接: " l1_endpoint_ws

    read -p "请输入Beacon Holskey RPC链接: " l1_beacon_http

    read -p "请输入Prover RPC 链接(可输入多个rpc, 多个rpc直接用,隔开): " prover_endpoints

    read -p "请确认是否作为提议者（可选true或者false，建议true）: " enable_proposer

    read -p "请输入EVM钱包私钥,去掉私钥前面的0x: " l1_proposer_private_key

    read -p "请输入EVM钱包地址: " l2_suggested_fee_recipient

    read -p "设置PROPOSAL_FEE(默认为1): " block_proposal_fee

    # 将配置信息写入.env文件
    sed -i "" "s|L1_ENDPOINT_HTTP=.*|L1_ENDPOINT_HTTP=${l1_endpoint_http}|" .env
    sed -i "" "s|L1_ENDPOINT_WS=.*|L1_ENDPOINT_WS=${l1_endpoint_ws}|" .env
    sed -i "" "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=${l1_beacon_http}|" .env
    sed -i "" "s|ENABLE_PROPOSER=.*|ENABLE_PROPOSER=${enable_proposer}|" .env
    sed -i "" "s|L1_PROPOSER_PRIVATE_KEY=.*|L1_PROPOSER_PRIVATE_KEY=${l1_proposer_private_key}|" .env
    sed -i "" "s|L2_SUGGESTED_FEE_RECIPIENT=.*|L2_SUGGESTED_FEE_RECIPIENT=${l2_suggested_fee_recipient}|" .env
    sed -i "" "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=${prover_endpoints}|" .env
    sed -i "" "s|BLOCK_PROPOSAL_FEE=.*|BLOCK_PROPOSAL_FEE=${block_proposal_fee}|" .env

    echo "配置文件.env已配置完毕"
    echo "端口使用官方默认端口，如需修改，请修改.env文件中的端口"

    # 运行 Taiko 节点
    docker compose --profile l2_execution_engine down
    docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
    docker compose --profile l2_execution_engine up -d
    docker compose --profile proposer up -d

    # 查看节点仪表板
    echo "Taiko 节点已启动，可以通过以下链接查看节点仪表板："
    echo "本地主机：http://localhost:3001/d/L2ExecutionEngine/l2-execution-engine-overview?orgId=1&refresh=10s&from=now-1m&to=now"
    echo "服务器：http://<服务器IP>:3001/d/L2ExecutionEngine/l2-execution-engine-overview?orgId=1&refresh=10s&from=now-1m&to=now"
}

function update_prover() {
    cd
    cd simple-taiko-node
    read -p "请输入Prover RPC 链接(可输入多个rpc, 多个rpc直接用,隔开): " prover_endpoints
    sed -i "" "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=${prover_endpoints}|" .env
    echo "修改 prover rpc 成功，正在重启taiko节点"
    docker compose --profile l2_execution_engine down
    docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
    docker compose --profile l2_execution_engine up -d
    docker compose --profile proposer up -d
    echo "taiko节点重启成功"
}

function update_fee() {
    cd
    cd simple-taiko-node
    read -p "设置PROPOSAL_FEE(默认为1): " block_proposal_fee
    sed -i "" "s|BLOCK_PROPOSAL_FEE=.*|BLOCK_PROPOSAL_FEE=${block_proposal_fee}|" .env
    echo "修改 proposal fee 成功，正在重启taiko节点"
    docker compose --profile l2_execution_engine down
    docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
    docker compose --profile l2_execution_engine up -d
    docker compose --profile proposer up -d
    echo "taiko节点重启成功"
}

function update_beacon() {
    cd
    cd simple-taiko-node
    read -p "请输入Beacon Holskey RPC链接: " l1_beacon_http
    sed -i "" "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=${l1_beacon_http}|" .env
    echo "修改 beacon holskey rpc 成功，正在重启taiko节点"
    docker compose --profile l2_execution_engine down
    docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
    docker compose --profile l2_execution_engine up -d
    docker compose --profile proposer up -d
    echo "taiko节点重启成功"
}

function delete_taiko() {
    cd
    cd simple-taiko-node
    docker compose --profile l2_execution_engine down -v
    docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
    cd
    rm -rf simple-taiko-node
    echo "Taiko 节点已删除"
}

function main_menu() {
    clear
    echo "#############################################################"
    echo "# Taiko节点 Mac 一键安装脚本                                   #"
    echo "# 1. 安装 Taiko                                              #"
    echo "# 2. 更新 Prover RPC 链接                                     #"
    echo "# 3. 更新 Beacon Holskey RPC链接                              #"
    echo "# 4. 更新 Block Proposal Fee                                 #"
    echo "# 5. 删除 Taiko 节点                                          #"
    read -p "请选择操作[1-5]:" opt
    case "$opt" in
    1)
        install_taiko
        ;;
    2)
        update_prover
        ;;
    3)
        update_beacon
        ;;
    4)
        update_fee
        ;;
    5)
        delete_taiko
        ;;
    esac
}

main_menu
