#!/bin/bash -l

# 节点安装功能
function install_node() {
    # 安装 Homebrew 包管理器（如果尚未安装）
    if ! command -v brew &>/dev/null; then
        echo "Homebrew 未安装。正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # 更新 Homebrew 并安装必要的软件包
    brew update
    brew install git screen bison gcc make go@1.20

    # 克隆仓库
    git clone https://github.com/quilibriumnetwork/ceremonyclient

    # 进入 ceremonyclient/node 目录
    cd
    cd ceremonyclient/node
    git switch release

    echo ====================================== 安装完成 =========================================
    main_menu

}
function start_mining() {
    cd
    cd ceremonyclient/node
    chmod +x release_autorun.sh
    screen -dmS Quili bash -c './release_autorun.sh'
    echo "=======================开始挖quil==============================="
}

function backup_set() {

    mkdir backup
    cp -r ~/ceremonyclient/node/.config/config.yml ./backup/quiconfig.txt
    cp -r ~/ceremonyclient/node/.config/keys.yml ./backup/quikeys.txt

    echo "=======================备份完成==============================="

}

# 主菜单
function main_menu() {
    clear
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 开挖quil"
    echo "3. 备份文件"
    read -p "请输入选项（1-3）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) start_mining ;;
    3) backup_set ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
