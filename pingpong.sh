if [ "$(id -u)" -ne 0 ]; then
    echo "必须以root用户权限运行此脚本；"
    echo "请使用sudo -i命令切换到root权限，然后以root用户权限运行此脚本。"
    exit 1
fi

# 安装pingpong
function install_pingpong() {
    #检查配置及安装环境
    sudo apt update
    sudo apt install screen
    # 检查 Docker 是否已安装
    if ! command -v docker &>/dev/null; then
        # 如果 Docker 未安装，则进行安装
        echo "未检测到 Docker，正在安装..."
        sudo apt-get install ca-certificates curl gnupg lsb-release

        # 添加 Docker 官方 GPG 密钥
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # 设置 Docker 仓库
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

        # 授权 Docker 文件
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update

        # 安装 Docker 最新版本
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
    else
        echo "Docker 已安装。"
    fi

    #输入device id
    read -p "请输入你的device id: " device_id
    deviceid="$device_id"

    #下载pingpong
    wget -O pingpong https://pingpong-build.s3.ap-southeast-1.amazonaws.com/linux/latest/PINGPONG

    if [ -f "./pingpong" ]; then
        chmod +x ./pingpong
        screen -dmS pingpong bash -c "./pingpong --key \"$deviceid\""
    else
        echo "pingpong下载失败"
    fi
    echo "节点启动成功，使用screen -r pingpong查看运行状态。"
}

function restart(){
    #输入device id
    read -p "请输入你的device id: " device_id
    deviceid="$device_id"
    if [ -f "./pingpong" ]; then
        chmod +x ./pingpong
        screen -dmS pingpong bash -c "./pingpong --key \"$deviceid\""
    else
        echo "pingpong下载失败"
    fi
    echo "节点启动成功，使用screen -r pingpong查看运行状态。"
}

function close(){
    screen -S pingpong -X quit
    echo "节点已关闭"
}

function watch(){
    screen -r pingpong
}

function menu(){
    clear
    echo "#############################################################"
    echo "# Pingpong一键安装脚本                                        #"
    echo "# 1. 安装Pingpong                                            #"
    echo "# 2. 重启Pingpong                                            #"
    echo "# 3. 关闭Pingpong                                            #"
    echo "# 4. 查看Pingpong运行窗口                                     #"
    read -p "请选择操作[1-4]:" num
    case "$num" in
    1)
        install_pingpong
        ;;
    2)
        restart
        ;;
    3)
        close
        ;;
    4)
        watch
        ;;
    *)
        echo "请输入正确数字 [1-4]"
        ;;
    esac
}

menu