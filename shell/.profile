export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"
. "$HOME/.cargo/env"

# Reuse a single ssh-agent across logins via a fixed socket
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
if ! ssh-add -l >/dev/null 2>&1; then
  rm -f "$SSH_AUTH_SOCK"
  ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
  ssh-add -q ~/.ssh/github
fi
export PATH="$HOME/.local/bin:$PATH"
