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

if ! command -v go &>/dev/null; then
    echo "Go 没有安装，正在安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install go
    go version
else
    echo "Go 已经安装。"
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

function install_mineral() {
    curl -LO https://github.com/ronanyeah/mineral-app/releases/download/v1/macos.zip
    unzip macos.zip
    read -p "输入sui钱包私钥：" sui_key
    WALLET=$sui_key pm2 start --name miner ./mineral-macos -- mine
    echo "使用pm2 list查看进程"
}

function install_multiminer() {
    read -p "请输入含有sui私钥的txt文件路径（每行一个私钥）：" key_file
    function install_mineral() {
    curl -LO https://github.com/ronanyeah/mineral-app/releases/download/v1/macos.zip
    unzip macos.zip
    read -p "输入sui钱包私钥：" sui_key
    WALLET=$sui_key pm2 start --name miner ./mineral-macos -- mine
    echo "使用pm2 list查看进程"
}

function install_multiminer() {
    read -p "请输入含有sui私钥的txt文件路径（每行一个私钥）：" key_file
    if [ -f "$key_file" ]; then
        echo "私钥文件存在，正在读取..."
        while IFS= read -r sui_key
        do
            WALLET=$sui_key pm2 start --name ${sui_key:0:16} ./mineral-macos -- mine
        done < "$key_file"
        echo "使用pm2 list查看进程"
    else
        echo "私钥文件不存在。"
    fi
}


}