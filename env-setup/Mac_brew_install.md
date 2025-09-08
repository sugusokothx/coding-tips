いいですね！✨
ざっと確認なら `brew list --versions` が一番見やすいですが、**将来の Mac 移行や再インストール**のことを考えると `brew bundle dump` は本当に強力です。

---

## 🔹 ざっと確認するコマンド

```bash
brew list --versions
```

出力例：

```
git 2.46.0
python@3.12 3.12.6
node 22.3.0
tree 2.1.1
```

→ どのパッケージが入っていて、どのバージョンかが一目でわかります。

---

## 🔹 再現用リストを作るコマンド

```bash
brew bundle dump --describe --file=~/Brewfile
```

* `~/Brewfile` が生成されます。中身はこんな感じ：

  ```ruby
  brew "git"          # distributed version control system
  brew "python@3.12"  # Interpreted, interactive, object-oriented programming language
  cask "visual-studio-code"
  cask "google-chrome"
  ```

* このファイルを **次の Mac にコピー**してから以下を実行すると同じ環境に：

  ```bash
  brew bundle --file=~/Brewfile
  ```

---

## 🔹 おすすめ運用

1. 定期的に `brew bundle dump --file=~/Brewfile --force` で更新
2. GitHub の dotfiles リポジトリに `Brewfile` を置いておく
3. 新しい Mac では `brew bundle` で一発再現

---

✅ まとめると：

* 今すぐ確認：`brew list --versions`
* 将来の再現：`brew bundle dump --file=~/Brewfile`

---

👉 もし「dotfiles リポジトリ」をまだ作っていないなら、`Brewfile` 以外にも **`.zshrc`, `bootstrap_workspace.sh`, `create_vscode_workspace.sh`** をまとめておくと、新しい Mac でも一瞬で環境構築できます。

ついでに「dotfiles リポジトリ」の雛形も出しましょうか？


いいですね。`.python-version` を読み取って、必要な Python を **pyenv で自動インストール**する汎用スクリプトを用意しました。
指定ディレクトリ（デフォルトはカレント）配下の **すべての `.python-version`** を見つけ、書かれているバージョンをまとめて入れます。すでに入っているものはスキップします。

### 使い方（コピペでOK）

1. スクリプト保存

```bash
cat > ~/pyenv_auto_install.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./pyenv_auto_install.sh [ROOT_DIR] [--dry-run]
# Example:
#   ./pyenv_auto_install.sh ~/workspace
#   ./pyenv_auto_install.sh ~/workspace --dry-run

ROOT="${1:-.}"
DRY_RUN="${2:-}"

# --- checks ---
if ! command -v pyenv >/dev/null 2>&1; then
  echo "❌ pyenv が見つかりません。先に 'brew install pyenv' を実行してください。"
  exit 1
fi

# macOS の一般的な初期化（ログインシェルで設定済みなら不要）
# eval "$(pyenv init -)" >/dev/null 2>&1 || true

mapfile -t files < <(find "$ROOT" -type f -name .python-version 2>/dev/null | sort)
if [ "${#files[@]}" -eq 0 ]; then
  echo "ℹ️  対象ディレクトリに .python-version は見つかりませんでした: $ROOT"
  exit 0
fi

echo "🔎 検出された .python-version:"
printf ' - %s\n' "${files[@]}"
echo

# すべての .python-version からバージョン文字列を収集（重複排除）
declare -A versions_map
for f in "${files[@]}"; do
  # .python-version には「複数バージョンが空白区切り」で書かれることもある
  while read -r line; do
    # コメントと空行をスキップ
    line="${line%%#*}"
    line="$(echo "$line" | xargs || true)"
    [ -z "$line" ] && continue
    # 空白で分割して全部入れる
    for v in $line; do
      versions_map["$v"]=1
    done
  done < "$f"
done

# uniq リスト作成
VERSIONS=("${!versions_map[@]}")
IFS=$'\n' VERSIONS=($(sort <<<"${VERSIONS[*]}"))
unset IFS

echo "📦 インストール対象（.python-version から収集）:"
for v in "${VERSIONS[@]}"; do
  echo " - $v"
done
echo

# インストール処理
for v in "${VERSIONS[@]}"; do
  if pyenv versions --bare | grep -qx "$v"; then
    echo "✅ 既にインストール済み: $v"
    continue
  fi

  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "🧪 DRY-RUN: pyenv install $v"
    continue
  fi

  echo "⬇️  インストール開始: $v"
  # -s: 既にあればスキップ（保険）。見つからない場合は通常の install を試行
  if ! pyenv install -s "$v"; then
    echo "⚠️  '$v' を pyenv で見つけられませんでした。"
    echo "    → 'pyenv install -l' で利用可能バージョンを確認し、"
    echo "      必要なら 'brew upgrade pyenv' あるいは 'pyenv update' を実行してください。"
    exit 1
  fi
  echo "✅ インストール完了: $v"
done

# 仕上げ
if [ "$DRY_RUN" != "--dry-run" ]; then
  pyenv rehash || true
fi

echo
echo "🎉 完了しました。必要に応じて各プロジェクトで 'pyenv local <version>' や venv 作成を行ってください。"
BASH

chmod +x ~/pyenv_auto_install.sh
```

2. 実行（例：workspace 全体を走査）

```bash
~/pyenv_auto_install.sh ~/workspace
```

ドライラン（何が入るかだけ確認）：

```bash
~/pyenv_auto_install.sh ~/workspace --dry-run
```

---

### スクリプトのポイント

* `.python-version` に **複数バージョン**（例：`3.12.6 3.11.9`）が書かれていても対応
* すでに入っているものは **スキップ**
* 見つからないバージョンはメッセージを出して停止（`pyenv update` 等を案内）
* `sudo` 不要・再実行OK

---

### 併せておすすめ（初回だけ）

pyenv をシェル起動時に有効化していない場合は、`~/.zshrc` に以下を入れておくと安心です：

```bash
# pyenv init
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

> 追記後は `source ~/.zshrc` で反映。

---

必要なら、このスクリプトを **`bootstrap_workspace.sh` の最後に呼び出す**ようにつなげて、
初期化一発で Python まで揃うようにもできます。どうしますか？
