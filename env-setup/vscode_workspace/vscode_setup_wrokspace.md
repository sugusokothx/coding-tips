
いいですね！VS Code の **`.code-workspace` は “複数フォルダを1つのウィンドウで扱うための設定ファイル”** です。
これを使うと、`motor-control/` や `kaggle-challenges/` などを**同一ウィンドウに並べて**、検索・設定・拡張機能の推奨・タスクを“workspace単位”でまとめられます。

---

# できること（要点）

* **複数フォルダを1ウィンドウ**に（マルチルート）
* **共通設定**（検索除外・フォーマッタなど）を一括適用
* **拡張機能の推奨**を表示（初回に入れるべき拡張が分かる）
* **タスクやデバッグ設定**を workspace に同梱（例：特定フォルダで pytest / cargo run など）

> フォルダごとの細かい設定は、各フォルダの `.vscode/settings.json` で上書きできます。

---

# すぐ使えるテンプレ（あなたの構成向け）

## 1) ファイル生成コマンド

ターミナルで以下を実行してください（ホーム直下 `~/workspace` に作成）：

```bash
cat > ~/workspace/DevWorkspace.code-workspace <<'JSON'
{
  "folders": [
    { "path": "motor-control" },
    { "path": "coding-tips" },
    { "path": "kaggle-challenges" },
    { "path": "kensho-san" },
    { "path": "memo-inbox" },
    { "path": "shared-drive" }
  ],
  "settings": {
    // 検索・ウォッチの負荷を軽減（大容量や生成物を除外）
    "search.exclude": {
      "**/.git": true,
      "**/.venv": true,
      "**/__pycache__": true,
      "shared-drive/datasets/**": true,
      "shared-drive/archive/**": true,
      "motor-control/papers/**": true,
      "shared-drive/papers/**": true
    },
    "files.watcherExclude": {
      "**/.git/**": true,
      "**/.venv/**": true,
      "**/__pycache__/**": true,
      "shared-drive/datasets/**": true,
      "shared-drive/archive/**": true
    },

    // エディタ快適化
    "editor.formatOnSave": true,
    "editor.tabSize": 2,
    "editor.rulers": [100],
    "files.trimTrailingWhitespace": true,
    "explorer.compactFolders": false,

    // Python 推奨（必要なければ後で削除OK）
    "python.defaultInterpreterPath": "python3",
    "python.analysis.autoImportCompletions": true,

    // Rust 推奨
    "rust-analyzer.checkOnSave.command": "clippy",

    // Markdown（Obsidianノートの見やすさ向上）
    "markdown.preview.breaks": true,

    // Terminal：デフォルトはワークスペースルート
    "terminal.integrated.cwd": "${workspaceFolder}"
  },

  // 初回に入れておきたい拡張（VS Code がサイドに通知）
  "extensions": {
    "recommendations": [
      "ms-python.python",
      "ms-toolsai.jupyter",
      "charliermarsh.ruff",
      "rust-lang.rust-analyzer",
      "vadimcn.vscode-lldb",
      "mhutchie.git-graph",
      "makorogan.view-in-browser"
    ]
  },

  // よく使うタスク例（コマンドパレット → “Tasks: Run Task”）
  "tasks": {
    "version": "2.0.0",
    "tasks": [
      {
        "label": "Open: Motor Control (new window)",
        "type": "shell",
        "command": "code -n ${workspaceFolder:motor-control}"
      },
      {
        "label": "MotorControl: pytest (simulation)",
        "type": "shell",
        "options": { "cwd": "${workspaceFolder:motor-control}/simulation" },
        "command": "pytest -q",
        "problemMatcher": []
      },
      {
        "label": "Kaggle: Jupyter (journal)",
        "type": "shell",
        "options": { "cwd": "${workspaceFolder:kaggle-challenges}/journal" },
        "command": "jupyter lab",
        "problemMatcher": []
      },
      {
        "label": "Tips: Python snippet run",
        "type": "shell",
        "options": { "cwd": "${workspaceFolder:coding-tips}/python" },
        "command": "python3 main.py",
        "problemMatcher": []
      }
    ]
  },

  // デバッグの例（必要なら後で各プロジェクトに移動可）
  "launch": {
    "version": "0.2.0",
    "configurations": [
      {
        "name": "Python: motor-control/simulation main.py",
        "type": "python",
        "request": "launch",
        "program": "${workspaceFolder:motor-control}/simulation/main.py",
        "console": "integratedTerminal"
      },
      {
        "name": "Rust: kensho-san run",
        "type": "lldb",
        "request": "launch",
        "program": "${workspaceFolder:kensho-san}/target/debug/kensho-san",
        "cwd": "${workspaceFolder:kensho-san}",
        "preLaunchTask": "cargo build",
        "args": []
      }
    ],
    "compounds": []
  }
}
JSON
```

## 2) 開く

```bash
code ~/workspace/DevWorkspace.code-workspace
```

これで VS Code が “複数フォルダを左側に並べた状態”で開きます。
以後は **この `.code-workspace` を起点**に開くと、共通設定・タスクが使えます。

---

# 使い方の小ワザ

* **コマンドパレット**（`⌘⇧P`）→ “Tasks: Run Task” → 事前定義タスクを起動
* **フォルダ別変数**：`${workspaceFolder:<folderName>}` を使うと、特定フォルダをタスクの作業ディレクトリにできます
* **フォルダごとの上書き設定**：
  例）`motor-control/.vscode/settings.json` に Python のフォーマッタや Lint を個別指定
* **Dock ピン留め**：`.code-workspace` を VS Code アイコンへドラッグすると「最近の項目」に残りやすい

---

必要なら、

* `ruff`/`black` の設定（`pyproject.toml`）
* `rust-toolchain.toml`（Rust のツールチェイン固定）
* Obsidian の日次テンプレ連動（`memo-inbox/templates`）
  …までまとめた“スターター一式”も作れます。欲しい粒度を教えてください！





なるほど 👍
さっきの **`.code-workspace` ファイル生成コマンド**はターミナルに直接流す形でしたが、
「あとで何度でも使えるように」**スクリプトファイル**にして保存しておくのが良いですね。

---

## 🔹 手順

### 1. スクリプトファイルを作成

例えば `create_vscode_workspace.sh` という名前で保存します。

```bash
cat > ~/create_vscode_workspace.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

TARGET="${HOME}/workspace/DevWorkspace.code-workspace"

cat > "$TARGET" <<'JSON'
{
  "folders": [
    { "path": "motor-control" },
    { "path": "coding-tips" },
    { "path": "kaggle-challenges" },
    { "path": "kensho-san" },
    { "path": "memo-inbox" },
    { "path": "shared-drive" }
  ],
  "settings": {
    "search.exclude": {
      "**/.git": true,
      "**/.venv": true,
      "**/__pycache__": true,
      "shared-drive/datasets/**": true,
      "shared-drive/archive/**": true,
      "motor-control/papers/**": true,
      "shared-drive/papers/**": true
    },
    "files.watcherExclude": {
      "**/.git/**": true,
      "**/.venv/**": true,
      "**/__pycache__/**": true,
      "shared-drive/datasets/**": true,
      "shared-drive/archive/**": true
    },
    "editor.formatOnSave": true,
    "editor.tabSize": 2,
    "editor.rulers": [100],
    "files.trimTrailingWhitespace": true,
    "explorer.compactFolders": false,
    "python.defaultInterpreterPath": "python3",
    "python.analysis.autoImportCompletions": true,
    "rust-analyzer.checkOnSave.command": "clippy",
    "markdown.preview.breaks": true,
    "terminal.integrated.cwd": "${workspaceFolder}"
  },
  "extensions": {
    "recommendations": [
      "ms-python.python",
      "ms-toolsai.jupyter",
      "charliermarsh.ruff",
      "rust-lang.rust-analyzer",
      "vadimcn.vscode-lldb",
      "mhutchie.git-graph",
      "makorogan.view-in-browser"
    ]
  }
}
JSON

echo "✅ VSCode workspace file created at: $TARGET"
BASH
```

---

### 2. 実行権限をつける

```bash
chmod +x ~/create_vscode_workspace.sh
```

---

### 3. 実行してファイルを作る

```bash
~/create_vscode_workspace.sh
```

→ `~/workspace/DevWorkspace.code-workspace` が生成されます。

---

### 4. VSCodeで開く

```bash
code ~/workspace/DevWorkspace.code-workspace
```

---

## 🔹 補足

* このスクリプトを保存しておけば、workspace を作り直したいときにいつでも再生成できます。
* 場所は `~/` に置いてもいいですし、`~/scripts/` フォルダを作ってまとめてもOKです。

---



はい、承知いたしました。提示された2つの記述について、それぞれ実行する前と後で何が変わるのかを解説します。

結論から言うと、どちらの操作も最終的に行われることは\*\*「VSCodeの便利なワークスペース設定ファイルを作成する」**という点で同じです。しかし、2つ目の方法は**「その設定ファイルをいつでも再生成できるスクリプトを作る」\*\*という点が大きな違いです。

-----

### 最初の記述：直接コマンドを実行した場合

これは、1回限りの操作でワークスペース設定ファイルを作成する方法です。

#### 実行前

  * あなたのPCの `~/workspace/` ディレクトリには、`DevWorkspace.code-workspace` というファイルは存在しません。
  * VSCodeで `motor-control` や `kaggle-challenges` といった複数のプロジェクトを同時に開くには、それぞれ別のウィンドウで開く必要がありました。
  * プロジェクトごとに検索除外設定やエディタのフォーマット設定などを個別に行う必要がありました。

#### 実行後

  * `~/workspace/DevWorkspace.code-workspace` という**設定ファイルが1つ作成されます**。
  * このファイルをVSCodeで開くと、以下のことが実現します。
      * **1つのウィンドウに**、`motor-control`、`coding-tips`など指定された全てのフォルダがサイドバーに表示されます。
      * Pythonの仮想環境（`.venv`）やGitの管理ファイル（`.git`）などが**自動的に検索対象から除外**され、VSCodeの動作が軽くなります。
      * ファイルを保存するたびに自動でフォーマットが適用されるなど、**共通のエディタ設定が適用**されます。
      * チーム開発などで便利な\*\*「推奨拡張機能」の通知\*\*が表示されるようになります。
      * コマンドパレットから「`MotorControl: pytest (simulation)`」のような**定義済みのコマンド（タスク）を簡単に実行**できるようになります。

つまり、**複数のプロジェクトを横断して効率的に開発するための、あなた専用の「開発拠点」が手に入ります。**

-----

### 2番目の記述：スクリプトファイルを作成した場合

これは、最初の記述で行った「設定ファイルの作成」という作業を、**自動化・再利用可能にするための方法**です。

#### 実行前

  * `DevWorkspace.code-workspace` ファイルはもちろん、それを生成するための `create_vscode_workspace.sh` というスクリプトファイルも存在しません。

#### 実行後

  * **2つのものが作成されます**。
    1.  `~/create_vscode_workspace.sh`：ワークスペース設定を**生成するためのシェルスクリプト**。
    2.  `~/workspace/DevWorkspace.code-workspace`：上記スクリプトを実行した結果として作られる、**最初の記述と全く同じ設定ファイル**。

一番の大きな変化は、**`create_vscode_workspace.sh` という「設計図」が手に入ること**です。

-----

### まとめ：2つの方法の決定的な違い

| | **最初の記述 (直接コマンド)** | **2番目の記述 (スクリプト化)** |
| :--- | :--- | :--- |
| **目的** | 設定ファイルを **“作る”** | 設定ファイルを **“作る仕組みを作る”** |
| **手に入るもの** | `DevWorkspace.code-workspace` ファイル | `DevWorkspace.code-workspace` ファイル **＋** \<br\>それを何度でも生成できる `create_vscode_workspace.sh` スクリプト |
| **メリット** | 手っ取り早い。一回きりならこれで十分。 | **再利用性**: 間違えて消してもスクリプト実行で復活できる。\<br\>**管理が楽**: プロジェクトが増えたらスクリプトを編集すればOK。\<br\>**環境移行**: 新しいPCでもスクリプト1つで環境を再現できる。 |

**結論として、2番目のスクリプト化するアプローチの方が、将来的なメンテナンス性や環境の再現性が格段に高まるため、断然おすすめです。**