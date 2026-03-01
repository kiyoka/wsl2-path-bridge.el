;;; wsl2-path-bridge.el --- Convert Windows paths to WSL2 paths in minibuffer -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Kiyoka Nishiyama
;;
;; Author: Kiyoka Nishiyama
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.0"))
;; Keywords: convenience, files
;; URL: https://github.com/kiyoka/wsl2-path-bridge.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; WSL2上のEmacsで、Windowsのファイルパス（C:\Users\...）を find-file の
;; ミニバッファにペースト（C-y）した際、自動的にWSL2パス（/mnt/c/Users/...）
;; に変換するパッケージです。
;;
;; 使い方:
;;   (require 'wsl2-path-bridge)
;;   (wsl2-path-bridge-mode 1)
;;
;; Windows側でファイルパスをコピーし、C-x C-f → C-y でペーストすると
;; 自動的にWSL2パスに変換されます。

;;; Code:

(defgroup wsl2-path-bridge nil
  "Convert Windows paths to WSL2 paths in minibuffer."
  :group 'files
  :prefix "wsl2-path-bridge-")

(defcustom wsl2-path-bridge-mount-point "/mnt/"
  "WSL2のマウントポイント。
Windowsドライブがマウントされるディレクトリのプレフィックス。"
  :type 'string
  :group 'wsl2-path-bridge)

(defcustom wsl2-path-bridge-message t
  "非nilの場合、パス変換時にメッセージを表示する。"
  :type 'boolean
  :group 'wsl2-path-bridge)

(defun wsl2-path-bridge--strip-quotes (str)
  "STR の前後のダブルクオーテーションを除去する。
Windowsの「パスのコピー」操作で付与される引用符に対応。"
  (if (and (stringp str)
           (>= (length str) 2)
           (eq (aref str 0) ?\")
           (eq (aref str (1- (length str))) ?\"))
      (substring str 1 -1)
    str))

(defun wsl2-path-bridge--windows-path-p (str)
  "STR がWindowsパスかどうかを判定する。
`C:\\Users\\...' や `C:/Users/...' の形式に対応。"
  (and (stringp str)
       (string-match-p "\\`[A-Za-z]:[/\\\\]" str)))

(defun wsl2-path-bridge--unc-path-p (str)
  "STR がUNCパスかどうかを判定する。
`\\\\server\\share\\...' の形式に対応。"
  (and (stringp str)
       (string-match-p "\\`\\\\\\\\[^\\\\]" str)))

(defun wsl2-path-bridge--convert-path (path)
  "WindowsパスPATHをWSL2パスに変換する。
PATHがWindowsパスでもUNCパスでもない場合はnilを返す。"
  (cond
   ((wsl2-path-bridge--windows-path-p path)
    (let* ((drive-letter (downcase (substring path 0 1)))
           (rest (substring path 2))
           ;; 先頭の区切り文字を除去
           (rest (if (string-match-p "\\`[/\\\\]" rest)
                     (substring rest 1)
                   rest))
           ;; バックスラッシュをスラッシュに変換
           (rest (replace-regexp-in-string "\\\\" "/" rest)))
      (concat wsl2-path-bridge-mount-point drive-letter "/" rest)))
   ((wsl2-path-bridge--unc-path-p path)
    (let* (;; 先頭の \\ を除去してバックスラッシュをスラッシュに変換
           (rest (substring path 2))
           (rest (replace-regexp-in-string "\\\\" "/" rest)))
      (concat wsl2-path-bridge-mount-point rest)))))

(defun wsl2-path-bridge--file-name-minibuffer-p ()
  "現在のミニバッファがファイル名入力用かどうかを判定する。"
  (and (minibufferp)
       (bound-and-true-p minibuffer-completing-file-name)))

(defun wsl2-path-bridge--convert-minibuffer-path ()
  "ミニバッファ内のテキストを検査し、Windowsパスがあれば変換する。
ミニバッファのデフォルトディレクトリがWindowsパスの前にある場合も処理する。"
  (when (wsl2-path-bridge--file-name-minibuffer-p)
    (let* ((content (minibuffer-contents))
           ;; ダブルクオーテーションを除去（Windowsの「パスのコピー」対応）
           (content (wsl2-path-bridge--strip-quotes content))
           ;; ミニバッファの内容からWindowsパスまたはUNCパスを検出
           ;; デフォルトディレクトリ（~/等）がプレフィックスとして付く場合がある
           (win-path-pos (or (string-match "\\\\\\\\[^\\\\]" content)
                             (string-match "[A-Za-z]:[/\\\\]" content))))
      (when win-path-pos
        (let* ((win-path (substring content win-path-pos))
               ;; 末尾のダブルクオーテーションを除去
               ;; プレフィックス付きの場合 ~/"C:\..." → win-path が C:\..." になるため
               (win-path (if (and (> (length win-path) 0)
                                  (eq (aref win-path (1- (length win-path))) ?\"))
                             (substring win-path 0 -1)
                           win-path))
               (wsl-path (wsl2-path-bridge--convert-path win-path)))
          (when wsl-path
            (delete-minibuffer-contents)
            (insert wsl-path)
            (when wsl2-path-bridge-message
              (message "WSL2 path: %s" wsl-path))))))))

(defun wsl2-path-bridge--after-yank (&rest _args)
  "yankの後に実行されるアドバイス関数。
ファイル名入力中のミニバッファでのみパス変換を実行する。"
  (wsl2-path-bridge--convert-minibuffer-path))

;;;###autoload
(define-minor-mode wsl2-path-bridge-mode
  "WindowsパスをWSL2パスに自動変換するグローバルマイナーモード。
有効にすると、ファイル名入力中のミニバッファでyankした際に
Windowsパスが自動的にWSL2パスに変換されます。"
  :global t
  :lighter " WSL2"
  :group 'wsl2-path-bridge
  (if wsl2-path-bridge-mode
      (progn
        (advice-add 'yank :after #'wsl2-path-bridge--after-yank)
        (advice-add 'yank-pop :after #'wsl2-path-bridge--after-yank))
    (advice-remove 'yank #'wsl2-path-bridge--after-yank)
    (advice-remove 'yank-pop #'wsl2-path-bridge--after-yank)))

(provide 'wsl2-path-bridge)
;;; wsl2-path-bridge.el ends here
