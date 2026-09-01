# Dotfiles

使用 GNU Stow 和 Git 管理的 Linux 用户配置。

## 目录结构

- `shell/`：Bash、Zsh 和 Powerlevel10k 配置，对应 `~/.bashrc`、`~/.zshrc` 和 `~/.p10k.zsh`
- `ssh/`：SSH 客户端配置、公钥和授权公钥，对应 `~/.ssh/`
- `install.sh`：将仓库中的配置部署到当前用户的家目录

私钥、`known_hosts` 以及其他机器相关或敏感文件不会纳入仓库。

## 新机器部署

```bash
git clone https://github.com/zhang-luming/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

## 日常使用

在仓库目录中预览 Stow 将执行的操作：

```bash
cd ~/.dotfiles
stow -n -v --target="$HOME" shell ssh
```

在任意目录中部署：

```bash
stow --dir="$HOME/.dotfiles" --target="$HOME" shell ssh
```

取消部署：

```bash
stow --dir="$HOME/.dotfiles" --target="$HOME" --delete shell ssh
```

修改配置后提交：

```bash
cd ~/.dotfiles
git add .
git commit -m "更新用户配置"
```

提交信息遵循 Conventional Commits 格式：

```text
<类型>: <简短说明>
```

常用类型包括：

- `feat`：新增配置或功能
- `fix`：修复配置问题
- `refactor`：调整目录或配置结构，不改变功能
- `docs`：只修改文档
- `chore`：仓库维护、依赖或工具调整

例如：`feat: 添加 tmux 配置`、`fix: 修正 SSH 主机别名`。

## SSH 安全说明

仓库只管理以下 SSH 文件：

- `~/.ssh/config`
- `~/.ssh/id_rsa.pub`
- `~/.ssh/authorized_keys`

不要将 `id_rsa`、`id_ed25519` 等私钥提交到 Git 仓库。部署脚本会为 `.ssh` 目录及相关文件设置合适的权限。
