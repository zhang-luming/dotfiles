# Dotfiles

使用 Git 和 GNU Stow 管理 Linux 用户配置及常用工具安装流程。

## 使用

在 Ubuntu 新机器上执行：

```bash
git clone https://github.com/zhang-luming/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

脚本会依次安装基础软件、Shell、Python、Node.js、开发和 Agents 工具，最后通过 Stow 部署配置。

当前管理的配置：

- `shell/`：Bash、Zsh、Powerlevel10k
- `ssh/`：SSH 公钥和 `authorized_keys`

## 更新配置

配置通过软链接使用，修改后提交并推送：

```bash
cd ~/.dotfiles
git add .
git commit -m "类型: 简短说明"
git push
```

例如：`feat: 添加 tmux 配置`。
