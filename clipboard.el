;;; TIPS for Emacs in console, especially on Mac

;;; Copyright (C) 2018 Yoshihiko Kakutani

;;; Author: Yoshihiko Kakutani

;;; Copyright Notice:

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Just load this file from your `init.el'!

;; (load "clipboard.el")

;;; handling OS clipboard

(defvar use-osc52 t)

(defun yank-from-os-clipboard ()
  "Insert a text retrieved from the OS clipboard."
  (interactive)
  (let ((command
         (cond ((equal system-type 'darwin) "pbpaste")
               ((equal system-type 'windows-nt) "pwsh -Command Get-Clipboard")
               (t "xsel --clipboard"))))
    (when command
      (set-mark (point))
      (insert (shell-command-to-string command)))))

(defun send-region-to-os-clipboard (from to)
  "Send the region to the OS clipboard."
  (interactive "r")
  (let ((command
         (cond ((equal system-type 'darwin) "pbcopy")
               ((equal system-type 'windows-nt) "pwsh -Command Set-Clipboard")
               (t "xsel --clipboard --input"))))
    (when command
      (shell-command-on-region from to command))
    (deactivate-mark)))

(defun send-region-to-os-clipboard-somehow (from to)
  "Send the region to the clipboard in some way."
  (interactive "r")
  (if (and (not window-system) use-osc52)
      (osc52-send-region-to-terminal from to)
    (send-region-to-os-clipboard from to)))

(defvar osc52-limit 100000)

(defun osc52-send-string-to-terminal (string)
  "Send a string to the OS clipboard along the OSC 52 manner.
If the base64 encoded string is longer than `osc52-limit', it
will not be sent."
  (let ((b64-length (* (/ (+ (string-bytes string) 2) 3) 4))
        (head "\e]52;c;")
        (tail "\a"))
    (when (string-match "^screen" (getenv-internal "TERM" initial-environment))
      (setq head (concat
                  (if (getenv-internal "TMUX" initial-environment) "\ePtmux;\e" "\eP")
                  head))
      (setq tail (concat tail "\e\\")))
    (if (< osc52-limit b64-length)
        (message "Too long to send to the clipboard.")
      (message "Sending a string to the clipboard...")
      (send-string-to-terminal
       (concat head
               (base64-encode-string (encode-coding-string string 'utf-8) t)
               tail)))))

(defun osc52-send-region-to-terminal (from to)
  "Send the region to the OS clipboard along the OSC 52 manner."
  (interactive "r")
  (osc52-send-string-to-terminal (buffer-substring-no-properties from to))
  (deactivate-mark))

(defun send-line-to-os-clipboard ()
  "The current line is sent to the OS clipboard."
  (interactive)
  (save-excursion
    (set-mark (point))
    (end-of-line)
    (send-region-to-os-clipboard-somehow (mark) (point)))
  (message ))

(defun kill-region-into-os-clipboard (from to)
  "The same as `kill-region' except that the killed text is saved
also in the OS clipboard even if Emacs runs in Terminal."
  (interactive "r")
  (send-region-to-os-clipboard-somehow from to)
  (kill-region from to))

(defun copy-region-into-os-clipboard (from to)
  "The same as `copy-region-as-kill' except that the killed text
is saved also in the OS clipboard even if Emacs runs in Terminal."
  (interactive "r")
  (send-region-to-os-clipboard-somehow from to)
  (copy-region-as-kill from to)
  (if (interactive-p) (indicate-copied-region)))

(defun kill-line-into-os-clipboard ()
  "The same as `kill-line' except that the killed text is saved
also in the OS clipboard even if Emacs runs in Terminal."
  (interactive)
  (send-line-to-os-clipboard)
  (kill-line))

(global-set-key "\C-c\C-y" 'yank-from-os-clipboard)
(global-set-key "\C-c\C-w" 'copy-region-into-os-clipboard)
(global-set-key "\C-c\C-k" 'send-line-to-os-clipboard)

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
        (if (fboundp 'kill-region-into-os-clipboard)
            (kill-region-into-os-clipboard (point-min) (point-max))
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
        (if (fboundp 'kill-region-into-os-clipboard)
            (kill-region-into-os-clipboard (point-min) (point-max))
          (kill-region (point-min) (point-max)))))
    (message "%d lines x %d cells" row col)))

(defun paste-cli-table ()
  "Insert the table created from killed tab-separated values."
  (interactive)
  (if (fboundp 'yank-from-os-clipboard)
      (yank-from-os-clipboard)
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
