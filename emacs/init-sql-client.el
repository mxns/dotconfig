;;; sql-connect.el --- mxns config -*- lexical-binding: t; -*-

;;; Commentary:
;;; My configuration

;;; Code:

(setq sql-connection-alist
      '((db-dev (sql-product 'mysql)
                (sql-server "127.0.0.1")
                (sql-user "root")
                (sql-password "yourStrong(!)Password")
                (sql-port 3306))
        (db-stg (sql-product 'mysql)
                (sql-server "db.site.com")
                (sql-user "username")
                (sql-password "password")
                (sql-database "stagingDB")
                (sql-port 3306))
        (db-prod (sql-product 'mysql)
                 (sql-server "db.site.com")
                 (sql-user "username")
                 (sql-password "password")
                 (sql-database "productionDB")
                 (sql-port 3306))))

(defun connect-to-database (label)
  "Connect to the database associated with the given LABEL."
  (interactive)
  (let ((product (car (cdr (assoc label sql-connection-alist)))))
    (setq sql-product product)
    (sql-connect label)))

(defun mysql-db-dev ()
  "Connect to the dev db."
  (interactive)
  (connect-to-database 'db-dev))

;;; sql-connect.el ends here
