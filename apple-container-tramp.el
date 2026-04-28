;;; apple-container-tramp.el --- TRAMP integration for apple container -*- lexical-binding: t; -*-

;; URL: https://github.com/major1201/apple-container-tramp.el
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3"))

;; This file is NOT part of GNU Emacs.

;;; License:

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
;;
;; `apple-container-tramp.el' offers a TRAMP method for Apple containers.
;;
;; > **NOTE**: `apple-container-tramp.el' relies in the `container exec` command.  Tested
;; > with apple container version 0.10.0 but should work with versions >0.10.0.
;;
;; > **NOTE**: [Similar functionality][] is built-in to Emacs from version 29
;; > onwards, so perhaps you don't need this package any more.
;;
;; ## Usage
;;
;; Offers the TRAMP method `container` to access running containers
;;
;;     C-x C-f /container:user@container-id:/path/to/file
;;
;;     where
;;       user           is the user that you want to use inside the container (optional)
;;       container-id   is the id or name of the container
;;
;; ### [Multi-hop][] examples
;;
;; If you container is hosted on `vm.example.net`:
;;
;;     /ssh:vm-user@vm.example.net|container:user@container:/path/to/file
;;
;; If you need to run the `container` command as, say, the `root` user:
;;
;;     /sudo:root@localhost|container:user@container:/path/to/file

;;; Code:

(eval-when-compile (require 'cl-lib))

(require 'tramp)
(require 'tramp-cache)

(defgroup apple-container-tramp nil
  "TRAMP integration for Apple containers."
  :prefix "apple-container-tramp-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/major1201/apple-container-tramp.el")
  :link '(emacs-commentary-link :tag "Commentary" "apple-container-tramp"))

;;;###autoload
(defcustom apple-container-tramp-container-options nil
  "List of container options."
  :type '(repeat string)
  :group 'apple-container-tramp)

;;;###autoload
(defconst apple-container-tramp-completion-function-alist
  '((apple-container-tramp--parse-running-containers  ""))
  "Default list of (FUNCTION FILE) pairs to be examined for container method.")

;;;###autoload
(defconst apple-container-tramp-method "container"
  "Method to connect containers.")

(defun apple-container-tramp--running-containers ()
  "Collect running containers.

Return a list of containers of the form: \(ID NAME\)"
  (cl-loop for line in (cdr (ignore-errors (apply #'process-lines "container" (append apple-container-tramp-container-options (list "ls")))))
           for info = (split-string line "[[:space:]]+" t)
           collect (car info)))

(defun apple-container-tramp--parse-running-containers (&optional _)
  "Return a list of (user host) tuples.

TRAMP calls this function with a filename which is IGNORED.  The
user is an empty string because the container TRAMP method uses bash
to connect to the default user containers."
  (cl-loop for id in (apple-container-tramp--running-containers)
           collect (list "" id)))

;;;###autoload
(defun apple-container-tramp-cleanup ()
  "Cleanup TRAMP cache for container method."
  (interactive)
  (let ((containers (apply #'append (apple-container-tramp--running-containers))))
    (maphash (lambda (key _)
               (and (vectorp key)
                    (string-equal apple-container-tramp-method (tramp-file-name-method key))
                    (not (member (tramp-file-name-host key) containers))
                    (remhash key tramp-cache-data)))
             tramp-cache-data))
  (setq tramp-cache-data-changed t)
  (if (zerop (hash-table-count tramp-cache-data))
      (ignore-errors (delete-file tramp-persistency-file-name))
    (tramp-dump-connection-properties)))

;;;###autoload
(defun apple-container-tramp-add-method ()
  "Add container tramp method."
  (add-to-list 'tramp-methods
               `(,apple-container-tramp-method
                 (tramp-login-program      ,"container")
                 (tramp-login-args         (,apple-container-tramp-container-options ("exec" "-it") ("-u" "%u") ("%h") ("sh")))
                 (tramp-remote-shell       "/bin/sh")
                 (tramp-remote-shell-args  ("-i" "-c")))))

(defun apple-container-tramp-setup ()
  "Set up apple-container TRAMP method."
  (apple-container-tramp-add-method)
  (tramp-set-completion-function apple-container-tramp-method
                                 apple-container-tramp-completion-function-alist))

;;;###autoload
(if (featurep 'tramp)
    ;; TRAMP is already loaded, run setup immediately
    (apple-container-tramp-setup)
  ;; TRAMP not yet loaded, defer until it is
  (add-hook 'tramp-load-hook #'apple-container-tramp-setup))

(provide 'apple-container-tramp)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; apple-container-tramp.el ends here
