# Mac/Ubuntuに入れたい物

chezmoi,miseでこれらをインストールしてMac,Ubuntuで対応できるようにしたい。原則バイナリ配布されているものを使う

## Mac/Ubuntu共通

- Utils
  - chezmoi(install script)
  - mise(chezmoi)
  - tailscale(brew,apt)
  - ffmpeg(brew,apt)
- lang
  - rust(mise)
  - uv(mise)
- Embedded-development(いらない時が多いので、選択式にしたい。)
  - arm-none-eabi-gcc(brew,apt)
  - KiCAD(flatpak)
  - openocd(brew,apt)
  - ArduinoIDE(Flatpak版は嫌)
  - platformio()
- CLI
  - Zellij(chezemoi)
  - keifu(chezmoi or cargo)
  - fzf(chezemoi)
  - htop(brew,apt)
  - arp-scan(brew,apt)
- code agent
  - claude(npmじゃなくてシェルスクリプトのほうがいいかも)
  - codex(npmじゃなくてシェルスクリプトのほうがいいかも)
- GUI
  - zed(brew,apt)
  - vscode(brew,apt)
    - desktop起動オプションは`Exec=/usr/share/code/code --enable-features=UseOzonePlatform,Vulkan --ozone-platform=wayland %F`
  - Google Chrome(flatpak版は嫌)
    - `wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb`
    - `sudo apt install ./google-chrome-stable_current_amd64.deb`
  - zsh
    - zsh-autosuggestions
    - carapace
    - Powerlevel10k

## ubuntu

これは最初の方にできていないと、他に何が入っていようが意味がない。重要度高い。
- Input Utils
  - fcitx5(apt)
    - 現状の設定をchezmoiで管理する必要あり
  - fcitx5-mozc(apt)
  - [toshy](https://github.com/RedBearAK/Toshy)(git clone & shell script)
  - `toshy_config.py`を`~/.config/toshy/toshy_config.py`にコピーする必要がある
  - xremap(chezmoi)

- other
  - net-utils(apt)
  - can-utils(apt)
  - gnome-sushi(apt)
  - gnome-shell-extension-manager(apt)
  - flatpak(apt)
    - zen browser
  - .bashrc,.zshrc(chezmoi)
