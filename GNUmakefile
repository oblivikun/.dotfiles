.PHONY: bootstrap check-emacs tangle-org check-file setup-% clean  install-%
define safe_link
	@if [ -e "$(2)" ]; then \
		echo "Removing existing $(2)"; \
		rm -rf "$(2)"; \
	fi
	@echo "Symlinking $(1) to $(2)"
	@ln -fs "$(1)" "$(2)"
endef

clean:
	rm -rf ./home
	rm -rf ./suckless

bootstrap: clean check-emacs check-file
	echo "Tangling org files"
	emacs --no-site-lisp -batch \
	  --eval "(progn (require 'org) (require 'ob))" \
	  --eval "(setq default-directory \"$(shell pwd)\")" \
	  --eval "(with-current-buffer (find-file-noselect \"./README.org\") (goto-char (point-min)) (org-babel-tangle))"

check-emacs:
	@which emacs > /dev/null && echo "Emacs found at $(shell which emacs)" || (echo "Emacs not found." && false)

check-file:
	@if [ ! -f ./README.org ]; then echo "File README.org not found."; false; fi



setup%: bootstrap
	@echo "Setting up $@"

setup-lisp:
	echo "installing quicklisp" 
	ruby ./setup.rb -q

setup-stump: setup-lisp
	echo "Cloning stumpwm-contrib"
	ruby ./setup.rb -s

install-stump:
	echo "Symlinking stumpwm config"
	$(call safe_link,$(shell readlink -f ./home/.stumpwm.d),${HOME}/.stumpwm.d)

install-st:
	echo "Installing ST terminal"
	ruby ./setup.rb -t
setup-mksh: 
	echo "Cloning fzf-mksh"
	ruby ./setup.rb -m
	echo "Making scripts executable"
	chmod +x ./home/.autoscreen
install-mksh: setup-mksh
	echo "Symlinking stuff"
	ln -fs "$(shell readlink -f ./home/.mkshrc)" "${HOME}/.mkshrc"
	ln -fs "$(shell readlink -f ./home/.fzf-mksh)" "${HOME}/.fzf-mksh"
	ln -fs "$(shell readlink -f ./home/.autoscreen)" "${HOME}/.autoscreen"
install-wayland:

	echo "Installing FZF app launcher: Making script executable"
	chmod +x ./home/.app-launcher-fzf.sh
	echo "Installing Game launcher, making script executable"
	chmod +x ./home/.game-launcher.py
	echo "installing game launcher, symlinking scirpt"
		ln -fs "$(shell readlink -f ./home/.game-launcher.py)" "${HOME}/.game-launcher.py"
	echo "Install FZF app launcher: symlinking script"
	ln -fs "$(shell readlink -f ./home/.app-launcher-fzf.sh)" "${HOME}/.app-launcher-fzf.sh"
	chmod +x "${HOME}/.app-launcher-fzf.sh"
	echo "Installing foot config(s) "
	$(call safe_link,$(shell readlink -f ./home/.config/foot),${HOME}/.config/foot)
	echo "Installing cagebreak Config"
	$(call safe_link,$(shell readlink -f ./home/.config/cagebreak),${HOME}/.config/cagebreak)

.DEFAULT_GOAL := bootstrap
