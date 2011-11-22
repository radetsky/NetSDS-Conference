########################################################################
# Including this file at the beginning of an AGI script written for
# either ash or bash will get a number of variables passed by Asterisk 
# (e.g., agi_request etc.: see http://gundy.org/asterisk/agi.html ) 
# and store them in shell variables with names such as sh_agi_request 
# etc.  (complete list of variable names in sh_agi_vars). Also, it
# will define the following procedures:
#
# - sh_agi_log: sends a line to console, with an optional level of verbosity.
# - sh_agi_cmd: executes an AGI command and sets two shell variables, 
#               sh_agi_response and sh_agi_result (see AGI documentation).
# - sh_agi_getvariable: accesses a single Asterisk variable such as EXTEN
#   and copies it into a shell variable (in this case, sh_agi_EXTEN).
# - sh_agi_setvariable: set varible command
#
# $1, $2 etc. are left set to the parameters passed to the script. 
# For instance, a call like:
#
#   exten => s,1,AGI,agi-test.agi|some|params
# or
#   exten => s,1,AGI(agi-test.agi,some,params)
#
# will result in $# being set to 2, $1 to "some", $2 set to 
# "params" (sans quotes). Any double quotes in the parameters
# will be removed.
#
# NOTE: as usual, the include line for this file must start with ". ", e.g.:
#
# . sh_agi.inc
#
#####################################################################

# sends the command passed as parameter. When it returns, sh_agi_response
# is set to the 3-digit numeric code, and, if the former is 200,
# sh_agi_result is set to the result following the '=' (sometimes
# only a number, sometimes a number and a parenthesized string).
#
sh_agi_cmd() {		# command arg [arg...]
	local sh_agi_tmp_respline
	# send command to stdout
	echo "$*"
	# read reply from stdin
	while read sh_agi_tmp_respline; do
		sh_agi_response=$(echo "${sh_agi_tmp_respline}" | cut -d ' ' -f 1)
		case "$sh_agi_response" in
		"200" ) 
			sh_agi_result=$(echo "${sh_agi_tmp_respline}" | cut -d '=' -f 2)
	        	break;;
		"510" ) 
	        	break;;	
		"520" ) 
	        	break;;
		esac
	done
	return
}

# copies Asterisk variable into shell variable of same name prefixed by sh_agi
# If Asterisk variable is not set, also the shell variable will be left unset
#
sh_agi_getvariable() {
	sh_agi_cmd GET VARIABLE "$1"
	case "$sh_agi_result" in
	1*)
		# result start with 1. Let's get the string between parentheses
		eval sh_agi_"$1"=\"$(echo "$sh_agi_result"|sed -e 's/.*(\([^)]*\)).*/\1/')\"
	;;
	esac
}

sh_agi_setvariable() {
        sh_agi_cmd SET VARIABLE "$1" "$2"
}


# usage: sh_agi_log "string_to_be_logged" [verbosity_level]
#
sh_agi_log() {
	local sh_agi_tmp_dummy
	echo VERBOSE \""$1"\" \""$2"\"
	read sh_agi_tmp_dummy	# VERBOSE only returns one response, ignorable
}

sh_agi_tmp_saveifs="$IFS"
IFS=" "
sh_agi_vars=""
while read sh_agi_tmp_line && [ "$sh_agi_tmp_line" ] ; do
	sh_agi_tmp_line=$(echo "$sh_agi_tmp_line" | sed -e "s/^/sh_/;s/: /='/;s/\(.*\)\$/\1'/")
	case $sh_agi_tmp_line in
	*=*)
	if [ $sh_agi_vars ] ; then
		sh_agi_vars=$sh_agi_vars:$(echo "$sh_agi_tmp_line" | cut -d '=' -f 1)
	else
		sh_agi_vars=$(echo "$sh_agi_tmp_line" | cut -d '=' -f 1)
	fi
	eval "$sh_agi_tmp_line"
	;;
	esac
done
unset sh_agi_tmp_line

IFS="$sh_agi_tmp_saveifs"
unset sh_agi_tmp_saveifs

# show variables passed by asterisk 
#sh_agi_log  "sh_agi_request=$sh_agi_request"
#sh_agi_log  "sh_agi_channel=$sh_agi_channel"
#sh_agi_log  "sh_agi_language=$sh_agi_language"
#sh_agi_log  "sh_agi_type=$sh_agi_type"
#sh_agi_log  "sh_agi_uniqueid=$sh_agi_uniqueid"
#sh_agi_log  "sh_agi_callerid=$sh_agi_callerid"
#sh_agi_log  "sh_agi_dnid=$sh_agi_dnid"
#sh_agi_log  "sh_agi_rdnis=$sh_agi_rdnis"
#sh_agi_log  "sh_agi_context=$sh_agi_context"
#sh_agi_log  "sh_agi_extension=$sh_agi_extension"
#sh_agi_log  "sh_agi_priority=$sh_agi_priority"
#sh_agi_log  "sh_agi_enhanced=$sh_agi_enhanced"
#sh_agi_log  "sh_agi_accountcode=$sh_agi_accountcode"
# Show number of params and params list

#sh_agi_log "=== an: $# av: $*"

