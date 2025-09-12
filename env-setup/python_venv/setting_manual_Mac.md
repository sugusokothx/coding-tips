# 会社PC 初期セットアップ（Python + Obsidian / macOSネイティブ）

## 手順のゴール

* 全員が同じ Python バージョン（例：3.11.9）
* 既存の `requirements.txt`（社内テンプレ）でパッケージ統一
* Homebrew のみ使用

---

## 1) Homebrew と基本ツールを一括セットアップ

ターミナル（`Terminal.app` または `iTerm2`など）を開き、以下を丸ごと貼り付けて実行してください：

```bash
# ==== 0) Homebrew のインストール ====
# まだインストールしていない場合のみ実行
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ==== 1) 基本ツール ====
brew install git
brew install --cask visual-studio-code
brew install --cask obsidian
brew install --cask iterm2 # おすすめのターミナル

# ==== 2) pyenv ====
brew install pyenv

# pyenv の設定をシェルに追加
# （zsh を利用している場合）
echo '' >> ~/.zshrc
echo '# pyenv settings' >> ~/.zshrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# 設定を反映させるため、ターミナルを再起動してください
```

> **【重要】** ここで一度ターミナルを閉じて、**新しいターミナルウィンドウ**を開いてください。

---

## 2) Python を統一インストール（例：3.11.9）

新しいターミナルで以下を実行します。

```bash
# ==== 3) Python 統一バージョン ====
# バージョンはチームで決めた値に合わせて変更可
PYVER="3.11.9"
pyenv install $PYVER
pyenv global $PYVER
python --version

# ==== 4) pip を最新化 ====
python -m pip install --upgrade pip
```

---

## 3) 依存パッケージの一括導入（社内テンプレ使用）

> 既存の `requirements.txt` をネットワーク共有・リポジトリなどから取得してある前提です。
> 例として `~/dev/project/requirements.txt` に置いた場合：

```bash
# プロジェクトのディレクトリに移動
cd ~/dev/project

# パッケージをインストール
pip install -r requirements.txt
```

※ プロキシ環境がある場合は、必要に応じて `pip.conf` を設定してください（例）：

```bash
# ~/.config/pip/pip.conf を作成
# （ない場合はフォルダも作る）
mkdir -p ~/.config/pip
nano ~/.config/pip/pip.conf
```

`pip.conf` の例（必要な場合のみ）：

```ini
[global]
proxy = http://user:pass@proxy.example.com:8080
timeout = 60
```

---

## 4) VS Code 推奨拡張

VS Code を起動 → 拡張機能（Extensions）からインストール：

*   Python (Microsoft)
*   Pylance
*   Jupyter (必要な場合)
*   (任意) GitLens, Remote Repositories

または、ターミナルからコマンドでインストール：

```bash
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter
```

---

## 5) Obsidian

*   Obsidian を起動し、**チームで決めた共有 Vault**（OneDrive/SharePoint/社内ファイルサーバ等）を開く
*   プラグインやテーマはチーム標準に合わせて設定

---

# 運用メモ（チーム向け）

*   **Python バージョン固定**：全員が `pyenv global 3.11.9` のように同一に。将来上げるときは「全員同日切り替え」をルールに。
*   **パッケージ統一**：依存は必ず `requirements.txt` へ。追加時はPR・承認フローに。
*   **PATH/優先順位**：`pyenv` の shims 経由になるため、システムの Python との競合を避けられます。
*   **権限/プロキシ**：社内プロキシ下では pip の `proxy` 設定や証明書設定が必要な場合あり（上記参照）。
*   **トラブル時の確認**：
    *   `which python` で解決されているパスが `pyenv` の `shims` かを確認
    *   `pyenv versions` でインストール済み一覧、`pyenv global` で有効版を確認
    *   `pip debug -v` でインデックス解決や証明書周りを確認

---

# 付録：アンインストール/やり直し（必要時）

```bash
# pyenv 経由の Python を消す（例：3.11.9）
pyenv uninstall 3.11.9

# pyenv 自体をアンインストール
brew uninstall pyenv

# 各種ツールのアンインストール（必要時のみ）
brew uninstall --cask visual-studio-code
brew uninstall --cask obsidian
brew uninstall git
```
