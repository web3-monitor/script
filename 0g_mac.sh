function install_resources() {
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

    # 检查是否安装rust和cargo
    if ! command -v cargo &>/dev/null; then
        echo "未检测到rust和cargo，正在安装..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
    else
        echo "rust和cargo已安装。"
    fi

    if ! command -v node &>/dev/null; then
        echo "Node.js 没有安装，正在安装..."
        brew install node
    else
        echo "Node.js 已经安装。"
    fi

    if ! command -v pm2 &>/dev/null; then
        echo "pm2 没有安装，正在安装..."
        npm install -g pm2
    else
        echo "pm2 已经安装。"
    fi

    brew install go llvm cmake

}

function install_storage_node() {
    install_resources
    # clone storage node库
    git clone -b v0.2.0 https://github.com/0glabs/0g-storage-node.git

    cd 0g-storage-node
    git submodule update --init

    # Build in release mode
    cargo build --release

    cd run

    read -p "请输入EVM钱包私钥（如果私钥以0x开头，删掉0x）: " miner_key

    sed -i "" "s/miner_key = \"\"/miner_key = \"$miner_key\"/" config.toml
    sed -i "" 's|blockchain_rpc_endpoint = "https://rpc-testnet.0g.ai"|blockchain_rpc_endpoint = "https://0g-evm-rpc.stakeme.pro"|g' config.toml

    sed -i "" 's/log_sync_start_block_number = 80981/log_sync_start_block_number = 172634/' config.toml

    pm2 start ../target/release/zgs_node -- --config config.toml

    echo "-------0g存储节点启动成功------"
}

function storage_node_logs() {
    tail -f "$(ls -t ~/0g-storage-node/run/log/* | head -n1)"
}

function menu() {
    while true; do
        echo "==================== 0g存储节点一键安装教程 ===================="
        echo "====== 脚本由推特用户: 十一 @wohefengyiyang 编写及免费分享 ======"
        echo "1. 安装0g存储节点"
        echo "2. 查看0g存储节点日志"
        echo "3. 查看0g存储节点运行状态"
        echo "4. 退出"
        echo "============================================================="
        read -p "请选择操作[0-3]: " choice
        case $choice in
        1)
            install_storage_node
            ;;
        2)
            storage_node_logs
            ;;
        3)  
            pm2 list
            ;;
        4)
            exit 0
            ;;
        *)
            echo "无效的选项"
            ;;
        esac
    done
}

menu
