# dotfiles

Dotfiles pessoais para uma única máquina: **Void Linux + niri + Noctalia v5**
(ThinkPad P15 Gen 1). Gerenciados com **GNU Stow** — cada diretório aqui é um
"pacote" Stow cuja árvore espelha caminhos a partir de `$HOME`.

## Estrutura

| Pacote Stow | Conteúdo |
|-------------|----------|
| `niri/` | `~/.config/niri` — compositor (binds, window-rules, `gpu-mode.kdl`, `noctalia.kdl`) |
| `noctalia/` | `~/.config/noctalia` — shell v5 (`config.toml`) |
| `alacritty/` | `~/.config/alacritty` — terminal + tema osaka |
| `nvim/` | `~/.config/nvim` — LazyVim |
| `gtk/`, `fontconfig/`, `pipewire/` | configs de GTK 3/4, fontes (Iosevka Nerd Font) e áudio |
| `shell/` | `~/.profile` (PATH, Flatpak exports, ssh-agent fixo) |
| `scripts/` | `~/.local/bin` — `gpu-mode`, `niri-session-services`, `brave-intel`, `unimatrix` |
| `applications/` | `~/.local/share/applications` — entradas .desktop (Brave, wiremix, yazi) |
| `dconf/` | export de `/org/gnome/desktop/interface/` (tema GTK) |
| `snapshots/` | estado do Noctalia (`settings.toml` da barra) restaurado pelo install.sh |
| `packages/` | lista de pacotes XBPS instalados manualmente + flatpaks |

## Instalação (máquina nova)

Este repo é instalado **automaticamente** pelo script
`install-niri-noctalia-secure.sh` do repositório
[voidinstall](https://github.com/vitoraalmeida/voidinstall): ele clona o repo,
instala stow + todos os pacotes de `packages/xbps-manual.txt`, os flatpaks de
`packages/flatpak-apps.txt`, copia os wallpapers para
`~/Pictures/Wallpapers` e roda este `install.sh` no final (aplicando as
configs pessoais por cima das geradas).

Manualmente, o fluxo é:

```sh
sudo xbps-install -Sy stow
git clone https://github.com/vitoraalmeida/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### O que o `install.sh` faz

1. Move qualquer config existente para `~/dotfiles-pre-stow-<data>/` (backup —
   não apague até validar a sessão)
2. Aplica todos os pacotes com `stow --restow` (cria symlinks em `$HOME`)
3. Restaura `~/.local/state/noctalia/settings.toml` (layout da barra) a partir
   de `snapshots/noctalia-state/`
4. Recarrega `dconf/gnome-interface.ini`, atualiza cache de fontes
5. Valida com `niri validate` e `fc-match monospace`

### O que o `update.sh` faz (salvar o estado atual)

Sincroniza **do sistema para o repo**: configs do `$HOME` → pacotes Stow,
lista de pacotes XBPS (`xbps-query -m`), flatpaks, dump dconf e o estado da
barra do Noctalia. Copia com `find -L` + `cp -aL` para **desreferenciar** os
symlinks do Stow — sem isso, o repo seria corrompido com links
autorreferenciais (bug que já ocorreu).

```sh
./update.sh
```

## Ciclo de manutenção

```sh
# editar configs ao vivo (os symlinks apontam para cá), depois:
./update.sh
git add -A && git commit -m "descrição" && git push

# voltar para um estado anterior:
git log --oneline
git reset --hard <hash>      # repo inteiro
git checkout <hash> -- caminho/arquivo   # só um arquivo
./install.sh                 # reaplica ao $HOME
```

## Específico desta máquina

- **`niri/.config/niri/gpu-mode.kdl`**: fixa o render device (Intel
  `pci-0000:00:02.0`, dGPU NVIDIA `01:00.0` ignorada). Alternativas em
  `gpu-modes/` (`hdmi.kdl`, `vfio.kdl`), trocadas pelo script `gpu-mode` em
  `~/.local/bin`. Noutra GPU, regenerar.
- **Fonte**: Iosevka Nerd Font (alacritty, noctalia, fontconfig). O script do
  voidinstall instala; manualmente: baixar `Iosevka.zip` de
  https://github.com/ryanoasis/nerd-fonts/releases e extrair em
  `~/.local/share/fonts/IosevkaNerdFont` + `fc-cache -f`.
- **`niri-session-services`**: terminava com `noctalia msg templates-apply`
  na versão original, mas foi removido de propósito — os templates do Noctalia
  escreveriam nos configs GTK/Alacritty, que são symlinks do Stow, alterando o
  repo por trás. Os temas vêm versionados aqui (`gtk/`, `alacritty/`).
- **Wallpapers** (`osaka-jade-bg*.jpg` na raiz): referenciados por
  `snapshots/noctalia-state/settings.toml` em `~/Pictures/Wallpapers`.
