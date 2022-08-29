# Setup

```sh
git init --bare $HOME/dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME' (add this alias to .bashrc)
dotfiles config --local status.showUntrackedFiles no

dotfiles update-index --skip-worktree .config/alacritty/local.yml
```
