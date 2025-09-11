了解です 👍
では **`~/workspace/utils`** を「共通ユーティリティ置き場」として設計しましょう。ここに **共通 venv** と **論文・データセット系スクリプト**をまとめて管理する流れです。

---

## 🔹 ディレクトリ構成イメージ

```
workspace/
├── utils/                # 共通ユーティリティ
│   ├── .venv/            # 共通仮想環境 (utils専用)
│   ├── requirements.txt  # 共通ライブラリ（PyPDF2など）
│   ├── papers/           # 論文関連ツール
│   │   └── make_paper_index.py
│   ├── datasets/         # データセット管理ツール
│   └── README.md         # ユーティリティ説明
```

---

## 🔹 セットアップ（初回だけ）

```bash
# utilsフォルダを作成
mkdir -p ~/workspace/utils/{papers,datasets}

# venv作成
cd ~/workspace/utils
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip

# 共通ライブラリ requirements.txt を作る
cat > requirements.txt <<'REQ'
PyPDF2
pandas
tabulate
tqdm
# 将来Drive APIを使うなら下も追加
# pydrive2
# google-api-python-client
# google-auth
# google-auth-oauthlib
REQ

# インストール
pip install -r requirements.txt
deactivate
```

---

## 🔹 実行の流れ（毎回）

```bash
cd ~/workspace/utils
source .venv/bin/activate
python papers/make_paper_index.py
deactivate
```

---

## 🔹 便利な alias （.zshrc に追加）

```bash
# 共通ユーティリティ用 venv を有効化
alias workon-utils='source ~/workspace/utils/.venv/bin/activate'

# 共通ユーティリティ環境でPythonスクリプトを実行
utilpy () {
  source ~/workspace/utils/.venv/bin/activate
  python "$@"
  deactivate
}
```

使い方：

```bash
utilpy ~/workspace/utils/papers/make_paper_index.py
```

---

## 🔹 VSCode での活用

* `~/workspace/utils/.vscode/settings.json` を作って interpreter を固定すると、
  VSCode で開いたときに自動で `.venv` を使うようになります。

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
}
```

---

✅ まとめ

* **共通ツールは `~/workspace/utils` に集約**
* **venv は `utils/.venv` としてそこに固定**
* **requirements.txt で再現性確保**
* 実行は `workon-utils` or `utilpy` で一発

---

👉 ここにまずは **論文インデックス生成スクリプト**を移して整備しますか？
それとも **datasets 用の fetch スクリプトの枠組み**も一緒に作っちゃいますか？
