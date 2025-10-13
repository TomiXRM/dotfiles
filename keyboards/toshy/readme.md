# Settings

1. install toshy
2. install flatpak
3. install chrome-gnome-shell
4. install Xremap (from flatpak)
5. move toshy_config.py into `~/.config/toshy/`


## install toshy

```shell
git clone https://github.com/RedBearAK/toshy.git  
cd toshy  
./setup_toshy.py
```

## install flatpak

```shell
sudo apt install flatpak
sudo apt install gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

## install chrome-gnome-shell

```shell
sudo apt install chrome-gnome-shell
```

## install Xremap
1. install cargo for Xremap
2. install Xremap

```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
cargo install xremap
```

## move toshy_config.py to `~/.config/toshy/`

