#!/usr/bin/env bash

## ################################################
## CONFIGURATION
## ################################################
DOTFILES="$HOME/.dotfiles"
REPO_LOCATION="loup-fox/fox-dotfiles"
# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

## ################################################
## UTILITY FUNCTIONS
## ################################################

# Display functions
function ok() {
    echo -e "$COL_GREEN[ok]$COL_RESET "$1
}

function bot() {
    echo -e "\n$COL_GREEN\[._.]/$COL_RESET - "$1
}

function running() {
    echo -en "$COL_YELLOW ⇒ $COL_RESET"$1": "
}

function action() {
    echo -e "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..."
}

function warn() {
    echo -e "$COL_YELLOW[warning]$COL_RESET "$1
}

function error() {
    echo -e "$COL_RED[error]$COL_RESET "$1
}

# Asks a question and return the result into REPLY
function ask() {
    read -r -p "$1 [y|N]" REPLY
}

# Installs a brew package if not already installed
function require_brew() {
    running "brew install $1"
    brew list $1 >/dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        brew install $1 $2
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    ok
}

# Install a cask package if not already installed
function require_cask() {
    running "brew cask install $1"
    brew cask list $1 >/dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        brew cask install $1
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
        fi
    fi
    ok
}

# Add nvm in variables and source it
function source_nvm() {
    action "sourcing NVM"
    export NVM_DIR=~/.nvm
    source $(brew --prefix nvm)/nvm.sh
}

# Installing nvm if not already installed
function require_nvm() {
    running "nvm install $1"
    mkdir -p ~/.nvm
    cp $(brew --prefix nvm)/nvm-exec ~/.nvm/
    source_nvm
    nvm install $1
    if [[ $? != 0 ]]; then
        require_brew nvm
        . ~/.bashrc
        nvm install $1
    fi
    ok
}

bot "ensuring build/install tools are available"
if ! xcode-select --print-path &>/dev/null; then
    xcode-select --install &>/dev/null
    until xcode-select --print-path &>/dev/null; do
        sleep 5
    done
    sudo xcodebuild -license
fi

# ###########################################################
# Installing homebrew (CLI Packages)
# ###########################################################
running "checking homebrew..."
brew_bin=$(which brew) 2>&1 >/dev/null
if [[ $? != 0 ]]; then
    action "installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    if [[ $? != 0 ]]; then
        error "unable to install homebrew, script $0 abort!"
        exit 2
    fi
    # update ruby to latest
    # use versions of packages installed with homebrew
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml)"
    require_brew ruby
else
    ok
    bot "Homebrew"
    action "updating homebrew"
    brew update
    ok "homebrew updated"
    action "upgrading brew packages"
    brew upgrade
    ok "brews upgraded"
fi

# Just to avoid a potential bug
mkdir -p ~/Library/Caches/Homebrew/Formula
brew doctor &>/dev/null

bot "installing fonts"
brew tap homebrew/cask-fonts
require_cask font-fontawesome
require_cask font-fira-code
require_cask font-awesome-terminal-fonts
require_cask font-hack
require_cask font-inconsolata-dz-for-powerline
require_cask font-inconsolata-g-for-powerline
require_cask font-inconsolata-for-powerline
require_cask font-roboto-mono
require_cask font-roboto-mono-for-powerline
require_cask font-source-code-pro

# Clone this repository if not exists
require_brew git

# nvm
require_brew nvm
require_nvm stable

# always pin versions (no surprises, consistent dev/build machines)
npm config set save-exact true

# install packages
ask "install packages?"
if [[ $REPLY =~ (yes|y|Y) ]]; then
    bot "tapping other repositories"
    running "tapping mongodb"
    brew tap mongodb/brew
    ok

    bot "installing brew packages"
    require_brew zsh
    require_brew yarn
    require_brew python

    ## Specific to Fox
    require_brew mongodb-community
    require_brew aws-iam-authenticator

    ## Installing awscli
    if [ ! -f /usr/local/bin/aws ]; then
        bot "installing awscli (requires sudo)"
        curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
        unzip awscli-bundle.zip
        sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
    fi

    bot "installing cask packages"
    require_cask docker
    require_cask flux
    require_cask gitkraken
    require_cask google-chrome
    require_cask iterm2
    require_cask keybase
    require_cask mongodb-compass
    require_cask notion
    require_cask postman
    require_cask robo-3t
    require_cask sequel-pro
    require_cask slack
    require_cask smcfancontrol
    require_cask spectacle
    require_cask spotify
    require_cask sublime-text
    require_cask the-unarchiver
    require_cask tunnelblick
    require_cask visual-studio-code

    # install visual code extensions
    bot "installing visual code extensions..."
    function vcie() {
        running "code --install-extensions $1"
        code --install-extension $1
        ok
    }
    vcie dbaeumer.vscode-eslint
    vcie eamodio.gitlens
    vcie editorconfig.editorconfig
    vcie esbenp.prettier-vscode
    vcie ms-azuretools.vscode-docker
    vcie ms-python.python
    vcie visualstudioexptteam.vscodeintellicode
    vcie vscode-icons-team.vscode-icons
    vcie vscodevim.vim
    vcie zhuangtongfa.material-theme
fi

[ ! -d "$DOTFILES" ] && git clone --recurse-submodules https://github.com/$REPO_LOCATION

## Keep it for future reintegration
# function make_key() {
#     [ ! -f "$HOME/.ssh/$2" ] && ssh-keygen -q -t rsa -b 4096 -C "$1" -f "$HOME/.ssh/$2" -N ""
# }
# bot "Setting up your ssh key"
# make_key "$WORK_EMAIL" "id_rsa"
# ok

bot "setting up dotfiles..."
DOTFILES_PLUGS="$DOTFILES/oh-my-zsh-plugins"
HOME_PLUGS="$HOME/.oh-my-zsh/custom/plugins"
FSH_PLUG="fast-syntax-highlighting"
AUTO_SUG="zsh-autosuggestions"
function link_dir() {
    SRC=$1
    DEST=$2
    [ -d "$DEST" ] && rm -rf "$DEST"
    ln -sf "$SRC" "$DEST"
}

link_dir "$DOTFILES/oh-my-zsh" "$HOME/.oh-my-zsh"

# Links all the files for zsh and oh-my-zsh
link_dir "$DOTFILES/zsh-themes" "$HOME/.zsh-themes"

link_dir "$DOTFILES_PLUGS/$FSH_PLUG" "$HOME_PLUGS/$FSH_PLUG"
link_dir "$DOTFILES_PLUGS/$AUTO_SUG" "$HOME_PLUGS/$AUTO_SUG"
ln -sf "$DOTFILES_PLUGS/z/z.sh" "$HOME_PLUGS/z.sh"
ln -sf "$DOTFILES/zshrc.sh" "$HOME/.zshrc"
ln -sf "$DOTFILES/.nvm-config.sh" "$HOME/.nvm-config.sh"
ok "dotfiles setup correctly"

### System changes

ask "setup system?"
if [[ $REPLY =~ (yes|y|Y) ]]; then
    # Restart automatically if the computer freezes
    sudo systemsetup -setrestartfreeze on
    # Never go into computer sleep mode
    sudo systemsetup -setcomputersleep Off >/dev/null
    # Disable press-and-hold for keys in favor of key repeat
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    # Enable subpixel font rendering on non-Apple LCDs
    defaults write NSGlobalDomain AppleFontSmoothing -int 2

    ### FINDER
    # Allow quitting via ⌘ + Q; doing so will also hide desktop icons
    defaults write com.apple.finder QuitMenuItem -bool true
    # Disable window animations and Get Info animations
    defaults write com.apple.finder DisableAllAnimations -bool true
    # Show hidden files by default
    defaults write com.apple.finder AppleShowAllFiles -bool true
    # Show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true
    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true
    # Allow text selection in Quick Look
    defaults write com.apple.finder QLEnableTextSelection -bool true
    # Display full POSIX path as Finder window title
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    # Enable spring loading for directories
    defaults write NSGlobalDomain com.apple.springing.enabled -bool true
    # running "Remove the spring loading delay for directories
    defaults write NSGlobalDomain com.apple.springing.delay -float 0
    # Avoid creating .DS_Store files on network volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    # Disable the warning before emptying the Trash
    defaults write com.apple.finder WarnOnEmptyTrash -bool false
    # Empty Trash securely by default
    defaults write com.apple.finder EmptyTrashSecurely -bool true

    ### DOCK
    # Set the icon size of Dock items to 36 pixels
    defaults write com.apple.dock tilesize -int 36
    # Change minimize/maximize window effect to scale
    defaults write com.apple.dock mineffect -string "scale"
    # Minimize windows into their application’s icon"
    defaults write com.apple.dock minimize-to-application -bool true
    # Enable spring loading for all Dock items
    defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
    # Show indicator lights for open applications in the Dock
    defaults write com.apple.dock show-process-indicators -bool true
    # Don’t animate opening applications from the Dock"
    defaults write com.apple.dock launchanim -bool false
    # Speed up Mission Control animations
    defaults write com.apple.dock expose-animation-duration -float 0.1
    # Remove the auto-hiding Dock delay
    defaults write com.apple.dock autohide-delay -float 0
    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true
    # Make Dock icons of hidden applications translucent"
    defaults write com.apple.dock showhidden -bool true
fi
