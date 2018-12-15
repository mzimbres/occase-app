DIST_NAME = menu_chat

.PHONY:
dist:
	git archive --format=tar.gz --prefix=menu_chat/ HEAD > menu_chat.tar.gz

backup_emails = laetitiapozwolski@yahoo.fr mzimbres@gmail.com bobkahnn@gmail.com coolcatlookingforakitty@gmail.com

.PHONY: backup
backup: $(DIST_NAME).tar.gz
	echo "Backup App" | mutt -s "Backup App" -a $< -- $(backup_emails)

