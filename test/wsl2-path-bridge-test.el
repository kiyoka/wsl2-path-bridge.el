;;; wsl2-path-bridge-test.el --- Tests for wsl2-path-bridge -*- lexical-binding: t; -*-

;;; Commentary:

;; ERTテスト for wsl2-path-bridge.el

;;; Code:

(require 'ert)

;; テスト対象のロード
(add-to-list 'load-path (expand-file-name ".." (file-name-directory load-file-name)))
(require 'wsl2-path-bridge)

;;; ============================================================
;;; wsl2-path-bridge--windows-path-p のテスト
;;; ============================================================

(ert-deftest test-windows-path-p-backslash ()
  "バックスラッシュ形式のWindowsパスを認識する。"
  (should (wsl2-path-bridge--windows-path-p "C:\\Users\\user")))

(ert-deftest test-windows-path-p-slash ()
  "スラッシュ形式のWindowsパスを認識する。"
  (should (wsl2-path-bridge--windows-path-p "C:/Users/user")))

(ert-deftest test-windows-path-p-lowercase ()
  "小文字ドライブレターのWindowsパスを認識する。"
  (should (wsl2-path-bridge--windows-path-p "c:\\Users\\user")))

(ert-deftest test-windows-path-p-d-drive ()
  "Dドライブのパスを認識する。"
  (should (wsl2-path-bridge--windows-path-p "D:\\Data\\file.txt")))

(ert-deftest test-windows-path-p-unix ()
  "Unixパスは認識しない。"
  (should-not (wsl2-path-bridge--windows-path-p "/home/user/file.txt")))

(ert-deftest test-windows-path-p-nil ()
  "nilは認識しない。"
  (should-not (wsl2-path-bridge--windows-path-p nil)))

(ert-deftest test-windows-path-p-empty ()
  "空文字列は認識しない。"
  (should-not (wsl2-path-bridge--windows-path-p "")))

(ert-deftest test-windows-path-p-relative ()
  "相対パスは認識しない。"
  (should-not (wsl2-path-bridge--windows-path-p "Users\\user")))

;;; ============================================================
;;; wsl2-path-bridge--convert-path のテスト
;;; ============================================================

(ert-deftest test-convert-path-c-drive ()
  "Cドライブのパスを変換する。"
  (should (equal (wsl2-path-bridge--convert-path "C:\\Users\\user\\file.txt")
                 "/mnt/c/Users/user/file.txt")))

(ert-deftest test-convert-path-d-drive ()
  "Dドライブのパスを変換する。"
  (should (equal (wsl2-path-bridge--convert-path "D:\\Data\\project")
                 "/mnt/d/Data/project")))

(ert-deftest test-convert-path-lowercase-drive ()
  "小文字ドライブレターのパスを変換する。"
  (should (equal (wsl2-path-bridge--convert-path "c:\\Users\\user")
                 "/mnt/c/Users/user")))

(ert-deftest test-convert-path-slash-format ()
  "スラッシュ形式のWindowsパスを変換する。"
  (should (equal (wsl2-path-bridge--convert-path "C:/Users/user/file.txt")
                 "/mnt/c/Users/user/file.txt")))

(ert-deftest test-convert-path-japanese ()
  "日本語を含むパスを変換する。"
  (should (equal (wsl2-path-bridge--convert-path "C:\\Users\\user\\OneDrive\\デスクトップ\\temp\\test1.txt")
                 "/mnt/c/Users/user/OneDrive/デスクトップ/temp/test1.txt")))

(ert-deftest test-convert-path-mixed-separator ()
  "バックスラッシュとスラッシュが混在するパスを変換する。"
  (should (equal (wsl2-path-bridge--convert-path "C:\\Users/user\\file.txt")
                 "/mnt/c/Users/user/file.txt")))

(ert-deftest test-convert-path-non-windows ()
  "Windowsパスでない場合はnilを返す。"
  (should-not (wsl2-path-bridge--convert-path "/home/user/file.txt")))

(ert-deftest test-convert-path-custom-mount-point ()
  "カスタムマウントポイントを使用した変換。"
  (let ((wsl2-path-bridge-mount-point "/wsl/"))
    (should (equal (wsl2-path-bridge--convert-path "C:\\Users\\user")
                   "/wsl/c/Users/user"))))

;;; ============================================================
;;; ミニバッファプレフィックス除去のテスト
;;; ============================================================

(ert-deftest test-convert-path-with-prefix ()
  "デフォルトディレクトリがプレフィックスとして付いた場合の処理。
この場合、wsl2-path-bridge--convert-minibuffer-path がプレフィックスを除去する。
ここではプレフィックス除去のロジックを間接的にテストする。"
  ;; ~/C:\Users\... のような文字列からWindowsパス部分を抽出
  (let* ((content "~/C:\\Users\\user\\file.txt")
         (win-path-pos (string-match "[A-Za-z]:[/\\\\]" content))
         (win-path (substring content win-path-pos))
         (wsl-path (wsl2-path-bridge--convert-path win-path)))
    (should (equal win-path-pos 2))
    (should (equal wsl-path "/mnt/c/Users/user/file.txt"))))

(ert-deftest test-convert-path-with-longer-prefix ()
  "長いプレフィックスがある場合の処理。"
  (let* ((content "/home/user/C:\\Data\\file.txt")
         (win-path-pos (string-match "[A-Za-z]:[/\\\\]" content))
         (win-path (substring content win-path-pos))
         (wsl-path (wsl2-path-bridge--convert-path win-path)))
    (should (equal wsl-path "/mnt/c/Data/file.txt"))))

(ert-deftest test-no-windows-path-in-content ()
  "Windowsパスが含まれていない場合。"
  (let* ((content "/home/user/file.txt")
         (win-path-pos (string-match "[A-Za-z]:[/\\\\]" content)))
    (should-not win-path-pos)))

;;; ============================================================
;;; モード有効/無効のテスト
;;; ============================================================

(ert-deftest test-mode-enable-disable ()
  "モードの有効/無効でアドバイスが追加・削除される。"
  (wsl2-path-bridge-mode 1)
  (should (advice-member-p #'wsl2-path-bridge--after-yank 'yank))
  (should (advice-member-p #'wsl2-path-bridge--after-yank 'yank-pop))
  (wsl2-path-bridge-mode -1)
  (should-not (advice-member-p #'wsl2-path-bridge--after-yank 'yank))
  (should-not (advice-member-p #'wsl2-path-bridge--after-yank 'yank-pop)))

(provide 'wsl2-path-bridge-test)
;;; wsl2-path-bridge-test.el ends here
