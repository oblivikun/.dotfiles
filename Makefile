.PHONY: bootstrap check-emacs tangle-org check-file setup clean
clean:
	rm -rf ./home
	rm -rf ./suckless

bootstrap: clean check-emacs check-file
	echo "Tangling org files"
	emacs -batch \
	  --eval "(progn (require 'org) (require 'ob))" \
	  --eval "(setq default-directory \"$(shell pwd)\")" \
	  --eval "(with-current-buffer (find-file-noselect \"./README.org\") (goto-char (point-min)) (org-babel-tangle))"

check-emacs:
	@which emacs > /dev/null && echo "Emacs found at $(shell which emacs)" || (echo "Emacs not found." && false)

check-file:
	@if [ ! -f ./README.org ]; then echo "File README.org not found."; false; fi
setup:
	 ruby ./setup.rb
	
.DEFAULT_GOAL := bootstrap
