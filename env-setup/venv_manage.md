# Multi‑Project Python venv 管理ベストプラクティス（Workspace版）

このドキュメントは、`code/` ワークスペース配下で **複数の独立プロジェクト**（例：`src/backtester`, `src/kiyohara` など）を運用する際の **仮想環境（venv）管理ベストプラクティス**をまとめたものです。目的は、**依存の分離・再現性・運用性（VSCode/CI 含む）** を高いレベルで両立することです。

---

## 1. 目的・原則

* **プロジェクト単位の依存分離**：各プロジェクトは `src/<project>/.venv` を持つ。
* **最小権限の原則**：不要なパッケージを入れない（各プロジェクトは必要最低限）。
* **再現性**：固定バージョン・ロック／constraints 管理（`requirements.txt` or `pip-tools` or `uv`）。
* **可観測性**：`pip freeze` 出力や `pyproject.toml` をリポジトリに保持し、差分追跡。
* **秘密情報の分離**：`.env` と `.gitignore`、かつテンプレとして `.env.example` を配布。

---

## 2. ディレクトリ標準構成

```
code/
├── .gitignore
├── .env.example                  # 共有用テンプレ（キーは空文字）
├── document/
├── experiments/
├── scripts/
│   ├── start_dev.sh              # venv アクティベート補助
│   └── setup_venv.sh             # venv 作成＋初期化共通スクリプト
├── requirement.txt               # 共通ユーティリティ（任意）
└── src/
    ├── backtester/
    │   ├── .venv/                # ← 本プロジェクト専用
    │   ├── pyproject.toml        # or requirements*.txt
    │   ├── requirements.in       # （pip-tools 運用時）
    │   ├── requirements.txt      # ロック or エクスポート
    │   ├── .env                  # プロジェクト固有の環境変数（APIキー等）
    │   └── .vscode/
    │       ├── settings.json     # Python interpreter の明示
    │       ├── launch.json       # デバッグ設定
    │       └── tasks.json        # タスク（テスト/リンタ/ビルド）
    └── kiyohara/
        ├── .venv/
        ├── pyproject.toml
        ├── requirements.in
        ├── requirements.txt
        ├── .env
        └── .vscode/
```

**.gitignore（抜粋）**

```
# venv / secrets / caches
**/.venv/
**/.env
.env
__pycache__/
*.pyc
.ipynb_checkpoints/

# build artefacts
build/
dist/
*.egg-info/
```

**.env.example（例）**

```
# copy to .env and fill values
EDINET_API_KEY=
YF_PROXY=
```

> ポイント：`.env` はコミットしない。テンプレとして `.env.example` を配布し、各メンバが `.env` を作成する。

---

## 3. venv 作成・起動フロー（統一手順）

**共通スクリプト（`scripts/setup_venv.sh`）** を用意し、各プロジェクトで使い回す：

```bash
#!/usr/bin/env bash
set -euo pipefail
proj_dir=${1:?"Usage: setup_venv.sh <project_dir>"}
cd "$proj_dir"
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
# pip-tools 運用なら（任意）
# pip install pip-tools
# pip-compile -q requirements.in -o requirements.txt
# インストール
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
# or pyproject（uv/pipx/poetry など方針に合わせる）
```

**アクティベート補助（`scripts/start_dev.sh`）**：

```bash
#!/usr/bin/env bash
set -euo pipefail
proj=${1:-"src/backtester"}
cd "$(git rev-parse --show-toplevel)"/"$proj"
if [ ! -d .venv ]; then echo "No .venv. Run setup_venv.sh $proj"; exit 1; fi
source .venv/bin/activate
echo "Activated venv for $proj"
```

---

## 4. 依存管理の選択肢

### A) シンプル：`requirements.txt` 固定

* 各プロジェクトに `requirements.txt` を置き、**バージョンピン**（`package==x.y.z`）。
* 運用：更新は手動で bump → `pip install -r requirements.txt`。

### B) `pip-tools`（推奨：ロックと宣言の分離）

* `requirements.in` に上位パッケージだけを列挙、`pip-compile` で依存解決 → `requirements.txt` を生成。
* 例：

  ```
  # requirements.in（最低限の宣言）
  pandas>=2.2
  requests
  lxml
  yfinance
  python-dotenv
  ```

  ```bash
  pip install pip-tools
  pip-compile -o requirements.txt requirements.in
  pip-sync requirements.txt
  ```

### C) `pyproject.toml` ベース（uv / poetry 等）

* 近年は `uv`（超高速pip互換）や `poetry` により、再現性の高いロックをサポート。
* 例（`uv`）：

  ```bash
  pip install uv
  uv venv .venv
  uv pip compile pyproject.toml -o requirements.txt
  uv pip sync requirements.txt
  ```

> チーム標準は **B) pip-tools** を推奨（読みやすさと再現性のバランスが良い）。

---

## 5. VSCode 設定例（プロジェクト毎）

**`src/<project>/.vscode/settings.json`**

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/src/<project>/.venv/bin/python",
  "python.testing.pytestEnabled": true,
  "python.envFile": "${workspaceFolder}/src/<project>/.env",
  "terminal.integrated.env.osx": {"PYTHONUTF8": "1"}
}
```

**`launch.json`（デバッグ例）**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run CLI",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/src/<project>/cli.py",
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/src/<project>/.env"
    }
  ]
}
```

**`tasks.json`（品質チェック例）**

```json
{
  "version": "2.0.0",
  "tasks": [
    {"label": "lint", "type": "shell", "command": "ruff check ."},
    {"label": "format", "type": "shell", "command": "ruff format ."},
    {"label": "test", "type": "shell", "command": "pytest -q"}
  ]
}
```

> `ruff` を使う場合は `requirements.in` に `ruff` を追加。`flake8/black/isort` でも可。

---

## 6. ㊙️ 秘密情報（APIキー）管理

* 各プロジェクトに `.env` を置き、**`python-dotenv`** で読み込む：

  ```python
  from dotenv import load_dotenv
  load_dotenv()  # .env をロード
  ```
* `.env` は **コミットしない**。テンプレに `.env.example` を配置。
* 共通値がある場合：ルート `code/.env` も可。ただし優先はプロジェクトローカル。
* CI では **リポジトリシークレット**に設定し、環境変数として注入。

---

## 7. CI/CD の基本パターン（例：GitHub Actions）

```yaml
name: ci
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: src/backtester
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - name: Install deps
        run: |
          python -m venv .venv
          source .venv/bin/activate
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      - name: Run tests
        env:
          EDINET_API_KEY: ${{ secrets.EDINET_API_KEY }}
        run: |
          source .venv/bin/activate
          pytest -q
```

> 各プロジェクトごとに `defaults.run.working-directory` を切り替えるだけで流用可能。

---

## 8. 運用 Tips

* **Python バージョン固定**：`pyenv` で 3.12.x を明示、`.python-version` を各プロジェクトに置く。
* **キャッシュ**：CI では `~/.cache/pip` を `actions/cache` でキャッシュ（要 `requirements.txt` のハッシュキー）。
* **共通スクリプト**：`scripts/` に venv 作成・更新・テスト実行のヘルパを集約。
* **LTS と高速化**：`uv` に切替えるとインストールが高速化。大規模依存で効果大。
* **Windows/Mac/Linux 差異**：パス（`Scripts/python.exe` vs `bin/python`）に注意。`start_dev.sh` の OS 分岐で吸収可能。

---

## 9. 既存 `code/.venv` からの移行手順（安全版）

1. 現 `.venv` の freeze を保存：

   ```bash
   source code/.venv/bin/activate
   pip freeze > code/requirements_legacy.txt
   deactivate
   ```
2. `src/<project>/` 毎に `.venv` 作成＋必要パッケージを再インストール。
3. 動作確認後、`code/.venv` を削除。

---

## 10. トラブルシュート

* **ImportError / ModuleNotFoundError**：別プロジェクトの venv が有効のまま → 正しい `.venv` を再アクティベート。
* **VSCode が古い venv を掴む**：コマンドパレット「Python: Select Interpreter」で該当パスを選択。`.vscode/settings.json` を確認。
* **PATH が混線**：シェルを一度閉じる／新ターミナルで `start_dev.sh` から起動。

---

## 11. サンプル：EDINET 連携プロジェクト（`src/kiyohara`）

* `requirements.in`（pip-tools 前提）

  ```
  pandas>=2.2
  requests
  lxml
  yfinance
  python-dotenv
  ```
* `.env.example`

  ```
  EDINET_API_KEY=
  ```
* 取り込みコード（抜粋）

  ```python
  import os
  from dotenv import load_dotenv
  load_dotenv()
  API_KEY = os.getenv("EDINET_API_KEY")
  assert API_KEY, "Set EDINET_API_KEY in .env"
  ```

---

## 12. まとめ（推奨セット）

* `src/<project>/.venv` 方式で **プロジェクト毎に隔離**。
* 依存は **pip-tools（requirements.in → requirements.txt → pip-sync）** でロック。
* VSCode は **project-local interpreter** を `settings.json` で固定。
* 機密は **.env** に隔離（`.env.example` を配布）＋ CI 秘密変数。
* CI は **working-directory** を切替え、各プロジェクトを独立検証。

これにより、**衝突のない依存・高速なセットアップ・安全な秘密管理** を実現できます。



なるほど状況わかりました 👍
`requirements.txt` にはちゃんと `ipykernel` が入っているのに、.venv の中には入ってない、という状態ですね。

---

## 原因

`requirements.in → pip-compile → requirements.txt` まではできているけど、

> **新しい `requirements.txt` を .venv にインストールしていない**

ので、`.venv` 側にはまだ `ipykernel` が入っていません。

その証拠がこれですね：

```bash
(.venv) python -m pip show ipykernel
WARNING: Package(s) not found: ipykernel
```

---

## やること：.venv に再インストール

プロジェクトルート（`code` ディレクトリ）で `.venv` を有効化した状態で、もう一度 **pip-sync** してください。

```bash
cd /Users/sugusokothx/workspace/kensho-san/code

# すでに .venv が有効なら不要ですが一応
source .venv/bin/activate

# stock_japanese 配下の requirements.txt を同期
pip-sync stock_japanese/requirements.txt
```

終わったら、ちゃんと入ったか確認：

```bash
python -m pip show ipykernel
```

ここで `Name: ipykernel` が表示されればOKです。

---

## VSCode 側の確認ポイント

1. **Pythonインタプリタが .venv を指しているか**

   * `⌘⇧P` →「Python: Select Interpreter」
   * パスが
     `/Users/sugusokothx/workspace/kensho-san/code/.venv/bin/python`
     になっているものを選択。

2. **Notebook のカーネルも .venv を選ぶ**

   * `.ipynb` を開く
   * 右上のカーネル名をクリック
   * `.venv (3.13.7)` とか、さっき選んだインタプリタと同じものを選択

それでも「ipykernel が必要です」と出る場合は、そのノートブックが別の環境を見ている可能性が高いので、

ノートブック内から

```python
import sys
print(sys.executable)
```

を実行して、どの Python を見ているか確認してみてください。
ここが `.venv/bin/python` になっていればOKです。

---

## ここまでやれば…

* `ipykernel` が .venv にインストールされる
* VSCode から `.venv` カーネルを選べるようになる
* `.ipynb` のセルが普通に実行できる状態になります 💻

まずは

```bash
pip-sync stock_japanese/requirements.txt
python -m pip show ipykernel
```

までやってみて、結果を教えてもらえれば、次のトラブルシュートも一緒にできます。
