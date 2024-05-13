# 检查是否安装了go
if ! command -v go &>/dev/null; then
    echo "Go 没有安装，正在安装..."
    sudo apt update
    sudo apt install -y golang-go
    go version
else
    echo "Go 已经安装。"
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

# 检查是否安装了unzip
if ! command -v unzip &>/dev/null; then
    echo "unzip 没有安装，正在安装..."
    sudo apt update
    sudo apt install -y unzip
else
    echo "unzip 已经安装。"
fi

function install_mineral() {
    curl -LO https://github.com/ronanyeah/mineral-app/releases/download/v1/linux.zip
    unzip linux.zip
    main_menu
}

function runSingleMiner() {
    pm2 delete all
    read -p "输入sui钱包私钥：" sui_key
    WALLET=$sui_key pm2 start --name miner ./mineral-linux -- mine
    echo "开始挖矿"
    main_menu
}

function runMultipleMiners() {
    read -p "请输入含有sui私钥的txt文件路径（每行一个私钥）：" key_file
    if [ -f "$key_file" ]; then
        echo "私钥文件存在，正在读取..."
        while IFS= read -r sui_key; do
            WALLET=$sui_key pm2 start --name ${sui_key:0:16} ./mineral-linux -- mine
        done <"$key_file"
        echo "开始挖矿"
    else
        echo "私钥文件不存在。"
    fi
    main_menu
}

function stopMiners() {
    pm2 delete all
    echo "停止所有矿工"
    main_menu
}

function main_menu() {
    echo "#############################################################"
    echo "########脚本由推特用户: 十一 @wohefengyiyang 编写及免费分享########"
    echo "1. 安装mineral矿工"
    echo "2. 启动挖矿应用：单钱包"
    echo "3. 启动挖矿应用：多钱包"
    echo "4. 停止所有矿工"
    echo "退出脚本后，使用pm2 list查看进程列表，pm2 show 进程id 查看信息，pm2 logs 进程id 查看日志，pm2 stop 进程id 停止进程。"
    echo "#############################################################"
    read -p "请选择执行的操作：" install_type
    case $install_type in
    1)
        install_mineral
        ;;
    2)
        runSingleMiner
        ;;
    3)
        runMultipleMiners
        ;;
    4)
        stopMiners
        ;;
    *)
        echo "无效的选择。"
        ;;
    esac
}

main_menu