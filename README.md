# wsl2-path-bridge.el
Emacs package to seamlessly open Windows paths in WSL2 via find-file.

WSL2上のEmacsで、Windowsのファイルパス（`C:\Users\...`）を `find-file` のミニバッファにペースト（`C-y`）した際、自動的にWSL2パス（`/mnt/c/Users/...`）に変換します。

## 必要環境

- Emacs >= 29.0
- WSL2

## セットアップ

### 手動インストール

1. `wsl2-path-bridge.el` を任意のディレクトリに配置します

2. `init.el` に以下を追加します

```elisp
(add-to-list 'load-path "/path/to/wsl2-path-bridge.el")
(require 'wsl2-path-bridge)
(wsl2-path-bridge-mode 1)
```

## 使い方

1. Windows側でファイルパスをコピーします（エクスプローラーのアドレスバー等）
2. Emacsで `C-x C-f`（find-file）を実行します
3. ミニバッファで `C-y`（yank）でペーストします
4. Windowsパスが自動的にWSL2パスに変換されます

### 変換例

| 入力（Windows） | 出力（WSL2） |
|---|---|
| `C:\Users\user\file.txt` | `/mnt/c/Users/user/file.txt` |
| `D:\Data\project` | `/mnt/d/Data/project` |
| `C:/Users/user/file.txt` | `/mnt/c/Users/user/file.txt` |
| `C:\Users\user\OneDrive\デスクトップ\test.txt` | `/mnt/c/Users/user/OneDrive/デスクトップ/test.txt` |

- バックスラッシュ（`\`）とスラッシュ（`/`）の両方に対応
- ドライブレターは自動的に小文字化
- 日本語を含むパスもそのまま変換
- `find-file-other-window` 等のファイル名入力ミニバッファすべてで動作

## カスタマイズ

### マウントポイントの変更

```elisp
;; デフォルトは "/mnt/"
(setq wsl2-path-bridge-mount-point "/mnt/")
```

### 変換時メッセージの抑制

```elisp
;; 変換時のメッセージを非表示にする
(setq wsl2-path-bridge-message nil)
```

## テスト

```bash
make test
```

## ライセンス

GPL-3.0
