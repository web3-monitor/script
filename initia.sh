if [ "$(id -u)" != "0" ]; then
    echo "请使用root权限运行此脚本"
    echo "请使用 sudo -i 命令切换到root权限后再重新运行此脚本"
    exit 1
fi

function install_environment() {
    # 检查是否安装了go
    TARGET_VERSION=1223 # 目标版本，例如1.22.3就写1223
    if ! command -v go &>/dev/null; then
        echo "Go 没有安装，正在安装..."
        curl -O https://dl.google.com/go/go1.22.3.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        source $HOME/.bash_profile
        go version
    else
        CURRENT_VERSION=$(go version | awk '{print $3}' | tr -d 'go' | tr -d '.')
        if [ "$CURRENT_VERSION" -lt "$TARGET_VERSION" ]; then
            echo "Go 的版本过低，正在更新..."
            curl -O https://dl.google.com/go/go1.22.3.linux-amd64.tar.gz
            sudo tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
            source $HOME/.bash_profile
        else
            echo "Go 已经安装，版本为 $(go version | awk '{print $3}')。"
        fi
    fi

    # 检查是否安装了node
    if ! command -v node &>/dev/null; then
        echo "Node.js 没有安装，正在安装..."
        curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        echo "Node.js 已经安装。"
    fi

    # 检查是否安装了pm2
    if ! command -v pm2 &>/dev/null; then
        echo "pm2 没有安装，正在安装..."
        npm install -g pm2
    else
        echo "pm2 已经安装。"
    fi

    # 安装相关依赖
    sudo apt install -y build-essential git curl iptables wget jq make gcc htop nvme-cli libssl-dev libleveldb-dev tar clang bsdmainutils ncdu libleveldb-dev lz4 snapd unzip
}

function install_initia() {
    install_environment

    #安装initiad
    git clone https://github.com/initia-labs/initia
    cd initia
    #切到v0.2.14版本
    git checkout v0.2.14
    make install
    initiad version --long

    # init initiad with default setting
    initiad init "moniker" --chain-id initiation-1
    initiad config set client chain-id initiation-1

    # get genesis.json and addrbook.json
    curl -Ls https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/genesis.json > \
        $HOME/.initia/config/genesis.json
    # Accessing Network Information
    curl -Ls https://rpc-initia-testnet.trusted-point.com/addrbook.json > \
        $HOME/.initia/config/addrbook.json

    # install Slinky Oracle
    git clone https://github.com/skip-mev/slinky.git
    cd slinky

    # checkout proper version
    git checkout v0.4.3

    # Build the Slinky binary in the repo.
    make build

    # 重载confg.toml和app.toml文件
    CONFIG_FILE_PATH="https://raw.githubusercontent.com/web3-monitor/script/main/configs/initia/config.toml"
    APP_FILE_PATH="https://raw.githubusercontent.com/web3-monitor/script/main/configs/initia/app.toml"
    curl -Ls $CONFIG_FILE_PATH >$HOME/.initia/config/config.toml
    curl -Ls $APP_FILE_PATH >$HOME/.initia/config/app.toml

    # 启动initiad
    pm2 start initiad -- start
    sleep 3 # 等待initiad启动
    pm2 save
    pm2 startup

    pm2 stop initiad
    sleep 3 # 等待initiad停止

    # 配置快照
    sudo apt install lz4 -y
    SNAPSHOT_FILE="latest_snapshot.tar.lz4"
    if [ -f "$SNAPSHOT_FILE" ]; then
        rm -f "$SNAPSHOT_FILE"
    fi
    wget https://rpc-initia-testnet.trusted-point.com/latest_snapshot.tar.lz4 -O $SNAPSHOT_FILE
    initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book
    lz4 -d -c ./$SNAPSHOT_FILE | tar -xf - -C $HOME/.initia

    # 启动slinky
    pm2 start ./build/slinky -- --oracle-config-path ./config/core/oracle.json --market-map-endpoint 0.0.0.0:50007
    # 重启initiad
    pm2 restart initiad

    echo "initia和slinky安装启动完成"
}

function list_initia() {
    pm2 list
}

function restart_initia() {
    pm2 restart initiad
    pm2 restart slinky
}

function initia_logs() {
    pm2 logs initiad
}

function slinky_logs() {
    pm2 logs slinky
}

function stop_initia() {
    pm2 stop initiad
    pm2 stop slinky
}

function remove_initia() {
    read -p "你确定要移除initia节点及相关数据？ (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pm2 delete all
        rm -rf $HOME/.initiad && rm -rf $HOME/initia $(which initiad) && rm -rf $HOME/.initia
        echo "initia节点已移除"
    fi
}

function create_wallet() {
    initiad keys add wallet
}

function import_wallet() {
    initiad keys add wallet --recover
}

function check_balances() {
    read -p "请输入initia钱包地址: " wallet_address
    initiad query bank balances "$wallet_address" --node tcp://localhost:50003
}

function node_sync_status() {
    initiad status --node tcp://localhost:50003 | jq .sync_info
}

function register_as_validator() {
    read -p "请输入钱包名称（本脚本导入及生成的钱包名默认为wallet）: " wallet
    read -p "请输入你希望设置的验证者名称（什么名称都行）: " validator
    read -p "请输入验证者的详情描述（什么描述都行）: " validator_desc
    initiad tx mstaking create-validator --amount=1000000uinit --pubkey=$(initiad tendermint show-validator) --moniker=$validator --chain-id=initiation-1 --commission-rate=0.05 --commission-max-rate=0.10 --commission-max-change-rate=0.01 --from=$wallet --identity="" --website="" --details=$validator_desc --gas=2000000 --fees=300000uinit --node tcp://localhost:50003 -y
}

function unjailing_validator() {
    read -p "请输入钱包名称（注册验证者时输入的钱包名）: " wallet
    initiad tx slashing unjail --from $wallet --fees=10000amf --chain-id=initiation-1 --node tcp://localhost:50003
}

function delegate_to_validator() {
    read -p "请输入钱包名称（本脚本导入及生成的钱包名默认为wallet）: " wallet
    read -p "请输入质押init数量: " amount
    initiad tx mstaking delegate $(initiad keys show wallet --bech val -a) $((amount * 1000000))uinit --from $wallet --chain-id initiation-1 --gas=2000000 --fees=300000uinit --node tcp://localhost:50003 -y
}

function update_initia() {
    cd initia
    git fetch && git checkout v0.2.14 && make install && pm2 restart initiad
}

function menu() {
    while true; do
        echo "#############################################################"
        echo "########脚本由推特用户: 十一 @wohefengyiyang 编写及免费分享########"
        echo "1. 安装initia节点"
        echo "2. 查看initia和slinky节点状态"
        echo "3. 重启initia和slinky节点"
        echo "4. 查看initia日志"
        echo "5. 停止initia和slinky节点"
        echo "6. 移除initia和slinky节点"
        echo "7. 创建钱包"
        echo "8. 导入钱包"
        echo "9. 查询余额"
        echo "10. 查询节点同步状态"
        echo "11. 注册验证者"
        echo "12. 解除验证者的监禁状态"
        echo "13. 委托给验证者"
        echo "14. 查看slinky日志"
        echo "15. 更新节点（官方版本有更新时再操作,当前版本v0.2.14）"
        echo "16. 退出"
        echo "#############################################################"
        read -p "请输入数字选择操作: " choice
        case $choice in
        1)
            install_initia
            ;;
        2)
            list_initia
            ;;
        3)
            restart_initia
            ;;
        4)
            initia_logs
            ;;
        5)
            stop_initia
            ;;
        6)
            remove_initia
            ;;
        7)
            create_wallet
            ;;
        8)
            import_wallet
            ;;
        9)
            check_balances
            ;;
        10)
            node_sync_status
            ;;
        11)
            register_as_validator
            ;;
        12)
            unjailing_validator
            ;;
        13)
            delegate_to_validator
            ;;
        14)
            slinky_logs
            ;;
        15)
            update_initia
            ;;
        16)
            break
            ;;
        *)
            echo "无效的选择"
            ;;
        esac
        read -p "按任意键继续..."
    done
}

menu
