#!/bin/bash
#
# <ProvidedScriptName>
# Script Metadata & Description
#
# Options Format:
# The SCRIPT_OPTS is an array who's keys are as follows,
#   <regex>:<varname>
#
# The first part before the colon is a standard Regex to match against
# the given options, i.e. (-d|--date)
#
# The second part is the key used as the variable name. This name will be exported
# as OPTS_<varname>, i.e. OPTS_DATE
#
# A complete example of this: (-d|--date):DATE
SCRIPT_NAME="<ProvidedScriptName>"
SCRIPT_VER="1.0.0"
SCRIPT_OPTS=("")
SCRIPT_CATCHALL="no"   # Must be either "yes" or "no", enables a '_catchall' method executed when no command given

# Print Usage for CLI
function _help () {
    echo -e "${SCRIPT_NAME}\n"
    echo -e "-v|--version  To display script's version"
    echo -e "-h|--help     To display script's help\n"
    echo -e "Available commands:\n"
    echo -e "methods       To display script's methods"
    _available-methods
    exit 0
}

# Print CLI Version
function _version () {
    echo -e "${SCRIPT_NAME}" 1>&2
    echo -en "Version " 1>&2
    echo -en "${SCRIPT_VER}"
    echo -e "" 1>&2
    exit 0
}

# List all the available public methods in this CLI
function _available-methods () {
    METHODS=$(declare -F | grep -Eoh '[^ ]*$' | grep -Eoh '^[^_]*' | sed '/^$/d')
    if [ -z "${METHODS}" ]; then
        echo -e "No methods found, this is script has a single entry point." 1>&2
    else
        echo -e "${METHODS}"
    fi
    exit 0
}

# Dispatches CLI Methods
function _handle () {
    METHOD=$(_available-methods | grep -Eoh "^${1}\$")
    if [ "x${METHOD}" != "x" ]; then ${METHOD} ${@:2}; exit 0
    else
        # Call a Catch-All method
        if [ "${SCRIPT_CATCHALL}" == "yes" ]; then _catchall ${@}; exit 0
        # Display usage options
        else echo -e "Method '${1}' is not found.\n"; _help; fi
    fi
}

#
# User Implementation Begins
#
# Catches all executions not performed by other matched methods
function _catchall () {
    exit 0
}

# ...
function some-method () {
    exit 0
}


#
# User Implementation Ends
# Do not modify the code below this point.
#
# Main Method Switcher
# Parses provided Script Options/Flags. It ensures to parse
# all the options before routing to a metched method.
#
# `<script> methods` is used for auto completion scripts
ARGS=(); EXPORTS=(); while test $# -gt 0; do
    OPT_MATCHED=0; case "${1}" in
        -h|--help) OPT_MATCHED=$((OPT_MATCHED+1)); _help ;;
        -v|--version) OPT_MATCHED=$((OPT_MATCHED+1)); _version ;;
        methods) OPT_MATCHED=$((OPT_MATCHED+1)); _available-methods ;;
        *)  # Where the Magic Happens!
        if [ ${#SCRIPT_OPTS[@]} -gt 0 ]; then for OPT in ${SCRIPT_OPTS[@]}; do
        OPT_MATCH=$(echo ${OPT} | grep -Eoh "^.*?:" | sed 's/://')
        OPT_KEY=$(echo ${OPT} | grep -Eoh ":.*?$" | sed 's/://')
        OPT_VARNAME="OPTS_${OPT_KEY}"
        if [ -z "${OPT_VARNAME}" ]; then echo "Invalid Option Definition, missing VARNAME: ${OPT}" 1>&2; exit 1; fi
        if [[ ${1} =~ ^${OPT_MATCH}$ ]]; then
            OPT_VAL="${OPT_VARNAME}"; OPT_MATCHED=$((OPT_MATCHED+1))
            if [ -n "${2}" -a $# -gt 2 ] && [[ ! "${2}" =~ ^-+ ]]; then OPT_VAL="${2}"; shift; fi
            if [ -n "${!OPT_VARNAME}" ]; then OPT_VAL="${!OPT_VARNAME};${OPT_VAL}"; fi
            declare "${OPT_VARNAME}=${OPT_VAL}"
            EXPORTS+=("${OPT_VARNAME}")
            shift
        fi; done; fi ;;
    esac
    if [ ${OPT_MATCHED} -eq 0 ]; then if [[ ${1} =~ ^-+ ]]; then
        if [ -n ${2} ] && [[ ! ${2} =~ ^-+ ]]; then shift; fi; shift
    else ARGS+=("${1}"); shift; fi; fi
done
EXPORTS_UNIQ=$(echo "${EXPORTS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
for EXPORT in ${EXPORTS_UNIQ[@]}; do if [[ ${!EXPORT} == *";"* ]]; then
    TMP_VAL=(); for VAL in $(echo ${!EXPORT} | tr ";" "\n"); do TMP_VAL+=("${VAL}"); done
    eval ''${EXPORT}'=("'${TMP_VAL[@]}'")'
fi; done; _handle ${ARGS[@]}; exit 0
