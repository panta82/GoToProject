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
	DEFAULT_ALIAS='gd'
	
	GTP_ROOT=''
	GTP_DEPTH=''
	GTP_ALIAS=''
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
	The final product of this process will be: \n
		- an added function and alias inside your $HOME/.bashrc file \n
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
_GO_TO_PROJECT_FILE_NAME_CUTOFF_LENGTH=`expr ${#GO_TO_PROJECT_ROOT} + 1`

EOF
	cat $source_path
	cat <<EOF

alias $GTP_ALIAS=go_to_project

#[GO_TO_PROJECT_CODE_END]
EOF
}

do_output_to_file() {
	local target_path="$1"
	
	local tmp_filename="/tmp/gtp_target.$!"
	sed -e '1h;2,$H;$!d;g' -re 's/\n*#\[GO_TO_PROJECT_CODE_START\].*#\[GO_TO_PROJECT_CODE_END]\n*//' $target_path > $tmp_filename
	{ cat $tmp_filename ; echo "" ; generate_code ; } > $target_path
}

do_install_bashrc() {
	do_output_to_file "$HOME/.bashrc"
	echo "GoToProject was installed to $HOME/.bashrc"
	echo ""
	echo "To activate the command right now, execute 'source \$HOME/.bashrc'"
	echo "Or just restart the terminal session(s)"
	echo ""
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
	' 17 70 2 bashrc 'Modify your $HOME/.bashrc' stdout 'Print the code into the terminal'" \
		|| fatal "Installation cancelled"
	
	local fn="do_install_${DIALOG_RESULT}"

	$fn
}

main() {
	load_settings
	detect_dialog_command
	prepare_source
	
	welcome_screen
	input_root
	input_depth
	input_alias
	
	confirmation
}

main