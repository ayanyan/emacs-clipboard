;;; Copy the following code to your init.el !

(defun yank-from-mac-clipboard ()
  (interactive)
  (set-mark (point))
  (insert (shell-command-to-string "pbpaste")))
(defun kill-region-into-mac-clipboard ()
  (interactive)
  (shell-command-on-region (mark) (point) "pbcopy")
  (kill-region (mark) (point)))
(global-set-key "\C-c\C-y" 'yank-from-mac-clipboard)
(global-set-key "\C-c\C-w" 'kill-region-into-mac-clipboard)
