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
;;; wsl2-path-bridge--unc-path-p のテスト
;;; ============================================================

(ert-deftest test-unc-path-p-backslash ()
  "バックスラッシュ形式のUNCパスを認識する。"
  (should (wsl2-path-bridge--unc-path-p "\\\\server\\share\\folder")))

(ert-deftest test-unc-path-p-not-windows ()
  "Windowsドライブパスは認識しない。"
  (should-not (wsl2-path-bridge--unc-path-p "C:\\Users\\user")))

(ert-deftest test-unc-path-p-unix ()
  "Unixパスは認識しない。"
  (should-not (wsl2-path-bridge--unc-path-p "/home/user")))

(ert-deftest test-unc-path-p-single-backslash ()
  "バックスラッシュ1つは認識しない。"
  (should-not (wsl2-path-bridge--unc-path-p "\\server\\share")))

;;; ============================================================
;;; UNCパス変換のテスト
;;; ============================================================

(ert-deftest test-convert-unc-path ()
  "UNCパスをWSL2パスに変換する。"
  (should (equal (wsl2-path-bridge--convert-path "\\\\server\\share\\folder\\file.txt")
                 "/mnt/server/share/folder/file.txt")))

(ert-deftest test-convert-unc-path-simple ()
  "シンプルなUNCパスを変換する。"
  (should (equal (wsl2-path-bridge--convert-path "\\\\nas01\\data")
                 "/mnt/nas01/data")))

(ert-deftest test-convert-unc-path-japanese ()
  "日本語を含むUNCパスを変換する。"
  (should (equal (wsl2-path-bridge--convert-path "\\\\server\\共有フォルダ\\資料.docx")
                 "/mnt/server/共有フォルダ/資料.docx")))

(ert-deftest test-convert-unc-path-custom-mount ()
  "カスタムマウントポイントでUNCパスを変換する。"
  (let ((wsl2-path-bridge-mount-point "/wsl/"))
    (should (equal (wsl2-path-bridge--convert-path "\\\\server\\share")
                   "/wsl/server/share"))))

(ert-deftest test-convert-unc-path-quoted ()
  "クオート付きUNCパスの変換。"
  (let* ((input "\"\\\\server\\share\\file.txt\"")
         (stripped (wsl2-path-bridge--strip-quotes input))
         (wsl-path (wsl2-path-bridge--convert-path stripped)))
    (should (equal wsl-path "/mnt/server/share/file.txt"))))

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
;;; wsl2-path-bridge--strip-quotes のテスト
;;; ============================================================

(ert-deftest test-strip-quotes-quoted-path ()
  "ダブルクオーテーションで囲まれたパスからクオートを除去する。"
  (should (equal (wsl2-path-bridge--strip-quotes "\"C:\\Users\\user\\file.txt\"")
                 "C:\\Users\\user\\file.txt")))

(ert-deftest test-strip-quotes-unquoted-path ()
  "クオートなしのパスはそのまま返す。"
  (should (equal (wsl2-path-bridge--strip-quotes "C:\\Users\\user\\file.txt")
                 "C:\\Users\\user\\file.txt")))

(ert-deftest test-strip-quotes-with-prefix ()
  "プレフィックス付きでクオートされたパスからクオートとプレフィックスを除去する。"
  (let* ((content "~/\"C:\\Users\\user\\file.txt\"")
         (stripped (wsl2-path-bridge--strip-quotes content)))
    ;; プレフィックスがあるためクオート除去はされない（前後が"でない）
    (should (equal stripped content))))

(ert-deftest test-strip-quotes-with-prefix-trailing-quote ()
  "プレフィックス付きの場合、抽出後の末尾クオートが除去される。"
  ;; ~/\"C:\\...\" から win-path 抽出時に末尾の \" が残るケースをテスト
  (let* ((content "~/\"C:\\Users\\user\\file.txt\"")
         (win-path-pos (string-match "[A-Za-z]:[/\\\\]" content))
         (win-path (substring content win-path-pos))
         ;; 末尾のダブルクオーテーションを除去
         (win-path (if (and (> (length win-path) 0)
                            (eq (aref win-path (1- (length win-path))) ?\"))
                       (substring win-path 0 -1)
                     win-path))
         (wsl-path (wsl2-path-bridge--convert-path win-path)))
    (should (equal wsl-path "/mnt/c/Users/user/file.txt"))))

(ert-deftest test-strip-quotes-empty ()
  "空文字列はそのまま返す。"
  (should (equal (wsl2-path-bridge--strip-quotes "") "")))

(ert-deftest test-strip-quotes-conversion ()
  "クオート付きWindowsパスの変換が正しく動作する。"
  (let* ((input "\"C:\\Users\\user\\OneDrive\\デスクトップ\\test.txt\"")
         (stripped (wsl2-path-bridge--strip-quotes input))
         (wsl-path (wsl2-path-bridge--convert-path stripped)))
    (should (equal wsl-path "/mnt/c/Users/user/OneDrive/デスクトップ/test.txt"))))

;;; ============================================================
;;; wsl2-path-bridge--ffap-at-point のテスト
;;; ============================================================

(ert-deftest test-ffap-quoted-windows-path ()
  "クオート付きWindowsパス上でffapが動作する。"
  (with-temp-buffer
    (insert "ファイルは \"C:\\Users\\user\\file.txt\" にあります。")
    (goto-char 13)  ;; クオート内のパス上にカーソル
    (should (equal (wsl2-path-bridge--ffap-at-point)
                   "/mnt/c/Users/user/file.txt"))))

(ert-deftest test-ffap-unquoted-windows-path ()
  "クオートなしWindowsパス上でffapが動作する。"
  (with-temp-buffer
    (insert "path: C:\\Users\\user\\file.txt end")
    (goto-char 8)  ;; パス上にカーソル
    (should (equal (wsl2-path-bridge--ffap-at-point)
                   "/mnt/c/Users/user/file.txt"))))

(ert-deftest test-ffap-unc-path ()
  "UNCパス上でffapが動作する。"
  (with-temp-buffer
    (insert "server: \\\\nas01\\share\\file.txt")
    (goto-char 12)  ;; パス上にカーソル
    (should (equal (wsl2-path-bridge--ffap-at-point)
                   "/mnt/nas01/share/file.txt"))))

(ert-deftest test-ffap-not-on-path ()
  "パス上にカーソルがない場合はnilを返す。"
  (with-temp-buffer
    (insert "テキスト C:\\Users\\user\\file.txt")
    (goto-char 3)  ;; パスの前にカーソル
    (should-not (wsl2-path-bridge--ffap-at-point))))

(ert-deftest test-ffap-quoted-japanese-path ()
  "日本語を含むクオート付きパス上でffapが動作する。"
  (with-temp-buffer
    (insert "\"C:\\Users\\user\\OneDrive\\デスクトップ\\test.txt\"")
    (goto-char 5)  ;; パス上にカーソル
    (should (equal (wsl2-path-bridge--ffap-at-point)
                   "/mnt/c/Users/user/OneDrive/デスクトップ/test.txt"))))

;;; ============================================================
;;; wsl2-path-bridge-to-windows-path のテスト
;;; ============================================================

(ert-deftest test-to-windows-path ()
  "WSL2パスをWindowsパスに変換する。"
  (let ((result (wsl2-path-bridge-to-windows-path "/mnt/c/Users")))
    (should (equal result "C:\\Users"))))

(ert-deftest test-to-windows-path-japanese ()
  "日本語を含むWSL2パスをWindowsパスに変換する。"
  (let ((result (wsl2-path-bridge-to-windows-path "/mnt/c/Users/user/OneDrive/デスクトップ")))
    (should (equal result "C:\\Users\\user\\OneDrive\\デスクトップ"))))

(ert-deftest test-copy-windows-path-no-file ()
  "ファイルが関連付けられていないバッファでエラーになる。"
  (with-temp-buffer
    (should-error (wsl2-path-bridge-copy-windows-path))))

;;; ============================================================
;;; モード有効/無効のテスト
;;; ============================================================

(ert-deftest test-mode-enable-disable ()
  "モードの有効/無効でアドバイスが追加・削除される。"
  (wsl2-path-bridge-mode 1)
  (should (advice-member-p #'wsl2-path-bridge--after-yank 'yank))
  (should (advice-member-p #'wsl2-path-bridge--after-yank 'yank-pop))
  (should (advice-member-p #'wsl2-path-bridge--after-yank 'xterm-paste))
  (should (advice-member-p #'wsl2-path-bridge--ffap-at-point 'ffap-guesser))
  (wsl2-path-bridge-mode -1)
  (should-not (advice-member-p #'wsl2-path-bridge--after-yank 'yank))
  (should-not (advice-member-p #'wsl2-path-bridge--after-yank 'yank-pop))
  (should-not (advice-member-p #'wsl2-path-bridge--after-yank 'xterm-paste))
  (should-not (advice-member-p #'wsl2-path-bridge--ffap-at-point 'ffap-guesser)))

(provide 'wsl2-path-bridge-test)
;;; wsl2-path-bridge-test.el ends here
