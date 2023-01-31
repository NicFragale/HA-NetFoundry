#!/bin/bash
###################################################################################################################
# HAHelper - A helper utility that adds functions and variables to the HA shell.
# 20220517 Written by Nic Fragale.
###################################################################################################################

#######################################################################################
# Variables and Aliases
#######################################################################################
# Prompt.
export PS1='$(RC=$?; if [[ ${RC} == 0 ]]; then echo "\[\e[1;92;40m\]\u@\h \w>"; else echo "(${RC}) \[\e[1;91;40m\]\u@\h \w>"; fi)\[\e[0;0m\] '

#######################################################################################
# Helper Functions
#######################################################################################
#################################################################################
# A function to colorize the output context to screen.
function ColorText {
	# Colors.
	Normal="0" Gray="29" Red="31" SuperRed="41" Green="32" Yellow="33" Blue="36" Purple="35"
	# Gather details.
	local FXColor="$1"
	local FXHeader
	case ${FXColor} in
		"GREEN") FXColor="${Green}"; FXHeader="SUCCESS";;
		"YELLOW") FXColor="${Yellow}"; FXHeader="WARN";;
		"RED") FXColor="${Red}"; FXHeader="ERROR";;
		"SUPERRED") FXColor="${SuperRed}"; FXHeader="FATAL";;
		"BLUE") FXColor="${Blue}"; FXHeader="QUESTION";;
		"PURPLE") FXColor="${Purple}"; FXHeader="ATTENTION";;
		*) FXColor="${Gray}"; FXHeader="INFO";;
	esac
	shift 1
	CommentText="$*"

	# Output.
	printf "\e[7;${FXColor}m[%-10s]\e[1;${Normal}m %s\n" "${FXHeader}" "${CommentText}"
}

#################################################################################
# Elicit a variable response from the user.
function GetResponse() {
	local InputQuestion="${1}" DefaultAnswer="${2}"
	local REPLY
	unset REPLY UserResponse

	# Do not allow blank or passed in NONE to be an answer.
	while :; do

		# A request for RESPONSE is a statement for an arbitrary answer.
		ColorText "RESPONSE" "${InputQuestion} [QUIT=QUIT]"

		# Get the answer.
		read -rp "Response? [DEFAULT=\"${DefaultAnswer}\"] > "
		if [[ ${REPLY:-NONE} == "NONE" ]] && [[ ${DefaultAnswer:-NONE} != "NONE" ]]; then
			UserResponse="${DefaultAnswer}"
		elif [[ ${REPLY:-NONE} == "NONE" ]] && [[ ${DefaultAnswer:-NONE} == "NONE" ]]; then
			ColorText "ERROR" "Invalid response \"${REPLY:-NO INPUT}\", try again."
			sleep 1
			continue
		elif [[ ${REPLY:-NONE} == "QUIT" ]]; then
			exit 0
		else
			UserResponse="${REPLY}"
		fi

		return 0

	done
}

#################################################################################
# Elicit a YES or NO from the user.
function GetYorN() {
	local InputQuestion="${1}" DefaultAnswer="${2}" TimerVal="${3}"
	unset REPLY UserResponse

	# Loop until a decision is made.
	while :; do

		# Get the answer.
		if [[ ${TimerVal} ]]; then
			# A request for YES OR NO is a question only.
			ColorText "YES OR NO" "${InputQuestion}"
			! read -rt "${TimerVal}" -p "Yes or No? [DEFAULT=\"${DefaultAnswer}\"] [TIMEOUT=${TimerVal}s] > " \
				&& printf '%s\n' "[TIMED OUT, DEFAULT \"${DefaultAnswer}\" SELECTED]" \
				&& sleep 1
		elif [[ ${InputQuestion} == "SPECIAL-PAUSE" ]]; then
			read -rp "Press ENTER to Continue > "
			unset REPLY
			return 0
		else
			# A request for YES OR NO is a question only.
			ColorText "YES OR NO" "${InputQuestion}"
			read -rp "Yes or No? [DEFAULT=\"${DefaultAnswer}\"] > "
		fi

		# If there was no reply, take the default.
		[[ ${REPLY:-NONE} == "NONE" ]] \
			&& REPLY="${DefaultAnswer}"

		# Find out which reply was given.
		case ${REPLY} in
			Y|YE|YES|YEs|Yes|yes|ye|y)
				unset REPLY
				return 0
			;;
			N|NO|No|no|n)
				unset REPLY
				return 1
			;;
			QUIT)
				exit 0
			;;
			*)
				ColorText "ERROR" "Invalid response \"${REPLY:-NO INPUT}\", try again."
				unset REPLY
				sleep 1
				continue
			;;
		esac

	done
}

#################################################################################
# Elicit a selection response from the user.
function GetSelection() {
	local i REPLY SelectionList SelectionItem TMP_DefaultAnswer COLUMNS
	local InputQuestion InputAllowed InputAllowed DefaultAnswer MaxLength
	InputQuestion="${1}"
	InputAllowed=( "QUIT" ${2} )
	DefaultAnswer="${3}"
	TimerVal="${4}"
	MaxLength="0"
	unset SELECTION UserResponse PS3

	# Prompt text.
	PS3="#? > "

	# Make the selections easy to read if they have the => delimiter.
	for ((i=0;i<${#InputAllowed[*]};i++)); do
		SelectionItem=( ${InputAllowed[${i}]/=>/${NewLine}=>} )
		if [[ ${#SelectionItem[0]} -gt 65 ]]; then
			MaxLength="65"
		elif [[ ${#SelectionItem[0]} -gt ${MaxLength} ]]; then
			MaxLength="${#SelectionItem[0]}"
		fi
	done

	# Build the list in a readable format.
	for ((i=0;i<${#InputAllowed[*]};i++)); do
		SelectionItem=( ${InputAllowed[${i}]/=>/${NewLine}=>} )
		SelectionList[${i}]="$(printf "%-${MaxLength}s %-s\n" "${SelectionItem[0]}" "${SelectionItem[1]}")"
	done

	# Loop until a decision is made.
	while :; do

		# If there is a default, a prompt will appear to accept it or move to the selection.
		if [[ ${DefaultAnswer:-NONE} != "NONE" ]]; then
			# This is a statement for a request of a selection.
			ColorText "SELECTION" "${InputQuestion}"
			TMP_DefaultAnswer=${DefaultAnswer}
			GetYorN "Keep selection of \"${DefaultAnswer}\"?" "Yes" "${TimerVal}" \
				&& UserResponse=${TMP_DefaultAnswer} \
				&& break
		fi

		# Otherwise, get the selection.
		ColorText "SELECTION" "${InputQuestion}"
		COLUMNS="1" # Force select statement into a single column.
		select SELECTION in ${SelectionList[*]}; do
			if { [[ "${REPLY}" == "QUIT" ]]; } || { [[ 1 -le "${REPLY}" ]] && [[ "${REPLY}" -le ${#SelectionList[*]} ]]; }; then
				case ${REPLY} in
					1|"QUIT")
						exit 0
					;;
					*)
						UserResponse="${InputAllowed[$((REPLY-1))]}"
						return 0
					;;
				esac
			else
				ColorText "ERROR" "Invalid response \"${REPLY}/${SELECTION:-NO MATCH}\", try again."
				sleep 1
			fi
			ColorText "SELECTION" "${InputQuestion}"
		done

	done
}

#################################################################################
# Get a list of current containers.
function GetContainers() {
    for EachID in $(docker ps -q); do
        ContainerInfo[$(docker inspect -f '{{.Name}}' ${EachID} | sed 's/\///')]="${EachID}"
    done
}

#######################################################################################
# Main Functions
######################################################################################
#################################################################################
# Login to a container.
function LoginContainer() {
	local ContainerInfo EachID ContainerInfo
	declare -A ContainerInfo
    GetContainers
	if GetSelection "Login to which container?" "ROOTOS ${!ContainerInfo[*]}" "NONE" "15"; then
		[[ ${UserResponse} != "ROOTOS" ]] \
			&& docker exec -it ${ContainerInfo[${UserResponse}]} bash \
			|| docker run --privileged --pid=host -it alpine:latest nsenter -t 1 -m -u -n -i bash
	fi
}

#################################################################################
# Get networking information from the container(s).
function GetContainerNetworking() {
	local ContainerInfo EachID ContainerInfo
	declare -A ContainerInfo
    GetContainers
	if GetSelection "Which container?" "ALL ${!ContainerInfo[*]}" "NONE" "15"; then
		if [[ ${UserResponse} == "ALL" ]]; then
			for EachContainer in ${ContainerInfo[*]}; do
				docker inspect -f '[{{.Name}}] {{range.NetworkSettings.Networks}}{{.IPAddress}}->{{.Gateway}} {{end}} | {{.HostConfig.Dns}}' ${EachContainer}
			done
		else
			echo -n "[${UserResponse}] "
			docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}->{{.Gateway}} {{end}} | {{.HostConfig.Dns}}' ${UserResponse}
		fi
	fi
}

#######################################################################################
# EOFEOFEOFOEFEOFEOFEOFOEFEOFEOFEOFOEFEOFEOFEOFOEFEOFEOFEOFOEFEOFEOFEOFOEFEOFEOFEOFOEF
#######################################################################################

# IPTABLES to block the Insteon from communicating to DNS.
# iptables -I PREROUTING -t raw -i eth1 -d 10.20.100.1 -p tcp --dport 53 -j DRO
# iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
# iptables -A FORWARD -i eth1 -o eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
# iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE
