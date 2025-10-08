素晴らしい判断です。
`requirements.in` ベースにすることで依存関係の固定と更新が容易になります。以下の構成を推奨します。

---

### 📘 `code/src/kiyohara/requirements.in`

```txt
# Core data processing
pandas>=2.2
numpy>=1.26

# HTTP / API communication
requests
python-dotenv

# XBRL / XML parsing
lxml
beautifulsoup4

# Market data supplement
yfinance

# Excel / CSV export
openpyxl
tqdm

# Development tools
black
ruff
pytest
```

---

### 🔧 pip-tools 運用手順

```bash
cd code/src/kiyohara
source .venv/bin/activate
pip install pip-tools
pip-compile -o requirements.txt requirements.in
pip-sync requirements.txt
```

この構成により、

* `requirements.in` は上位パッケージのみ明示（読みやすい）
* `requirements.txt` は自動生成され、全依存がバージョン固定されます

---

### 💡補足

* pandas/lxml/beautifulsoup4 は EDINET の XBRL構造に対応
* requests + dotenv は EDINET API 認証＋環境変数読み込み
* yfinance は MarketCap 等の補完用
* tqdm は進捗表示、black/ruff/pytest は開発品質用

---

