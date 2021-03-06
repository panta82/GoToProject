[[ -z "${THIS_DIR}" ]] && THIS_DIR="$(cd $(dirname $0) && pwd)"

fatal() {
	echo "FATAL: " $@ >&2
	exit 1
}

load_settings() {
	REMOTE_SOURCE_PATH="https://raw.githubusercontent.com/panta82/GoToProject/master/gotoproject.sh"
	WEBSITE="https://github.com/panta82/GoToProject"
	DIALOG_COMMAND=""
	
	DEFAULT_ROOT='$HOME/dev'
	DEFAULT_DEPTH='3'
	DEFAULT_EXCLUDE='node_modules,.git'
	DEFAULT_ALIAS='gd'
	
	GTP_ROOT=''
	GTP_DEPTH=''
	GTP_EXCLUDE=''
	GTP_ALIAS=''
	
	GTP_COMMAND_STAT=''
}

detect_dialog_command() {
	if [[ ! -z $DIALOG_COMMAND ]]; then
		return
	fi
	if command -v dialog >/dev/null 2>&1; then
		DIALOG_COMMAND="dialog --keep-tite"
	elif command -v whiptail >/dev/null 2>&1; then
		DIALOG_COMMAND="whiptail"
	else
		fatal "No dialog program found. Try installing 'dialog' or 'whiptail'"
	fi
}

detect_environment() {
	local bash_version_regex='^4\.[3-9]|^[5-9]'
	[[ $BASH_VERSION =~ $bash_version_regex ]] || fatal "GoToProject requires minimum bash 4.3"

	local sysname="$(uname -s)"
	if [[ $sysname = "Linux" ]]; then
		GTP_COMMAND_STAT='stat'
	elif [[ $sysname = "Darwin" ]]; then
		[[ $(type -t gstat) == "file" ]] || fatal "Requirement missing: coreutils. Try: brew install coreutils"
		GTP_COMMAND_STAT='gstat'
	else
		fatal "Unsupported nix type: $sysname"
	fi
}

prepare_source() {
	source_path="${THIS_DIR}/gotoproject.sh"
	if [[ -f ${source_path} ]]; then
		return
	fi
	
	[[ -z ${REMOTE_SOURCE_PATH} ]] \
		&& fatal "No local script source found and no remote path specified" 
	
	hash wget 2>/dev/null \
		|| fatal "'wget' command not found. Either install wget, or do the manual install"
	
	source_path="/tmp/gotoproject.sh.$!"
	wget -O ${source_path} -q ${REMOTE_SOURCE_PATH} \
		|| fatal "Failed to download script source code from ${REMOTE_SOURCE_PATH}"
}

_do_show_dialog() {
	local cmd="$DIALOG_COMMAND $1"
	local normalize="$2"
	local exit_code
	
	# Show dialog
	tput smcup
	clear
	exec 7>&1
	DIALOG_RESULT=$(
		( bash -c "$cmd" >&7 ) 2>&1
	)
	exit_code="$?"
	exec 7>&-
	tput rmcup

	if [[ "$2" = "true" ]]; then
		# Normalize true/false result
		if [[ -z "$DIALOG_RESULT" && $exit_code -le 1 ]]; then
			if [[ $exit_code = 0 ]]; then
				DIALOG_RESULT=true
			else
				exit_code=0
				DIALOG_RESULT=false
			fi
		fi
	fi

	return $exit_code
}

welcome_screen() {
	_do_show_dialog "--title 'GoToProject Install Wizard' --msgbox '\n
	Hello! This wizard will help you install GoToDev onto your machine. \n
	\n
	The final product of this process will be an added function \n
	and alias inside your $HOME/.bashrc file \n
	\n
	For more information, please visit ${WEBSITE} \n
	\n
	Press enter to start the installation or ESC to cancel. \n
	' 15 85" \
		|| fatal "Installation cancelled"
}

input_root() {
	[[ ! -z $GTP_ROOT ]] && return 
	_do_show_dialog "--title 'Projects root' --inputbox 'Enter the path where you keep your projects (tip: you can enter \$HOME for your home folder)' 10 40 '$DEFAULT_ROOT'" \
		|| fatal "Installation cancelled"
	GTP_ROOT="$DIALOG_RESULT"
}

input_depth() {
	[[ ! -z $GTP_DEPTH ]] && return 
	_do_show_dialog "--title 'Search depth' --inputbox 'Max depth when searching through your project hiearchy' 10 40 '$DEFAULT_DEPTH'" \
		|| fatal "Installation cancelled"
	GTP_DEPTH="$DIALOG_RESULT"
}

input_exclude() {
	[[ ! -z $GTP_EXCLUDE ]] && return 
	_do_show_dialog "--title 'Exclude list' --inputbox 'Comma-separated list of directories to exclude from search' 10 40 '$DEFAULT_EXCLUDE'" \
		|| fatal "Installation cancelled"
	GTP_EXCLUDE="$DIALOG_RESULT"
}

input_alias() {
	[[ ! -z $GTP_ALIAS ]] && return 
	_do_show_dialog "--title 'Command alias' --inputbox 'Alias under which to install GoToProject (this is what you type in your console to run the command)' 10 40 '$DEFAULT_ALIAS'" \
		|| fatal "Installation cancelled"
	GTP_ALIAS="$DIALOG_RESULT"
}

generate_code() {
	cat <<EOF
#[GO_TO_PROJECT_CODE_START]

# #############
# GoToProject #
###############
#
# For details and license, please visit: ${WEBSITE}
#

GO_TO_PROJECT_ROOT="$GTP_ROOT"
GO_TO_PROJECT_DEPTH=$GTP_DEPTH
GO_TO_PROJECT_STAT="$GTP_COMMAND_STAT"
GO_TO_PROJECT_EXCLUDE_DIRS="$GTP_EXCLUDE"

EOF

	cat $source_path
	
	cat <<EOF

alias $GTP_ALIAS=go_to_project

#[GO_TO_PROJECT_CODE_END]
EOF
}

do_output_to_file() {
	local target_path="$1"
	
	touch $target_path
	local tmp_filename="/tmp/gtp_target.$!"
	sed -e '1h;2,$H;$!d;g' -e 's/\n*#\[GO_TO_PROJECT_CODE_START\].*#\[GO_TO_PROJECT_CODE_END]\n*/\
/' $target_path > $tmp_filename \
		|| fatal "Failed to process $target_path"
	{ cat $tmp_filename ; echo "" ; generate_code ; } > $target_path
}

do_install_file() {
    local file="$1"
    
    do_output_to_file "$file"
	cat <<EOF
GoToProject was installed to $file
	
To activate the command right now, execute

	source $file

Or just restart your active terminal session(s).
You can re-run this installer at any time to change the options, or do so manually by editing .bashrc.

EOF
}

do_install_bashrc() {
	do_install_file "$HOME/.bashrc"
}

do_install_bash_profile() {
	do_install_file "$HOME/.bash_profile"
}

do_install_stdout() {
	generate_code
}

confirmation() {
	_do_show_dialog "--title 'Ready to install' --menu '\n
	GoToProject is ready to be installed with the following options:\n
	     Root: $GTP_ROOT \n
	    Depth: $GTP_DEPTH \n
	    Alias: $GTP_ALIAS \n
	\n
	Please chose the install target
	' 17 70 4 bashrc 'Modify your $HOME/.bashrc' bash_profile 'Modify your $HOME/.bash_profile' stdout 'Print the code into the terminal'" \
		|| fatal "Installation cancelled"
	
	local fn="do_install_${DIALOG_RESULT}"

	$fn
}

main() {
	load_settings
	detect_dialog_command
	detect_environment
	prepare_source
	
	welcome_screen
	input_root
	input_depth
	input_exclude
	input_alias
	
	confirmation
}

main