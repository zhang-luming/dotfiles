#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# 基础环境
# 安装后续步骤所需的系统级依赖；
# ==============================================================================
if [[ ! -r /etc/os-release ]]; then
  printf '[dotfiles] 错误: 找不到 /etc/os-release，无法识别系统\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != ubuntu ]]; then
  printf '[dotfiles] 错误: 当前脚本只支持 Ubuntu，检测到: %s\n' "${PRETTY_NAME:-${ID:-unknown}}" >&2
  exit 1
fi
printf '[dotfiles] 检测到 Ubuntu: %s\n' "${PRETTY_NAME:-$ID}"

if ! command -v apt-get >/dev/null 2>&1; then
  printf '[dotfiles] 错误: 找不到 apt-get\n' >&2
  exit 1
fi
if ! command -v timeout >/dev/null 2>&1; then
  printf '[dotfiles] 错误: 找不到 timeout（请安装 coreutils）\n' >&2
  exit 1
fi

if (( EUID == 0 )); then
  apt_command=(apt-get)
else
  if ! command -v sudo >/dev/null 2>&1; then
    printf '[dotfiles] 错误: 当前用户不是 root，且找不到 sudo\n' >&2
    exit 1
  fi
  apt_command=(sudo apt-get)
fi

printf '[dotfiles] 更新软件包索引\n'
timeout --foreground 15m "${apt_command[@]}" update
printf '[dotfiles] 安装基础软件: sudo git curl stow wget\n'
timeout --foreground 15m "${apt_command[@]}" install -y --no-install-recommends sudo git curl stow wget

# ==============================================================================
# Shell 环境、美化与插件
# ==============================================================================
printf '[dotfiles] 安装 Zsh\n'
timeout --foreground 10m "${apt_command[@]}" install -y zsh

# ==============================================================================
# 常用命令行工具
# ==============================================================================
printf '[dotfiles] 安装常用命令行工具\n'
timeout --foreground 15m "${apt_command[@]}" install -y \
  btop ffmpeg jq fzf zoxide resvg xclip 7zip fd-find ripgrep

oh_my_zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
if [[ -d "$oh_my_zsh_dir/.git" ]]; then
  printf '[dotfiles] Oh My Zsh 已安装，跳过\n'
elif [[ -e "$oh_my_zsh_dir" ]]; then
  printf '[dotfiles] 错误: %s 已存在但不是有效的 Oh My Zsh 仓库\n' "$oh_my_zsh_dir" >&2
  exit 1
else
  printf '[dotfiles] 安装 Oh My Zsh\n'
  timeout --foreground 10m bash -o pipefail -c \
    'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://install.ohmyz.sh/)"'
fi

zsh_custom_dir="${ZSH_CUSTOM:-$oh_my_zsh_dir/custom}"

if [[ ! -d "$zsh_custom_dir/themes/powerlevel10k/.git" ]]; then
  printf '[dotfiles] 安装 Powerlevel10k\n'
  timeout --foreground 10m git clone --depth=1 \
    https://github.com/romkatv/powerlevel10k.git \
    "$zsh_custom_dir/themes/powerlevel10k"
else
  printf '[dotfiles] Powerlevel10k 已安装，跳过\n'
fi

if [[ ! -d "$zsh_custom_dir/plugins/zsh-autosuggestions/.git" ]]; then
  printf '[dotfiles] 安装 zsh-autosuggestions\n'
  timeout --foreground 10m git clone --depth=1 \
    https://github.com/zsh-users/zsh-autosuggestions \
    "$zsh_custom_dir/plugins/zsh-autosuggestions"
else
  printf '[dotfiles] zsh-autosuggestions 已安装，跳过\n'
fi

if [[ ! -d "$zsh_custom_dir/plugins/zsh-syntax-highlighting/.git" ]]; then
  printf '[dotfiles] 安装 zsh-syntax-highlighting\n'
  timeout --foreground 10m git clone --depth=1 \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$zsh_custom_dir/plugins/zsh-syntax-highlighting"
else
  printf '[dotfiles] zsh-syntax-highlighting 已安装，跳过\n'
fi

printf '[dotfiles] 将默认登录 Shell 设置为 Zsh\n'
zsh_path="$(command -v zsh)"
if [[ "${SHELL:-}" != "$zsh_path" ]]; then
  if ! command -v chsh >/dev/null 2>&1; then
    printf '[dotfiles] 错误: 找不到 chsh，无法修改默认 Shell\n' >&2
    exit 1
  fi
  timeout --foreground 2m chsh -s "$zsh_path"
else
  printf '[dotfiles] 默认登录 Shell 已经是 Zsh，跳过\n'
fi

# ==============================================================================
# Python 工具链
# ==============================================================================
printf '[dotfiles] 安装 Python 工具链: uv\n'
timeout --foreground 5m bash -o pipefail -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

# ==============================================================================
# Node.js 工具链
# ==============================================================================
printf '[dotfiles] 安装 Node.js 版本管理器: NVM\n'
timeout --foreground 5m bash -o pipefail -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash'

# NVM 通过 shell 初始化文件提供命令，当前脚本需显式加载它。
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  printf '[dotfiles] 错误: NVM 安装后找不到 %s/nvm.sh\n' "$NVM_DIR" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$NVM_DIR/nvm.sh"
printf '[dotfiles] 安装 Node.js LTS\n'
timeout --foreground 15m bash -c '
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
'

# ==============================================================================
# 终端工具
# ==============================================================================
printf '[dotfiles] 安装 Yazi\n'
timeout --foreground 10m bash -c '"$HOME/.local/bin/uv" tool install yazi-bin'
printf '[dotfiles] 安装 Herdr\n'
timeout --foreground 10m bash -o pipefail -c \
  'curl -fsSL https://herdr.dev/install.sh | sh'

# ==============================================================================
# Nerd Fonts 字体（可选）
# 直接按回车跳过；输入字体名称，例如 JetBrainsMono 或 FiraCode。
# ==============================================================================
printf '\n[dotfiles] Nerd Fonts 字体安装是可选的。\n'
printf '[dotfiles] 输入字体名称后按回车安装，直接按回车跳过: '
read -r nerd_font_name
if [[ -n "$nerd_font_name" ]]; then
  printf '[dotfiles] 安装 Nerd Fonts: %s\n' "$nerd_font_name"
  timeout --foreground 5m bash -o pipefail -c \
    'curl -fsSL https://raw.githubusercontent.com/ronniedroid/getnf/main/install.sh | bash'
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v getnf >/dev/null 2>&1; then
    printf '[dotfiles] 错误: getnf 安装后不可用\n' >&2
    exit 1
  fi
  timeout --foreground 15m getnf install "$nerd_font_name"
else
  printf '[dotfiles] 跳过 Nerd Fonts 安装\n'
fi

# ==============================================================================
# Agents 工具链
# ==============================================================================
printf '[dotfiles] 安装 cc-switch-cli\n'
timeout --foreground 10m bash -o pipefail -c \
  'curl -fsSL https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh | bash'

printf '[dotfiles] 安装 OpenCode\n'
timeout --foreground 2m npm config set allow-scripts=opencode-ai --location=user
timeout --foreground 15m npm install --global opencode-ai

printf '[dotfiles] 安装 OpenAI Codex CLI\n'
timeout --foreground 15m npm install -g @openai/codex

printf '\n[dotfiles] 即将运行交互式 Skills 安装命令。\n'
printf '[dotfiles] 请按提示完成选择，准备好后按回车继续...\n'
read -r
printf '[dotfiles] 安装 Skills\n'
timeout --foreground 30m npx skills@latest add mattpocock/skills

# ==============================================================================
# 配置部署
# 将仓库中的配置通过软链接部署到当前用户家目录。
# ==============================================================================
printf '[dotfiles] 部署 Shell 和 SSH 配置\n'
cd "$repo_dir"

# 安装器可能生成普通配置文件；先备份冲突项，再交给 Stow 建立软链接。
backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
for config_path in \
  "$HOME/.bashrc" \
  "$HOME/.zshrc" \
  "$HOME/.p10k.zsh" \
  "$HOME/.ssh/config" \
  "$HOME/.ssh/id_rsa.pub" \
  "$HOME/.ssh/authorized_keys"; do
  if [[ -f "$config_path" && ! -L "$config_path" ]]; then
    mkdir -p "$backup_dir$(dirname "${config_path#$HOME}")"
    mv "$config_path" "$backup_dir${config_path#$HOME}"
    printf '[dotfiles] 已备份冲突文件: %s\n' "$config_path"
  fi
done

timeout --foreground 2m stow --target="$HOME" shell ssh

chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/config" "$HOME/.ssh/authorized_keys" 2>/dev/null || true
chmod 644 "$HOME/.ssh/id_rsa.pub" 2>/dev/null || true

printf '[dotfiles] 全部安装和配置完成\n'
