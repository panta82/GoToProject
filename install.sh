[[ -z "${THIS_DIR}" ]] && THIS_DIR="$(cd $(dirname $0) && pwd)"

fatal() {
	echo "FATAL: " $@
	exit 1
}

load_settings() {
	REMOTE_PATH=""
	DIALOG_COMMAND=""
	
	DEFAULT_ROOT='$HOME/dev'
	DEFAULT_DEPTH='3'
	
	GO_TO_PROJECT_ROOT=''
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

determine_source_path() {
	source_path="${THIS_DIR}/gotoproject.sh"
	if [[ ! -f ${source_path} ]]; then
		echo "TODO"
		exit 1
	fi
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

input_root() {
	[[ ! -z $GO_TO_PROJECT_ROOT ]] && return 
	_do_show_dialog "--title 'Root path' --inputbox 'Enter the path where you keep your projects (tip: you can enter \$HOME for your home folder)' 10 40 '$DEFAULT_ROOT'" \
		|| fatal "Installation cancelled"
	GO_TO_PROJECT_ROOT="$DIALOG_RESULT"
}



main() {
	load_settings
	detect_dialog_command
	determine_source_path
	
	input_root
}

main