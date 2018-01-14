;;; Just copy the following into your init.el !

;;; Emacs in console on Mac

(defun yank-from-mac-clipboard ()
  "Insert text from the OS clipboard on Mac."
  (interactive)
  (let ((command
         (cond ((equal system-type 'darwin   ) "pbpaste")
               ((equal system-type 'gnu/linux) "xsel --clipboard"))))
    (set-mark (point))
    (insert (shell-command-to-string command))))

(defun kill-region-into-mac-clipboard (from to)
  "The same as `kill-region' except that the killed text is saved
also in the OS clipboard on Mac even if Emacs runs in Terminal."
  (interactive "r")
  (let ((command
         (cond ((equal system-type 'darwin   ) "pbcopy")
               ((equal system-type 'gnu/linux) "xsel --clipboard --input"))))
    (shell-command-on-region from to command)
    (kill-region from to)))

(defun copy-region-into-mac-clipboard (from to)
  "The same as `copy-region-as-kill' except that the killed text
is saved also in the OS clipboard on Mac even if Emacs runs in
Terminal."
  (interactive "r")
  (let ((command
         (cond ((equal system-type 'darwin   ) "pbcopy")
               ((equal system-type 'gnu/linux) "xsel --clipboard --input"))))
    (shell-command-on-region from to command)
    (copy-region-as-kill from to)))

(global-set-key "\C-c\C-y" 'yank-from-mac-clipboard)
(global-set-key "\C-c\C-w" 'kill-region-into-mac-clipboard)
(global-set-key "\C-c\M-w" 'copy-region-into-mac-clipboard)

;;; Excel-方眼紙

(defun kill-region-for-hougansi (from to)
  "Kill the region and convert it to a tab-separated list of
characters."
  (interactive "r")
  (copy-region-as-kill from to)
  (let ((row 1) (col 1) (candy 1))
    (save-excursion
      (save-restriction
        (narrow-to-region from to)
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
    (message "%d lines x %d cells" row col)))

(global-set-key "\C-c\M-\C-w" 'kill-region-for-hougansi)

;;; character-based tables

(defun cut-cli-table-in-region (from to)
  "A table written in the region is cut into the kill ring as
tab-separated values."
  (interactive "r")
  (copy-region-as-kill from to)
  (let ((row 1) (col 1) (candy 1))
    (save-excursion
      (save-restriction
        (narrow-to-region from to)
        (goto-char (point-min))
        (while (re-search-forward "[\t]" nil t)
          (replace-match " " t t))
        (goto-char (point-min))
        (while (re-search-forward "[ ]+$" nil t)
          (replace-match "" t t))
        (goto-char (point-max))
        (while (re-search-backward "^[ ]+" nil t)
          (replace-match "" t t))
        (goto-char (point-min))
        (while (re-search-forward "[ ]*|$" nil t)
          (replace-match "" t t))
        (goto-char (point-max))
        (while (re-search-backward "^|[ ]*" nil t)
          (replace-match "" t t))
        (goto-char (point-min))
        (while (re-search-forward "^[-|+]+$" nil t)
          (replace-match "" t t))
        (goto-char (point-min))
        (while (re-search-forward "[ ]*|[ ]*" nil t)
          (replace-match "\t" t t))
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
    (message "%d lines x %d cells" row col)))

(defun paste-cli-table ()
  "Insert the table created from killed tab-separated values."
  (interactive)
  (if (fboundp 'yank-from-mac-clipboard)
      (yank-from-mac-clipboard)
    (yank))
  (save-excursion
    (save-restriction
      (narrow-to-region (mark) (point))
      (goto-char (point-min))
      (while (re-search-forward "[\t]" nil t)
        (replace-match "\t| " t t)))))

;;; Dictionary.app

(defun mac-dict-open-app ()
  "Apply `browse-url' to the word at point with \"dict:\" protocol.
By default, Dictionary.app launches on Mac."
  (interactive)
  (let ((word
         (if (use-region-p)
             (buffer-substring-no-properties (region-beginning) (region-end))
           (thing-at-point 'word 'noproperty))))
    (browse-url
     (concat "dict://" (url-hexify-string word)))))

(global-set-key "\C-cD" 'mac-dict-open-app)
