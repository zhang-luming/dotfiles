# ==============================================================================
# Powerlevel10k 即时提示符
# 请将此配置块放在 ~/.zshrc 的顶部附近。任何可能要求用户输入的初始化配置
# 都必须放在此配置块之前。
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# 基础环境配置
# ==============================================================================
# zsh 的 path 数组与 PATH 环境变量相互关联。-U 参数用于移除重复项，
# 即使某个工具的初始化脚本被多次加载，也能保持 PATH 简洁且无重复路径。
typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  /usr/local/bin
  $path
)

# ==============================================================================
# Oh My Zsh 配置
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

COMPLETION_WAITING_DOTS="true"

plugins=(
  z
  git
  extract
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ==============================================================================
# 命令别名与辅助函数
# ==============================================================================
alias zshconfig='vim ~/.zshrc'
# 启动一个全新的 shell 比反复执行 source ~/.zshrc 更安全：Oh My Zsh、
# Powerlevel10k 和补全系统的初始化配置通常只应在每个 shell 中执行一次。
alias ss='exec zsh'
alias cl='clear'

alias sud='sudo apt update'
alias sug='sudo apt upgrade'

# 加载当前的 colcon 工作空间，也可以通过第一个参数（$1）明确指定 setup 文件。
# 此处有意使用 setup.sh，使叠加工作空间仅更新环境变量，
# 而不会再次运行 zsh 的补全初始化。
sss() {
  local setup_file="${1:-./install/setup.sh}"

  if [[ ! -r "$setup_file" ]]; then
    print -u2 "sss: cannot read setup file: $setup_file"
    return 1
  fi

  AMENT_SHELL=sh source "$setup_file"
}

# 代理端口设置 传入ip与端口
proxy () {
    action=$1
    addr=$2

    if [ "$action" = "on" ]; then
        if [ -z "$addr" ]; then
            echo "Usage: proxy on <ip:port>"
            return 1
        fi

        proxy_url="http://$addr"

        export http_proxy=$proxy_url
        export https_proxy=$proxy_url
        export ftp_proxy=$proxy_url

        git config --global http.proxy $proxy_url
        git config --global https.proxy $proxy_url

        echo "Proxy enabled: $proxy_url"

    elif [ "$action" = "off" ]; then
        unset http_proxy
        unset https_proxy
        unset ftp_proxy

        git config --global --unset http.proxy
        git config --global --unset https.proxy

        echo "Proxy disabled"

    else
        echo "Usage:"
        echo "  proxy on <ip:port>"
        echo "  proxy off"
    fi
}

# ==============================================================================
# 机器人开发环境：Gazebo Classic 与 ROS 2 Humble
# ==============================================================================
export ROS_DOMAIN_ID=11
export ROS_LOCALHOST_ONLY=1
export RCUTILS_COLORIZED_OUTPUT=1

# Gazebo Classic 仅提供 setup.sh。由于该脚本会追加路径，
# 而不会自动移除所有重复项，因此在加载前进行条件检查。
if [[ -r /usr/share/gazebo/setup.sh &&
      ":${GAZEBO_RESOURCE_PATH:-}:" != *":/usr/share/gazebo-11:"* ]]; then
  source /usr/share/gazebo/setup.sh
fi

# 使用 POSIX shell 模式加载 ROS 环境。与 setup.zsh 相比，
# 该方式导出相同的 ROS 环境，但会跳过各软件包级别的 zsh 补全钩子，
# 避免它们反复调用 compinit 并相互覆盖已注册的补全配置。
if [[ -r /opt/ros/humble/setup.sh ]]; then
  AMENT_SHELL=sh source /opt/ros/humble/setup.sh
fi

# ==============================================================================
# Node.js 版本管理工具：NVM
# ==============================================================================
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# ==============================================================================
# 动态命令补全
# ==============================================================================
# Oh My Zsh 已经初始化了 zsh 原生补全系统。此处只启用一次 Bash 补全兼容层，
# 然后统一注册所有 Bash/argcomplete 补全集成，
# 本节之后的配置不应再次调用 compinit。
autoload -U +X bashcompinit && bashcompinit

_register_python_argcomplete() {
  local register_command command_name

  if (( $+commands[register-python-argcomplete3] )); then
    register_command=register-python-argcomplete3
  elif (( $+commands[register-python-argcomplete] )); then
    register_command=register-python-argcomplete
  else
    return 0
  fi

  for command_name in "$@"; do
    (( $+commands[$command_name] )) || continue
    eval "$(command "$register_command" "$command_name")"
  done
}

_register_python_argcomplete \
  ament_index \
  ros2 \
  rosidl \
  colcon
unfunction _register_python_argcomplete

[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"


# # 进入 HOME 目录（仅限交互式 shell 启动时）+ 启动时手动打开ros2 daemon
# if [ -n "$PS1" ] && [ "$PWD" != "$HOME" ] && [ -z "$BASHRC_ALREADY_RAN" ]; then
#   export BASHRC_ALREADY_RAN=1
#   cd ~
#   ros2 daemon start
# fi

# ==============================================================================
# Powerlevel10k 用户配置
# ==============================================================================
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
