;;; lang/org/contrib/gtd.el -*- lexical-binding: t; -*-
;;;###if (featurep! +gtd)

;;; Commentary

(use-package! org-edna
  :after org
  :config
  (setq org-edna-use-inheritance t)
  (org-edna-load))

(use-package! org-agenda-property
  :after org
  :config
  (setq org-agenda-property-list '("DELEGATED_TO")
        org-agenda-property-position 'next-line))

(use-package! org-super-agenda
  :after org
  :init
  (setq org-agenda-custom-commands
        '(("d" "Daily Overview"
           ((agenda ""
                    ((org-super-agenda-groups
                      '((:name "Today" :time-grid t :scheduled t :order 1)
                        (:name "Due Today" :deadline t :order 2)))))
            (alltodo ""
                     ((org-super-agenda-groups
                       '((:name "Current actions" :todo "STRT" :order 1)
                         (:name "Important" :priority "A" :order 2)
                         (:name "Overdue" :deadline past :face error :order 3)
                         (:name "Due Soon" :deadline future :order 4)
                         (:name "Waiting" :todo ("WAIT" "HOLD") :order 5)
                         (:name "Stuck Projects"
                          :and (:todo "PROJ"
                                :not (:tag "SOMEDAY")
                                :not (:children "STRT"))
                          :order 80)
                         (:name "Incubating Projects"
                          :and (:tag "SOMEDAY" :todo "PROJ") :order 90)
                         (:name "Projects" :todo "PROJ" :order 10)
                         (:discard (:tag ("PROJECT" "INBOX")))))))))
          ("p" "All projects" ((todo "PROJ")))
          ("n" "Agenda and all TODOs" ((agenda "") (alltodo "")))))
  :hook (org-agenda-mode . org-super-agenda-mode)
  :config
  (setq org-super-agenda-header-map nil))

;;;###autoload
(defun +org--add-projects-tags-and-properties ()
  "Hook function to add the necessary properties and tags when a
heading is makred as a project."
  (when (string-equal org-state "PROJ")
    (org-set-property "TRIGGER" "next-sibling todo-state!(STRT)")
    (let ((current-tags (org-get-tags nil t)))
      (org-set-tags (append '("PROJECT") current-tags)))))

(after! org
  (setq org-stuck-projects '("/+PROJ" ("STRT") ("SOMEDAY") ""))
  (add-hook 'org-after-todo-state-change-hook '+org--add-projects-tags-and-properties))

(after! org-capture
  ;; Update the personal todo templates to match others
  (map-put! org-capture-templates "t"
            '("Personal todo" entry
              (file+headline +org-capture-todo-file "Inbox")
              "* TODO %?\n%i\n%a" :prepend t)))
