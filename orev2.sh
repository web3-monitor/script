# 检查是否以root用户运行
if [ "$(id -u)" != "0" ]; then
    echo "需要以root用户权限运行当前脚本"
    echo "请使用 'sudo -i' 切换到root用户，然后重新运行脚本。"
    exit 1
fi

# 检查git是否安装，如果没有安装则安装git
if ! command -v git &>/dev/null; then
    echo "未检测到git，正在安装..."
    apt update
    apt install git -y
else
    echo "git已安装。"
fi

# 更新及安装依赖
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen

# 检查是否安装rust和cargo
if ! command -v cargo &>/dev/null; then
    echo "未检测到rust和cargo，正在安装..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
else
    echo "rust和cargo已安装。"
fi

# 检查solana cli是否安装
if ! command -v solana &>/dev/null; then
    echo "未检测到solana cli，正在安装..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.9.6/install)"
else
    echo "solana cli已安装。"
fi

# 检查 solana-keygen 是否在 PATH 中
if ! command -v solana-keygen &>/dev/null; then
    echo "将 solana cli 添加到 PATH"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    export PATH="$HOME/.cargo/bin:$PATH"
fi

function install_orev2() {
    # clone ore仓库
    git clone https://github.com/hardhatchad/ore
    git clone https://github.com/hardhatchad/ore-cli
    git clone https://github.com/hardhatchad/drillx

    # 切换到v2分支
    cd ore && git checkout hardhat/v2 && cd ..
    cd ore-cli && git checkout hardhat/v2

    # 开始构建mint应用
    cargo build --release
    cd ..

    read -p "请输入solana rpc地址(当前仅能在开发者测试网运行，默认为https://api.devnet.solana.com): " solana_rpc
    custom_rpc=${solana_rpc:-"https://api.devnet.solana.com"}
    read -p "请输入mint orev2的线程数,(默认为4): " threads
    custom_threads=${threads:-4}
    read -p "请输入停止挖矿并开始提交的活性惩罚截止日期前的秒数,(默认为10): " custom_buffer_time
    buffer_time=${custom_buffer_time:-10}
    read -p "请输入交易的优先费用,(默认为1): " custom_priority_fee
    priority_fee=${custom_priority_fee:-1}

    session_base_name="orev2"
    start_command_template="while true; do ore --rpc $solana_rpc --keypair ~/.config/solana/idX.json --priority-fee $priority_fee mine --threads $threads --buffer-time $buffer_time; echo '进程异常退出，等待重启' >&2; sleep 1; done"





"
}
