いい感じにマウントできましたね！
「論文一覧の index を自動生成する」なら、段階別に3パターンあります。まずは**超お手軽ローカル版**から始め、必要になったら**Driveリンク自動付与**に拡張するのがおすすめです。

---

# 3段階のやり方

## A) ローカル走査だけ（最短・設定不要）

* `papers/` を再帰的にスキャン
* PDFのメタデータ（タイトル/著者/年）を取得（失敗時はファイル名）
* `index.csv` と `README.md` を生成
* Driveリンク欄は空欄（手動で列を埋めてもOK）

## B) 既知リンクをマージ（半自動）

* `drive_links.csv`（`relpath,webViewLink`）を別管理
* A)で生成した一覧にマージしてREADMEにも反映

## C) Google Drive APIでリンク自動付与（本格）

* `pydrive2` などで Drive のフォルダを列挙し、`webViewLink` を取得
* 一覧生成と同時にリンクを自動挿入
* ※初回だけ OAuth 同意/トークン保存が必要

---

# まずは動くやつ：A) ローカル版スクリプト

下記を `~/workspace/shared-drive/papers/make_paper_index.py` として保存してください。

```python
#!/usr/bin/env python3
import csv, os, sys, time, hashlib
from pathlib import Path

try:
    from PyPDF2 import PdfReader
except Exception:
    PdfReader = None  # メタデータ抽出はベストエフォート

PAPERS_DIR = Path(os.environ.get("PAPERS_DIR", str(Path.home() / "workspace/shared-drive/papers")))

OUT_CSV = PAPERS_DIR / "index.csv"
OUT_MD  = PAPERS_DIR / "README.md"

def pdf_meta(path: Path):
    title = authors = year = ""
    if PdfReader is None:
        return title, authors, year
    try:
        reader = PdfReader(str(path))
        info = reader.metadata or {}
        # PyPDF2 >= 3: keys like '/Title' は .metadata で 'title' 属性になることも
        title   = (getattr(info, "title", None) or info.get("/Title") or "").strip() if info else ""
        authors = (getattr(info, "author", None) or info.get("/Author") or "").strip() if info else ""
        # 年はCreationDateからざっくり
        cdate = (getattr(info, "creation_date", None) or info.get("/CreationDate") or "")
        if isinstance(cdate, str) and len(cdate) >= 6 and cdate.startswith("D:"):
            year = cdate[2:6]
    except Exception:
        pass
    return title or "", authors or "", year or ""

def human_size(n):
    for unit in ["B","KB","MB","GB","TB"]:
        if n < 1024.0:
            return f"{n:.1f}{unit}" if unit!="B" else f"{int(n)}{unit}"
        n /= 1024.0
    return f"{n:.1f}PB"

def main():
    if not PAPERS_DIR.exists():
        print(f"❌ PAPERS_DIR not found: {PAPERS_DIR}", file=sys.stderr)
        sys.exit(1)

    rows = []
    for p in PAPERS_DIR.rglob("*.pdf"):
        if any(part.startswith(".") for part in p.parts):
            continue
        rel = p.relative_to(PAPERS_DIR)
        stat = p.stat()
        title, authors, year = pdf_meta(p)
        if not title:
            title = p.stem.replace("_"," ").replace("-"," ").strip()
        rows.append({
            "title": title,
            "authors": authors,
            "year": year,
            "relpath": str(rel),
            "size": stat.st_size,
            "size_h": human_size(stat.st_size),
            "mtime": time.strftime("%Y-%m-%d", time.localtime(stat.st_mtime)),
            "drive_link": ""  # 後でB/Cで埋める
        })

    # ソート（年↓, タイトル）
    rows.sort(key=lambda r: (r["year"] or "0000", r["title"].lower()), reverse=True)

    # CSV出力
    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["title","authors","year","relpath","size","mtime","drive_link"])
        w.writeheader()
        for r in rows:
            w.writerow({
                "title": r["title"],
                "authors": r["authors"],
                "year": r["year"],
                "relpath": r["relpath"],
                "size": r["size"],
                "mtime": r["mtime"],
                "drive_link": r["drive_link"],
            })

    # README.md 出力（テーブル）
    with OUT_MD.open("w", encoding="utf-8") as f:
        f.write("# Papers Index\n\n")
        f.write(f"- Generated: {time.strftime('%Y-%m-%d %H:%M')}\n")
        f.write(f"- Root: `{PAPERS_DIR}`\n\n")
        f.write("| Title | Authors | Year | Size | Updated | Link |\n")
        f.write("|------|---------|------|------|---------|------|\n")
        for r in rows[:1000]:  # 表は最大1000行（必要なら調整）
            local_link = f"[{r['title']}]({r['relpath']})"
            drive_link = r["drive_link"] or ""
            link_cell  = f"[Drive]({drive_link})" if drive_link else ""
            f.write(f"| {local_link} | {r['authors']} | {r['year']} | {r['size_h']} | {r['mtime']} | {link_cell} |\n")

    print(f"✅ Wrote: {OUT_CSV}")
    print(f"✅ Wrote: {OUT_MD}")

if __name__ == "__main__":
    main()
```

### 実行

```bash
# 依存（任意）：PyPDF2 を入れると精度UP
pip install PyPDF2

python3 ~/workspace/shared-drive/papers/make_paper_index.py
```

* `index.csv` と `README.md` が `papers/` に生成されます（Driveリンク欄は空）。

---

# B) 既知リンクをマージ（半自動）

`papers/drive_links.csv` を用意（内容例）：

```csv
relpath,webViewLink
DeepLearning/Goodfellow2016.pdf,https://drive.google.com/file/d/FILE_ID/view
Flux/Observer2020.pdf,https://drive.google.com/file/d/FILE_ID/view
```

上のスクリプトを少し拡張して、`drive_links.csv` があれば `drive_link` 欄にマージするようにできます。必要なら改修版を出します。

---

# C) Drive API でリンク自動付与（本格）

1. Google Cloud でプロジェクト作成 → Drive API 有効化
2. OAuth クライアント（デスクトップ）を作成して `credentials.json` を `papers/` に配置
3. `pip install pydrive2`
4. スクリプト側で：

   * 「`Project/Workspace/papers` に対応する **フォルダID**」を一度だけ取得し、環境変数や `papers/.gdrive_folder_id` に保存
   * そのフォルダ配下のファイルを API で列挙→`webViewLink` を取得
   * `relpath` と名前で突合して自動で `drive_link` を埋める
   * 必要なら共有設定（Anyone with the link）を付与

> セットアップが長くなるので、**やる気になったら**私から「完全版テンプレ（pydrive2向け）」をお渡しします。

---

# 定期自動化（任意）

macOS の `launchd` で毎日自動更新。`~/Library/LaunchAgents/com.user.papers.index.plist` 例：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.user.papers.index</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/env</string>
    <string>python3</string>
    <string>/Users/sugusokothx/workspace/shared-drive/papers/make_paper_index.py</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Hour</key><integer>3</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>StandardOutPath</key><string>/Users/sugusokothx/workspace/shared-drive/papers/index.log</string>
  <key>StandardErrorPath</key><string>/Users/sugusokothx/workspace/shared-drive/papers/index.err</string>
</dict></plist>
```

読み込み：

```bash
launchctl load ~/Library/LaunchAgents/com.user.papers.index.plist
launchctl start com.user.papers.index
```

---

## まずは A) を入れて回す → B/C に拡張、がスムーズです。

次の一手として、**B) マージ方式**にしますか？それともいきなり **C) API 連携**まで進めますか？
