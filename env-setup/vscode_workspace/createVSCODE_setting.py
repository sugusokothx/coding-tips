# Re-create three VSCode settings templates and save them as files the user can download.
import json, os

base = "/mnt/data"

root_settings = {
  "editor.formatOnSave": True,
  "editor.defaultFormatter": "ms-python.black-formatter",
  "editor.tabSize": 4,
  "files.exclude": {
    "**/__pycache__": True,
    "**/.pytest_cache": True,
    "**/.venv": True,
    "**/*.pyc": True
  },
  "python.languageServer": "Pylance",
  "python.terminal.activateEnvironment": True,
  "python.formatting.provider": "black",
  "python.testing.pytestEnabled": True,
  "python.analysis.autoImportCompletions": True
}

project_settings = {
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.envFile": "${workspaceFolder}/.env",
  "python.languageServer": "Pylance",
  "python.terminal.activateEnvironment": True,
  "python.testing.pytestEnabled": True,
  "python.analysis.autoImportCompletions": True,
  "editor.formatOnSave": True,
  "editor.defaultFormatter": "ms-python.black-formatter",
  "editor.tabSize": 4,
  "files.exclude": {
    "**/__pycache__": True,
    "**/.pytest_cache": True,
    "**/.venv": True,
    "**/*.pyc": True
  }
}

root_path = os.path.join(base, "code.vscode.settings.json")
backtester_path = os.path.join(base, "backtester.vscode.settings.json")
kiyohara_path = os.path.join(base, "kiyohara.vscode.settings.json")

with open(root_path, "w") as f:
    json.dump(root_settings, f, indent=2, ensure_ascii=False)

with open(backtester_path, "w") as f:
    json.dump(project_settings, f, indent=2, ensure_ascii=False)

with open(kiyohara_path, "w") as f:
    json.dump(project_settings, f, indent=2, ensure_ascii=False)

(root_path, backtester_path, kiyohara_path)
