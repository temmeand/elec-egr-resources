(require 'package)
(package-initialize)

(dolist (package-path (split-string (or (getenv "OX_HUGO_LOAD_PATH") "") ":" t))
  (add-to-list 'load-path package-path))

(require 'ox-hugo)
(add-to-list 'org-export-exclude-tags "dont_export")

(defun site-org-exportable-file-p (org-file)
  (and (not (string-prefix-p ".#" (file-name-nondirectory org-file)))
       (with-temp-buffer
         (insert-file-contents org-file)
         (let* ((keywords (org-collect-keywords '("HUGO_TAGS")))
                (hugo-tags (cdr (assoc "HUGO_TAGS" keywords))))
           (not (seq-some (lambda (tag) (member tag hugo-tags))
                          org-export-exclude-tags))))))

(let* ((site-root (expand-file-name ".." (file-name-directory load-file-name)))
       (org-dir (expand-file-name "content-org" site-root))
       (org-files (seq-filter
                   #'site-org-exportable-file-p
                   (directory-files-recursively org-dir "\\.org\\'"))))
  (dolist (org-file org-files)
    (with-current-buffer (find-file-noselect org-file)
      (org-hugo-export-to-md))))