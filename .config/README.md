# Setup

```sh
git init --bare $HOME/dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
dotfiles config --local status.showUntrackedFiles no

dotfiles update-index --skip-worktree .config/alacritty/local.yml
dotfiles update-index --skip-worktree .config/nvim/local.vim
```

Then source the shared shell config from your `.bashrc` / `.zshrc` (PATH and other
machine-specific settings stay in those local files):

```sh
. "$HOME/.config/shell/common"
```
