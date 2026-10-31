(require 'package)
(package-initialize)

(dolist (package-path (split-string (or (getenv "OX_HUGO_LOAD_PATH") "") ":" t))
  (add-to-list 'load-path package-path))

(require 'ox-hugo)
(add-to-list 'org-export-exclude-tags "dont_export")

(let* ((site-root (expand-file-name ".." (file-name-directory load-file-name)))
       (org-dir (expand-file-name "content-org" site-root))
       (org-files (seq-filter
                   (lambda (org-file)
                     (not (string-prefix-p ".#" (file-name-nondirectory org-file))))
                   (directory-files-recursively org-dir "\\.org\\'"))))
  (dolist (org-file org-files)
    (with-current-buffer (find-file-noselect org-file)
      (org-hugo-export-to-md))))