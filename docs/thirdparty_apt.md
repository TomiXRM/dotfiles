# Third-party APT Sources (Ubuntu)

`packages/apt_thirdparty.txt` にあるパッケージは、標準リポジトリ外のため
先にリポジトリ追加が必要です。追加後に `run_once_12_apt_thirdparty.sh.tmpl`
を再実行してください。

## Tailscale
```bash
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"
if [ -z "$CODENAME" ]; then
  CODENAME="$(lsb_release -cs)"
fi

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg" \
  | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.tailscale-keyring.list" \
  | sudo tee /etc/apt/sources.list.d/tailscale.list

sudo apt update
sudo apt install -y tailscale
```

## Visual Studio Code
```bash
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null

cat << EOF | sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

sudo apt update
sudo apt install -y code
```

## Zed
公式のインストール手順に従う（APT が使える環境のみ）。
```bash
curl -fsSL https://zed.dev/install.sh | sh
```
