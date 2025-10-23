# 手動でのPython仮想環境(venv)セットアップ手順

このドキュメントは、現在のプロジェクト構成において、手動でPythonの仮想環境（venv）をセットアップする手順を説明します。

## 1. 前提とするディレクトリ構造

この手順は、以下のようなディレクトリ構造を前提としています。`code`ディレクトリの中に、それぞれ独立したPythonプロジェクト（例: `backtester`, `stock_japanese`）が格納されています。

```
kensho-san/
└── code/
    ├── backtester/
    │   ├── requirements.in
    │   └── ...
    ├── stock_japanese/
    │   ├── requirements.txt
    │   └── ...
    └── ...
```

## 2. .venvが作られる位置

仮想環境（`.venv`）は、各プロジェクトのルートディレクトリ直下に作成されます。これにより、プロジェクトごとに独立した環境を保つことができます。

例：`backtester`プロジェクトの場合
`code/backtester/.venv/`

## 3. セットアップ手順 (`backtester`プロジェクトの例)

以下に、`backtester`プロジェクトの仮想環境をセットアップする手順を示します。

1.  **プロジェクトディレクトリに移動します。**
    ```bash
    cd code/backtester
    ```

2.  **仮想環境を作成します。**
    `.venv`という名前のディレクトリが作成されます。
    ```bash
    python3 -m venv .venv
    ```

3.  **仮想環境を有効化（アクティベート）します。**
    コマンドを実行すると、ターミナルのプロンプトの先頭に `(.venv)` と表示されます。
    ```bash
    source .venv/bin/activate
    ```

4.  **pipをアップグレードし、`pip-tools`をインストールします。**
    `requirements.in`ファイルを扱うために`pip-tools`が必要です。
    ```bash
    pip install --upgrade pip
    pip install pip-tools
    ```

5.  **`requirements.in`から`requirements.txt`を生成します。**
    `requirements.in`に記述されたパッケージ情報をもとに、依存関係が解決された`requirements.txt`が作成されます。
    ```bash
    pip-compile requirements.in
    ```

6.  **依存パッケージをインストールします。**
    生成された`requirements.txt`を使って、必要なパッケージをすべてインストールします。
    ```bash
    pip install -r requirements.txt
    ```

これでセットアップは完了です。開発作業を行う際は、必ず手順3のコマンドで仮想環境を有効化してください。

### 仮想環境の無効化

作業が終わり、仮想環境を抜ける場合は、以下のコマンドを実行します。

```bash
deactivate
```
