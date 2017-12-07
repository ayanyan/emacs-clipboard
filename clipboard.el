;;; Just copy the following into your init.el !

;;; Emacs in console on Mac

(defun yank-from-mac-clipboard ()
  "Insert text from the OS clipboard on Mac."
  (interactive)
  (set-mark (point))
  (insert (shell-command-to-string "pbpaste")))

(defun kill-region-into-mac-clipboard (from to)
  "The same as `kill-region' except that the killed text is saved
also in the OS clipboard on Mac even if Emacs runs in Terminal."
  (interactive "r")
  (shell-command-on-region from to "pbcopy")
  (kill-region from to))

(defun copy-region-into-mac-clipboard (from to)
  "The same as `copy-region-as-kill' except that the killed text
is saved also in the OS clipboard on Mac even if Emacs runs in
Terminal."
  (interactive "r")
  (shell-command-on-region from to "pbcopy")
  (copy-region-as-kill from to))

(global-set-key "\C-c\C-y" 'yank-from-mac-clipboard)
(global-set-key "\C-c\C-w" 'kill-region-into-mac-clipboard)
(global-set-key "\C-c\M-w" 'copy-region-into-mac-clipboard)

;;; Excel-方眼紙

(defun copy-region-for-hougansi (from to)
  "Text in the region is saved in the clipboard and converted to
a tab-separated list of characters."
  (interactive "r")
  (let ((row 1) (col 1) (candy 1))
    (save-excursion
      (save-restriction
        (narrow-to-region from to)
        (copy-region-as-kill (point-min) (point-max))
        (goto-char (point-min))
        (while (looking-at "[\n\r\t]") (forward-char 1))
        (while (< (point) (- (point-max) 1))
          (when (looking-at "[\"]")
            (delete-char 1)
            (insert "'")
            (backward-char 1))
          (forward-char 1)
          (if (looking-at "[\n\r\t]")
              (while (looking-at "[\n\r\t]") (forward-char 1))
            (insert "\t")))
        (goto-char (point-min))
        (while (< (point) (point-max))
          (when (looking-at "[\t]")
            (setq candy (+ candy 1)))
          (when (looking-at "[\n]")
            (setq row (+ row 1))
            (setq col (if (< col candy) candy col))
            (setq candy 1))
          (forward-char 1))
        (setq col (if (< col candy) candy col))
        (if (fboundp 'kill-region-into-mac-clipboard)
            (kill-region-into-mac-clipboard (point-min) (point-max))
          (kill-region (point-min) (point-max)))))
    (yank 2)
    (message "%d lines x %d cells" row col)))

(global-set-key "\C-c\M-\C-w" 'copy-region-for-hougansi)
