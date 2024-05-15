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

function install_ionet(){
    curl -L https://github.com/ionet-official/io_launch_binaries/raw/main/io_net_launch_binary_mac -o io_net_launch_binary_mac

    chmod +x io_net_launch_binary_mac

    read -p "请输入ionet的device_id: " device_id
    read -p "请输入ionet的user_id: " user_id
    read -p "请输入自定义的device_name（什么名称都行）: " device_name
    ./io_net_launch_binary_mac --device_id=${device_id} --user_id=${user_id} --operating_system="macOS" --usegpus=false --device_name=${device_name}
}

install_ionet