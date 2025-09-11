いいですね！これは **「自分専用のコマンドフォルダ」を作って、どこからでも呼べるようにする仕組み** のことです 👍

---

## 🔹 なぜやるのか

* 普段は `~/workspace/utils/papers/make_paper_index.sh` のように長いパスを打たないといけない
* `PATH` にそのフォルダを追加すれば、ただのコマンドみたいに呼べる

  ```bash
  make_paper_index.sh
  ```
* これは **Linux/macOS の標準的な習慣**で、開発者はよく `~/bin` を使っています

---

## 🔹 手順

### 1. フォルダを作る

```bash
mkdir -p ~/workspace/utils/bin
```

### 2. スクリプトを置く

たとえば `make_paper_index.sh` をここに移動：

```bash
mv ~/workspace/utils/papers/make_paper_index.sh ~/workspace/utils/bin/
```

### 3. 実行権限を付与

```bash
chmod +x ~/workspace/utils/bin/make_paper_index.sh
```

### 4. PATH に追加（.zshrc に追記）

```zsh
export PATH="$HOME/workspace/utils/bin:$PATH"
```

保存後に反映：

```bash
source ~/.zshrc
```

---

## 🔹 動作確認

```bash
which make_paper_index.sh
# → /Users/sugusokothx/workspace/utils/bin/make_paper_index.sh

make_paper_index.sh
# 論文インデックス更新スクリプトが実行される
```

---

## 🔹 メリット

* どこからでも一発で呼べる（`cd` しなくていい）
* Git で管理できる（`utils/bin` はそのままリポジトリに含められる）
* 他の人に渡すときも「PATH を通すだけ」で同じ環境が再現できる

---

## 🔹 応用

* `utils/bin` に複数の小スクリプトを置けば、全部コマンド化できる

  * `make_paper_index.sh`
  * `sync_datasets.sh`
  * `backup_workspace.sh`
* これで「自分だけの小さいツール集」が出来上がる

---

✅ まとめ

* **`utils/bin` = 自作コマンド置き場**
* `.zshrc` に `PATH` を通すと「普通のコマンド」として呼び出せる
* 再利用性・管理性が高まる

---

👉 ここで質問ですが、`utils/bin` に置くスクリプトは「論文インデックス生成」だけで十分ですか？
それとも「datasetsの同期」「バックアップ」なども将来入れていくイメージですか？




いいですね！将来拡張もしやすい形で、**`utils/bin` に小さなコマンド群**を置く運用を提案します。まずは「雛形＋すぐ動く最小実装」を用意します。

---

# 置き場所の全体像（提案）

```
~/workspace/utils/
├── .venv/                   # 共通ユーティリティ用 venv
├── requirements.txt         # utils 用ライブラリ
├── bin/                     # ← PATH を通す（小さな実行スクリプト置き場）
│   ├── make_paper_index     # 論文インデックス更新（既存の.pyを呼ぶだけ）
│   ├── datasets_sync        # データセット同期（設定駆動）
│   ├── backup_workspace     # ワークスペース丸ごとバックアップ
│   └── memos_organize       # メモの自動整理（INBOX→日付フォルダなど）
├── papers/
│   └── make_paper_index.py  # 以前のスクリプト
├── datasets/
│   └── sync_config.yml      # 同期マップ設定（ローカル↔Drive どこをどう同期するか）
└── memos/
    └── organize_memos.py    # メモ整理の中身（最小ロジック）
```

> `.zshrc` に `export PATH="$HOME/workspace/utils/bin:$PATH"` を追加し、`source ~/.zshrc` を忘れずに。

---

# 1) utils/requirements.txt（追加）

共通ツール用に、YAML と進捗表示を追加推奨：

```txt
PyPDF2
pandas
tabulate
tqdm
PyYAML
```

> 初回（1回だけ）:
>
> ```bash
> cd ~/workspace/utils
> python -m venv .venv
> source .venv/bin/activate
> pip install --upgrade pip
> pip install -r requirements.txt
> deactivate
> ```

---

# 2) bin/make\_paper\_index（論文インデックス更新）

```bash
#!/usr/bin/env bash
set -euo pipefail
UTILS="$HOME/workspace/utils"
source "$UTILS/.venv/bin/activate"
python "$UTILS/papers/make_paper_index.py" "$@"
deactivate
```

---

# 3) datasets/sync\_config.yml（設定で同期マップ化）

「どこから→どこへ」をここで列挙します。
**Drive 側は `~/workspace/shared-drive/datasets` を指す前提**（シンボリックリンク済み）：

```yaml
# 例: ローカルにほしいデータセットたち
pull:
  - name: house-prices
    from:  ~/workspace/shared-drive/datasets/house-prices
    to:    ~/workspace/kaggle-challenges/house-prices/data
    exclude:
      - "*.tmp"
      - ".ipynb_checkpoints/"

  - name: drw-crypto
    from:  ~/workspace/shared-drive/datasets/drw-crypto
    to:    ~/workspace/kaggle-challenges/drw-crypto/data

# 例: 検証ログを Drive にアップロード
push:
  - name: kensho-logs
    from:  ~/workspace/kensho-san/experiments/logs
    to:    ~/workspace/shared-drive/archive/kensho-logs
    exclude:
      - "*.png"
```

---

# 4) bin/datasets\_sync（設定駆動で rsync）

```bash
#!/usr/bin/env bash
set -euo pipefail
UTILS="$HOME/workspace/utils"
CFG="$UTILS/datasets/sync_config.yml"

if [ ! -f "$CFG" ]; then
  echo "❌ config not found: $CFG"; exit 1
fi

source "$UTILS/.venv/bin/activate"
python - "$CFG" <<'PY'
import sys, os, subprocess, yaml
from pathlib import Path

cfg_path = Path(sys.argv[1]).expanduser()
cfg = yaml.safe_load(cfg_path.read_text(encoding="utf-8")) or {}
def _rsync(src, dst, excludes=(), direction="pull"):
    src = os.path.expanduser(src)
    dst = os.path.expanduser(dst)
    Path(dst).mkdir(parents=True, exist_ok=True)
    cmd = ["rsync","-avh","--progress","--delete"]
    for ex in excludes or []:
        cmd += ["--exclude", ex]
    if direction=="pull":
        cmd += [f"{src}/", f"{dst}/"]
    else:
        cmd += [f"{src}/", f"{dst}/"]
    print("🔄", " ".join(cmd))
    subprocess.check_call(cmd)

for item in (cfg.get("pull") or []):
    print(f"\n⬇️  PULL: {item.get('name','')}")
    _rsync(item["from"], item["to"], item.get("exclude"), "pull")

for item in (cfg.get("push") or []):
    print(f"\n⬆️  PUSH: {item.get('name','')}")
    _rsync(item["from"], item["to"], item.get("exclude"), "push")
PY
deactivate
```

> `rsync` を使うので差分だけ同期・進捗も見やすいです。
> 実行: `datasets_sync`

---

# 5) bin/backup\_workspace（丸ごとバックアップ・除外付き）

```bash
#!/usr/bin/env bash
set -euo pipefail
# 出力: ~/Backups/workspace_YYYYmmdd_HHMM.tar.gz
TS=$(date +"%Y%m%d_%H%M")
DEST="$HOME/Backups"
ARCH="$DEST/workspace_$TS.tar.gz"
SRC="$HOME/workspace"

mkdir -p "$DEST"

tar --exclude='.git' \
    --exclude='*/.git' \
    --exclude='*/node_modules' \
    --exclude='*/__pycache__' \
    --exclude='*/venv' \
    --exclude='*/.venv' \
    --exclude='shared-drive' \
    --exclude='.DS_Store' \
    -czf "$ARCH" -C "$HOME" workspace

echo "✅ Backup created: $ARCH"

# 任意: 直近5つだけ残し、それ以外は削除
ls -1t "$DEST"/workspace_*.tar.gz | tail -n +6 | xargs -I{} rm -f "{}" || true
```

> 実行: `backup_workspace`
> `shared-drive` はクラウド実体なので **除外**（巨大化防止）。

---

# 6) memos/organize\_memos.py（INBOX→日付フォルダに移動・簡易タグ付け）

最小ロジック：`99_memo-inbox/inbox/*.md` を **`indexed/YYYY/MM/`** へ移動。
先頭に YAML front matter を足して `tags` を追加（#hashtag を抽出）。

```python
#!/usr/bin/env python3
import re, shutil, sys, time
from pathlib import Path

ROOT = Path.home() / "workspace" / "99_memo-inbox"
INBOX = ROOT / "inbox"
OUTROOT = ROOT / "indexed"
TAGDIR = ROOT / "tags"

def extract_tags(text):
    return sorted(set(re.findall(r"#([A-Za-z0-9_\-ぁ-んァ-ヶ一-龥]+)", text)))

def ensure_front_matter(text, tags):
    fm = "---\n" + "tags: [" + ", ".join(tags) + "]\n" + "---\n"
    if text.lstrip().startswith("---"):
        # 既存front matterがある場合は上書きしない（簡易）
        return text
    return fm + "\n" + text

def main():
    INBOX.mkdir(parents=True, exist_ok=True)
    OUTROOT.mkdir(parents=True, exist_ok=True)
    moved = 0
    for src in INBOX.glob("*.md"):
        y = time.strftime("%Y")
        m = time.strftime("%m")
        dst_dir = OUTROOT / y / m
        dst_dir.mkdir(parents=True, exist_ok=True)
        text = src.read_text(encoding="utf-8")
        tags = extract_tags(text)
        new_text = ensure_front_matter(text, tags)
        dst = dst_dir / src.name
        dst.write_text(new_text, encoding="utf-8")
        src.unlink()
        moved += 1
    print(f"✅ moved {moved} notes.")
    TAGDIR.mkdir(parents=True, exist_ok=True)
    # 簡易: タグインデックスの雛形だけ作る
    (TAGDIR / "README.md").write_text("# Tags\n\n(Autogenerated placeholder)\n", encoding="utf-8")

if __name__ == "__main__":
    main()
```

---

# 7) bin/memos\_organize（上の Python を呼ぶだけ）

```bash
#!/usr/bin/env bash
set -euo pipefail
UTILS="$HOME/workspace/utils"
source "$UTILS/.venv/bin/activate"
python "$UTILS/memos/organize_memos.py" "$@"
deactivate
```

---

# 8) 最後に：権限付与と PATH

```bash
chmod +x ~/workspace/utils/bin/*
# まだなら PATH 追記
# echo 'export PATH="$HOME/workspace/utils/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

---

## 使い方まとめ

* 論文インデックス：`make_paper_index`
* データセット同期：`datasets_sync`
* バックアップ：`backup_workspace`
* メモ整理：`memos_organize`

必要に応じて、中の\*.pyや設定ファイルだけ差し替えれば、**運用コマンド名は変えずにロジックだけ改善**できます。
もっと高度な機能（例えば Drive API を使って `webViewLink` を自動付与 / Obsidian用のタグ索引を本格生成 など）も、この骨格に差し込めます。
