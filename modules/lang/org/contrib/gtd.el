;;; lang/org/contrib/gtd.el -*- lexical-binding: t; -*-
;;;###if (featurep! +gtd)

;;; Commentary

(use-package! org-edna
  :after org
  :config
  (setq org-edna-prompt-for-archive nil
        org-edna-use-inheritance t)
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
                    ((org-agenda-span 'day)
                     (org-agenda-start-day nil)
                     (org-super-agenda-groups
                      '((:name "Today"
                         :date today :time-grid t :scheduled today)
                        (:name "Due Today" :deadline today :order 2)
                        (:discard (:anything t))))))
            (alltodo ""
                     ((org-super-agenda-groups
                       '((:discard (:scheduled t))
                         (:name "Current actions" :todo "STRT" :order 1)
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
                         (:discard (:tag "INBOX"))
                         (:discard (:property ("PROJECT" "t")))))))))
          ("i" "Inbox" ((tags-todo "INBOX")))
          ("p" "All projects" ((todo "PROJ")))
          ("n" "Agenda and all TODOs" ((agenda "") (alltodo "")))))
  :hook (org-agenda-mode . org-super-agenda-mode)
  :config
  (setq org-super-agenda-header-map nil))

;;;###autoload
(defun +org--add-project-properties-h (change-plist)
  "Hook function to change the properties when a heading is
marked or unmarked as a project."
  ;; Cleanup properties if the todo state is being moved from PROJ
  (when (string-equal "PROJ" (plist-get change-plist :from))
    (org-delete-property "TRIGGER")
    (org-delete-property "PROJECT"))
  ;; Add properties if the todo state is being moved from PROJ
  (when (string-equal "PROJ" (plist-get change-plist :to))
    (org-set-property "TRIGGER" "next-sibling todo!(STRT)")
    (org-set-property "PROJECT" "t")))

;;;###autoload
(defun +org--deletated-to-h (change-plist)
  "Hook function to add a property describing who a task is
  delegated to."
  (when (string-equal "WAIT" (plist-get change-plist :from))
    (org-delete-property "DELEGATED_TO"))
  (when (string-equal "WAIT" (plist-get change-plist :to))
    (org-set-property "DELEGATED_TO" (read-string "Who will work on this? "))))

(after! org
  (setq org-stuck-projects '("/+PROJ" ("STRT") ("SOMEDAY") ""))
  (add-hook! 'org-trigger-hook
             #'(+org--add-project-properties-h
                +org--deletated-to-h)))

(after! org-capture
  ;; Update the personal todo templates to match others
  (map-put! org-capture-templates "t"
            '("Personal todo" entry
              (file+headline +org-capture-todo-file "Inbox")
              "* TODO %?\n%i\n%a" :prepend t)))
