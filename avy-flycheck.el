;;; avy-flycheck.el --- Jump to and fix syntax errors using `flycheck' with `avy' interface -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Xu Ma

;; Author: Xu Ma <magicdirac@gmail.com>
;; URL: https://github.com/magicdirac/flycheck
;; Package-Version: 0.0.1
;; Version: 0.0.1
;; Package-Requires: ((avy "0.4.0")) ((flycheck))
;; Keywords: avy flycheck

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; 1. Load the package
;; ===================

;; ,----
;; | (add-to-list 'load-path "/path/to/avy-flycheck.el")
;; | (require 'avy-flycheck)
;; `----

;; 2. Give the command a keybinding
;; ================================

;; `avy-flycheck-setup' bind `avy-flycheck-goto-error' to `C-c ! g'.
;; (avy-flycheck-setup)

;; or you can bind `avy-flycheck-goto-error' in global key map
;; (global-flycheck-mode)
;; (global-set-key (kbd "C-c '") #'avy-flycheck-goto-error)

;; 3 Acknowledgment
;; ================

;; This package is based on awesome [flycheck] package and [abo-abo(Oleh
;; Krehel)]'s awesome [avy] package.

;; [flycheck] http://www.flycheck.org  https://github.com/flycheck/flycheck

;; [abo-abo(Oleh Krehel)] https://github.com/abo-abo/

;; [avy] https://github.com/abo-abo/avy

;;; Code:


(eval-when-compile (require 'cl-lib))
(require 'avy)
(require 'flycheck)

(defgroup avy-flycheck nil
  "Jump to and fix syntax errors `flycheck' with `avy' interface"
  :group 'flycheck)

(defcustom avy-flycheck-style 'pre
  "Method for displaying avy overlays.
Defaults to pre."
  :group 'avy-flycheck
  :type '(choice
          (const :tag "Pre" pre)
          (const :tag "At" at)
          (const :tag "At Full" at-full)
          (const :tag "Post" post)
          (const :tag "De Bruijn" de-bruijn)))

(defun avy--flycheck--cands (&optional arg beg end)
  (let (candidates)
    (avy-dowindows arg
      (let ((top (or beg (window-start)))
            ;; (bot (or end (window-end)))
            )
        (save-excursion
          (save-restriction
            (narrow-to-region top (or end (window-end (selected-window) t)))
            (overlay-recenter (point-max))
            ;; TODO: check how to deal with multiple times overlayed region.
            (let* ((overlay-list (overlays-in (point-min) (point-max)))
                   (intersting-overlay (cl-remove-if
                                        (lambda (element)
                                          (let ((pos (overlay-start element)))
                                            (not (and (get-char-property pos 'flycheck-error)
                                                      ;; Check if this error is interesting
                                                      (flycheck-error-level-interesting-at-pos-p pos)))))
                                        overlay-list))
                   (new-candidates (mapcar
                                    (lambda (element)
                                      (cons
                                       (if (eq avy-flycheck-style 'post)
                                           (overlay-end element)
                                         (overlay-start element))
                                       (selected-window)))
                                    intersting-overlay)))
              (setq candidates
                    (append
                     (sort new-candidates
                           ;; sort per window basis.
                           #'(lambda (a b) (<= (car a) (car b))))
                     candidates))
              )))))
    candidates))

(defun avy--flycheck (&optional arg beg end)
  "Select a flycheck syntax error.
The window scope is determined by `avy-all-windows' (ARG negates it).
Narrow the scope to BEG END."
  (let ((avy-action #'identity)
        (candidates (avy--flycheck--cands arg beg end)))
    (if candidates
        (progn
          (if (= 1 (length candidates))
              (message "There is only one Syntax error and jump to it"))
          (avy--process
           candidates
           (avy--style-fn avy-flycheck-style)))
    (progn
      (message "There is no Syntax error found.")
      nil))))

;;;###autoload
(defun avy-flycheck-goto-error (&optional arg)
  "Jump to a flycheck syntax error.
The window scope is determined by `avy-all-windows' (ARG negates it)."
  (interactive (list current-prefix-arg))
  (avy-with avy-flycheck-jump-word
    (let* ((r (avy--flycheck (eq arg 4))))
      (unless (or (not r) (eq r t))
        (avy-action-goto

;;;###autoload
(defun avy-flycheck-setup ()
  "Set up default keybindings."
  (interactive)
  (if (featurep 'flycheck)
      (define-key flycheck-mode-map (kbd "C-c ! g") #'avy-flycheck-goto-error)
    (eval-after-load "flycheck"
      ;; TODO: need to fix why I can not add new command to `flycheck-mode-map'
      '(define-key flycheck-mode-map (kbd "C-c ! g") #'avy-flycheck-goto-error)
      )))

(provide 'avy-flycheck)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; avy-flycheck.el ends here
