#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# GENERAL

function issue_signal_to_lamp_controller_over_serial() {
    local SIGNAL="$1"
    local SIG_TYPE="${2:-porcelain}"
    case "${SIG_TYPE}" in
        'porcelain')
            local ARGUMENTS=( `format_serial_signal_cargo_arguments "${SIGNAL}"` )
            ;;
        'plumbing')
            local ARGUMENTS=( `format_low_level_serial_signal_cargo_arguments "${SIGNAL}"` )
            ;;
        *)
            warning_msg "Invalid signal type! (${RED}${SIG_TYPE}${RESET})"
            return 1
            ;;
    esac
    echo "
[ INFO ]: About to execute (${MAGENTA}`format_cargo_exec_string ${ARGUMENTS[@]}`${RESET})"
    action_firefly_cargo ${ARGUMENTS[@]}
    return $?
}
