#!/bin/bash

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FCITX5_CONFIG_DIR="$HOME/.config/fcitx5"

echo -e "${GREEN}=== fcitx5設定適用スクリプト ===${NC}"

# fcitx5がインストールされているか確認
if ! command -v fcitx5 &> /dev/null; then
    echo -e "${RED}エラー: fcitx5がインストールされていません${NC}"
    echo "以下のコマンドでインストールしてください:"
    echo "  sudo apt install fcitx5 fcitx5-mozc fcitx5-config-qt"
    exit 1
fi

# fcitx5を停止
echo -e "${YELLOW}fcitx5を停止しています...${NC}"
pkill fcitx5 || true
sleep 1

# バックアップを作成
if [ -d "$FCITX5_CONFIG_DIR" ]; then
    BACKUP_DIR="$FCITX5_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}既存の設定をバックアップしています: $BACKUP_DIR${NC}"
    cp -r "$FCITX5_CONFIG_DIR" "$BACKUP_DIR"
fi

# 設定ディレクトリを作成
mkdir -p "$FCITX5_CONFIG_DIR/conf"

# 設定ファイルをコピー
echo -e "${GREEN}設定ファイルをコピーしています...${NC}"

if [ -f "$SCRIPT_DIR/config" ]; then
    cp "$SCRIPT_DIR/config" "$FCITX5_CONFIG_DIR/"
    echo "  ✓ config"
fi

if [ -f "$SCRIPT_DIR/profile" ]; then
    cp "$SCRIPT_DIR/profile" "$FCITX5_CONFIG_DIR/"
    echo "  ✓ profile"
fi

if [ -d "$SCRIPT_DIR/conf" ]; then
    cp -r "$SCRIPT_DIR/conf/"* "$FCITX5_CONFIG_DIR/conf/"
    echo "  ✓ conf/*"
fi

# 環境変数の設定を確認
echo -e "${YELLOW}環境変数の設定を確認しています...${NC}"
ENV_FILE="$HOME/.profile"
if ! grep -q "GTK_IM_MODULE=fcitx" "$ENV_FILE" 2>/dev/null; then
    echo -e "${YELLOW}環境変数を設定しますか? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cat >> "$ENV_FILE" << 'EOF'

# fcitx5 設定
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF
        echo -e "${GREEN}環境変数を ~/.profile に追加しました${NC}"
        echo -e "${YELLOW}注意: 変更を有効にするにはログアウトして再ログインしてください${NC}"
    fi
fi

# fcitx5を起動
echo -e "${GREEN}fcitx5を起動しています...${NC}"
fcitx5 -d &

echo -e "${GREEN}=== 設定の適用が完了しました ===${NC}"
echo ""
echo "次のステップ:"
echo "1. ログアウトして再ログインする（環境変数を追加した場合）"
echo "2. fcitx5設定ツールで確認: fcitx5-configtool"
echo "3. 問題がある場合は、バックアップから復元できます"
