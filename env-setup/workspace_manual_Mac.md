了解しました！🙌
これまでの会話を踏まえて、**「workspace 作成と運用マニュアル」詳細ステップ版**をまとめます。
プロンプトとして AI に渡せるように、見出し＋手順ベースで整理しました。

---

# 📘 Workspace 作成と運用マニュアル（詳細版）

## 1. 事前準備

### 1.1 基本ソフトのインストール

* **Homebrew**

  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

  確認: `brew -v`

* **Git / GitHub CLI**

  ```bash
  brew install git gh
  ```

  確認: `git --version`, `gh --version`

* **pyenv**

  ```bash
  brew install pyenv
  ```

  `.zshrc` に追記:

  ```zsh
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  ```

* **VSCode**

  ```bash
  brew install --cask visual-studio-code
  ```

* **Google Drive デスクトップアプリ**（公式サイトからインストール）

---

## 2. ディレクトリ構成と初期化

### 2.1 workspace 基本構成

```bash
mkdir -p ~/workspace/{00_rules,99_memo-inbox,coding-tips,kaggle-challenges,kensho-san,motor-control,utils,shared-drive}
```

### 2.2 Google Drive との連携

例: GoogleDrive の `Project/Workspace` をリンク

```bash
ln -s ~/Library/CloudStorage/GoogleDrive-<アカウント>/マイドライブ/Project/Workspace ~/workspace/shared-drive
```

---

## 3. Git リポジトリ管理

### 3.1 mono repo 初期化

```bash
cd ~/workspace
git init
git remote add origin https://github.com/<user>/workspace-mono.git
```

### 3.2 公開/非公開の方針

* workspace-mono → private
* motor-control / coding-tips / utils → public
* サブモジュールとして登録

### 3.3 サブモジュール追加

```bash
git submodule add https://github.com/<user>/motor-control.git motor-control
git submodule add https://github.com/<user>/coding-tips.git coding-tips
git submodule add https://github.com/<user>/utils.git utils
```

### 3.4 .gitignore 標準設定

```txt
__pycache__/
venv/
.venv/
.DS_Store
```

---

## 4. Python 環境の運用

### 4.1 pyenv でバージョン固定

```bash
pyenv install 3.12.6
echo "3.12.6" > ~/.python-version
```

### 4.2 プロジェクトごとの venv 初期化スクリプト

`init_venv.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"
python -m venv venv
source venv/bin/activate
pip install --upgrade pip
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
elif [ -f ~/workspace/requirements_normal.txt ]; then
  pip install -r ~/workspace/requirements_normal.txt
fi
deactivate
```

使い方:

```bash
./init_venv.sh ~/workspace/motor-control/simulation
```

### 4.3 共通ユーティリティ環境（utils）

```bash
cd ~/workspace/utils
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
deactivate
```

---

## 5. VSCode の運用

### 5.1 .code-workspace 作成

例: `workspace.code-workspace`

```json
{
  "folders": [
    { "path": "motor-control" },
    { "path": "coding-tips" },
    { "path": "utils" },
    { "path": "99_memo-inbox" }
  ]
}
```

### 5.2 Python インタープリタ固定

各プロジェクトの `.vscode/settings.json`

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python"
}
```

---

## 6. 基本的な事務スクリプト（utils/bin）

### 6.1 論文インデックス更新

`utils/bin/make_paper_index`:

```bash
#!/usr/bin/env bash
UTILS="$HOME/workspace/utils"
source "$UTILS/.venv/bin/activate"
python "$UTILS/papers/make_paper_index.py" "$@"
deactivate
```

### 6.2 データセット同期

* `utils/datasets/sync_config.yml` で同期マップ定義
* `utils/bin/datasets_sync` に `rsync` スクリプト

### 6.3 バックアップ

`utils/bin/backup_workspace`:

```bash
#!/usr/bin/env bash
TS=$(date +"%Y%m%d_%H%M")
tar --exclude='.git' --exclude='*/venv' -czf ~/Backups/workspace_$TS.tar.gz -C ~ workspace
```

### 6.4 メモ整理

`utils/memos/organize_memos.py` + `utils/bin/memos_organize`

---

## 7. 資料・論文の管理

### 7.1 論文

* `shared-drive/papers` に格納
* `README.md` と `index.csv` を自動生成
* PyPDF2 + pandas でタイトル抽出

### 7.2 データセット

* `shared-drive/datasets` に格納
* 実体は `.gitignore`
* fetch / sync スクリプトで扱う

---

## 8. Git 運用の実務

### 8.1 サブモジュール更新フロー

```bash
cd coding-tips
git pull origin main
cd ..
git add coding-tips
git commit -m "Update coding-tips submodule pointer"
git push
```

### 8.2 クローンと初期化

```bash
git clone --recurse-submodules https://github.com/<user>/workspace-mono.git
```

---

## 9. 運用上のTips

* `.zshrc` には PATH 設定だけを入れる、alias は utils/bin に集約
* `brew bundle dump --describe` で Brewfile を保存 → 環境再現
* バックアップは `tar.gz` + Google Drive
* 機密情報（APIキーなど）は **絶対に public リポに含めない**

---

✅ このアウトラインをそのまま AI に渡せば、\*\*詳細な手順書（Markdown/HTML化も可）\*\*を生成可能です。

---

👉 仕上げとして、このマニュアルを \*\*Markdown 文書（README.md スタイル）\*\*にして出力する版を作りましょうか？
