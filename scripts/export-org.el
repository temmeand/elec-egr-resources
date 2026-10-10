(require 'package)
(package-initialize)

(dolist (package-path (split-string (or (getenv "OX_HUGO_LOAD_PATH") "") ":" t))
  (add-to-list 'load-path package-path))

(require 'ox-hugo)

(let* ((site-root (expand-file-name ".." (file-name-directory load-file-name)))
       (org-files (directory-files site-root t "\\.org\\'")))
  (dolist (org-file org-files)
    (with-current-buffer (find-file-noselect org-file)
      (org-hugo-export-to-md))))