OK！いまは Git 未初期化とのことなので、**最短で “親＝モノレポ(Private) ＋ 子＝motor-control(Public, submodule)”** を作る手順を丸ごと用意しました。コピペで進められます。

---

# 0) 事前（任意）

* Git のユーザー情報が未設定なら一度だけ：

```bash
git config --global user.name  "あなたの表示名"
git config --global user.email "あなたのメール"
```

* 可能なら **GitHub CLI** を入れると楽です（UIでも可）：

```bash
brew install gh
gh auth login   # GitHub にログイン
```

---

# 1) 親モノレポ（Private）を初期化

`~/workspace` を親リポにします（**sudo は不要**）。

```bash
cd ~/workspace

# ルートに .gitignore（大きい/生成物を除外）
cat > .gitignore <<'GITIGNORE'
# macOS
.DS_Store

# Python
__pycache__/
*.pyc
.venv/
venv/

# Node/JS
node_modules/

# Jupyter
.ipynb_checkpoints/

# 大きな保管庫（Gitに入れない）
shared-drive/datasets/
shared-drive/archive/
shared-drive/papers/
motor-control/papers/

# その他よくある生成物
dist/
build/
GITIGNORE

# 初期化 → まず motor-control 以外をコミットしたいので一旦避難せずこのままでOK
git init -b main
git add .
git commit -m "chore: bootstrap workspace (without motor-control submodule yet)"
```

> ここではまだ motor-control は普通のフォルダのままですが、次の手順で**外出しして公開リポ化 → サブモジュールで戻す**ので大丈夫です。

---

# 2) 子リポ：motor-control（Public）を作る

いま履歴は無いので、**フォルダを独立リポに昇格** → GitHub 公開リポへプッシュします。

```bash
# motor-control の中身を一時的に別フォルダに退避
cd ~/workspace
mv motor-control ~/motor-control_pub

# 子リポとして初期化して公開へ
cd ~/motor-control_pub
git init -b main
cat > .gitignore <<'GITIGNORE'
# keep sources, ignore typical big/derived stuff
.DS_Store
__pycache__/
*.pyc
.venv/
venv/
papers/             # 論文はGitに入れない
.ipynb_checkpoints/
GITIGNORE
git add .
git commit -m "feat: initial public release (motor-control)"
```

### GitHub への作成＆プッシュ（A: gh を使う）

```bash
# <あなたのGitHubユーザー名> を自分のに置換
gh repo create <あなたのGitHubユーザー名>/motor-control --public --source . --remote origin --push
```

### （B: Web UI の場合）

1. GitHub で `motor-control`（Public）を作成
2. 表示されたコマンドでリモート設定＆プッシュ：

```bash
git remote add origin git@github.com:<あなた>/motor-control.git
git push -u origin main
```

---

# 3) 親に「サブモジュール」として戻す

```bash
# 親の作業ツリーに戻る
cd ~/workspace

# 親にある古い motor-control フォルダはもう無い（さっき mv 済み）
# ここで submodule として追加
git submodule add git@github.com:<あなた>/motor-control.git motor-control
git add .gitmodules motor-control
git commit -m "chore: add motor-control as public submodule"
```

---

# 4) 親モノレポ（Private）を GitHub へ

### （A: gh で作成＆プッシュ）

```bash
# 例: リポ名 workspace-mono（private）
cd ~/workspace
gh repo create <あなたのGitHubユーザー名>/workspace-mono --private --source . --remote origin --push
```

### （B: Web UI の場合）

1. GitHub で `workspace-mono`（Private）を作成
2. 下記でリモート登録＆プッシュ：

```bash
git remote add origin git@github.com:<あなた>/workspace-mono.git
git push -u origin main
```

> ここまでで
>
> * 親：`workspace-mono`（Private）
> * 子：`motor-control`（Public、submodule）
>   が完成です。

---

# 5) 日々の使い方（最重要だけ）

* **新しいマシンで親をクローン（サブモジュール込み）**

```bash
git clone --recurse-submodules git@github.com:<あなた>/workspace-mono.git
```

* **子で開発 → 子だけ push（公開リポへ）**

```bash
cd motor-control
git checkout -b feat/observer
git commit -m "add Δφ-EKF demo"
git push origin feat/observer
```

* **親に子の更新を反映（ポインタ更新）**

```bash
cd motor-control
git pull origin main     # 子を最新コミットへ
cd ..
git add motor-control    # サブモジュールの参照更新が差分に出る
git commit -m "chore: bump motor-control submodule"
git push
```

---

## よくあるハマりどころ＆対策

* **サブモジュールが空っぽ**：`git submodule update --init --recursive` を実行
* **VSCode が重い/不要ディレクトリも検索**：親の `.code-workspace` で `search.exclude` や `files.watcherExclude` を設定済みに
* **大きなデータや論文を誤って追跡**：`.gitignore` に入れる（親・子ともに）。必要なら Google Drive/DVC/LFS を使う
* **`sudo` で作業してしまい権限事故**：`sudo chown -R $(whoami) ~/workspace` で戻す

---

必要なら、上記のコマンドを**あなたの実際の GitHub ユーザー名**に置き換えた「コピペ1発スクリプト」にも整えます。
（`<あなた>` の部分を教えてくれれば、すぐ出します！）



はい、承知いたしました。GitHub CLI（`gh`コマンド）をインストールすると、具体的に何が楽になるのかを解説します。

一言で言うと、\*\*「普段ブラウザのGitHubサイト上で行うほとんどの操作が、ターミナルから直接できるようになる」\*\*のが最大のメリットです。

これにより、コーディング作業を中断してブラウザに切り替える手間がなくなり、多くの定型作業がスピードアップします。

-----

### 具体的に楽になること

#### 1\. リポジトリの作成とクローンが圧倒的に楽になる

**Before (ghなし):**

1.  ブラウザでGitHubを開く
2.  「New Repository」ボタンを押す
3.  リポジトリ名などを入力して作成
4.  表示されたURLをコピーする
5.  ターミナルに戻り `git clone <URL>` を実行する
6.  （ローカルに既存のプロジェクトがある場合） `git remote add origin <URL>` などを実行して紐付ける

**After (ghあり):**
ターミナルで以下のコマンドを実行するだけです。

```bash
# 新しいリポジトリをGitHub上に作り、すぐにクローンする
gh repo create MyNewProject --public --clone

# 既存のローカルプロジェクトをGitHubに上げる
# （自動でリポジトリが作られ、リモートが設定され、pushされる）
gh repo create
```

これだけで、ブラウザを開くことなくリポジトリの作成から連携までが完了します。

#### 2\. プルリクエスト（PR）の操作がターミナルで完結する

これが `gh` を使う最大のメリットかもしれません。日々の開発で最もよく使う機能です。

**Before (ghなし):**

1.  コードを `git push` する
2.  ブラウザでGitHubを開く
3.  「Compare & pull request」ボタンを押す
4.  PRのタイトル、本文、レビュアーなどを入力して作成する
5.  （レビューが来たPRを確認する場合）ブラウザでPRのページを開き、ローカルでブランチを切り替える

**After (ghあり):**
現在のブランチからPRを作成する場合、コマンド1つで済みます。

```bash
# 現在のブランチから対話形式でPRを作成
gh pr create

# レビュアーやタイトルも指定できる
gh pr create --title "新しい機能を追加" --body "詳細はIssue #123" --reviewer @TaroYamada

# 他の人が作ったPRをローカルで試すのも簡単
gh pr checkout 25  # PR番号25のブランチに切り替え
```

`gh pr create` を実行すると、ターミナル上で対話的にタイトルや本文を入力でき、そのままPRが作成されます。わざわざブラウザを開く必要がありません。

#### 3\. Issueの確認や作成も楽になる

```bash
# Issueの一覧を表示
gh issue list

# 新しいIssueを作成
gh issue create --title "バグ報告: ログインできない"

# Issueの詳細を確認
gh issue view 15
```

#### 4\. 認証（ログイン）が簡単で安全

`gh auth login` を実行すると、ブラウザが起動して認証プロセスを進めるだけで、安全な認証情報（トークン）がPCに保存されます。
自分でアクセストークンを発行してPCに設定する手間が省け、セキュリティも向上します。

-----

### まとめ

| 操作 | GitHub CLI (`gh`)がない場合 | GitHub CLI (`gh`)がある場合 |
| :--- | :--- | :--- |
| **リポジトリ作成** | ブラウザで数クリック ＋ URLコピー ＋ `git`コマンド | `gh repo create` コマンド一発 |
| **プルリクエスト作成** | `git push` → ブラウザでフォーム入力 | `gh pr create` コマンド一発 |
| **PRの確認** | ブラウザでPRを探し、ローカルでブランチを切り替え | `gh pr checkout <番号>` コマンド一発 |
| **コンテキスト** | ターミナルとブラウザを頻繁に行き来する必要がある | ほとんどの操作が**ターミナル内で完結**する |

結論として、`gh` は **「Git（ローカルリポジトリの管理ツール）」と「GitHub（リモートリポジトリのホスティングサービス）」の間の溝を埋めてくれるツール**です。
これを導入することで、日々の開発ワークフローがよりスムーズで高速になります。