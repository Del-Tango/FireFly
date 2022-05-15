#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# GENERAL

function process_cli_args() {
    local ARGUMENTS=( $@ )
    local FAILURE_COUNT=0
    if [ ${#ARGUMENTS[@]} -eq 0 ]; then
        return 1
    fi
    for opt in "${ARGUMENTS[@]}"; do
        case "$opt" in
            -h|--help)
                display_usage
                exit 0
                ;;
            -pS=*|--plumbing-signal=*)
                local SIGNAL="${opt#*=}"
                cli_action_plumbing_signal "${SIGNAL}"
                if [ $? -ne 0 ]; then
                    local FAILURE_COUNT=$((FAILURE_COUNT + 1))
                fi
                ;;
            -PS=*|--porcelain-signal=*)
                local SIGNAL="${opt#*=}"
                cli_action_porcelain_signal "${SIGNAL}"
                if [ $? -ne 0 ]; then
                    local FAILURE_COUNT=$((FAILURE_COUNT + 1))
                fi
                ;;
            *)
                echo "[ WARNING ]: Invalid CLI arg! (${opt})"
                ;;
        esac
    done
    return $FAILURE_COUNT
}

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
