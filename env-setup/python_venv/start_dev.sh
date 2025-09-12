#!/bin/bash
# このスクリプトは、プロジェクトの開発環境をセットアップします。

# --- 設定 ---
PYTHON_VERSION_FILE=".python-version"
VENV_DIR=".venv"
REQUIREMENTS_FILE="requirement.txt"

# --- 1. pyenvの存在確認 ---
if ! command -v pyenv &> /dev/null; then
    echo "エラー: pyenvがインストールされていません。setting_manual_Mac.mdに従ってインストールしてください。"
    exit 1
fi

# --- 2. Pythonのバージョン設定 ---
if [ ! -f "$PYTHON_VERSION_FILE" ]; then
    echo "エラー: $PYTHON_VERSION_FILE が見つかりません。"
    exit 1
fi

VERSION=$(cat $PYTHON_VERSION_FILE)
echo "Pythonバージョン $VERSION を準備しています..."

# pyenvで指定バージョンがインストールされているか確認し、なければインストール
if ! pyenv versions --bare | grep -q "^$VERSION$"; then
    echo "Python $VERSION が見つからないため、インストールします。"
    pyenv install $VERSION
fi

# このディレクトリでのバージョンを固定
pyenv local $VERSION

# --- 3. 仮想環境の作成 ---
echo "仮想環境を '$VENV_DIR' に作成しています..."
python -m venv $VENV_DIR

# --- 4. パッケージのインストール ---
echo "仮想環境を有効化し、$REQUIREMENTS_FILE からパッケージをインストールします..."
source $VENV_DIR/bin/activate
python -m pip install --upgrade pip
pip install -r $REQUIREMENTS_FILE

# --- 完了 ---
echo ""
echo "✅ 開発環境の準備ができました。"
echo "ターミナルで以下のコマンドを実行して、仮想環境を有効化してください:"
echo "source $VENV_DIR/bin/activate"
