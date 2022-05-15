#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# ACTIONS

function action_update_skeleton_chat_config_file() {
    local FILE_CONTENT="`format_skeleton_chat_config_file_content`"
    debug_msg "Formatted SkeletonChat config file content: ${FILE_CONTENT}"
    if [ $? -ne 0 ] || [ -z "$FILE_CONTENT" ]; then
        echo; nok_msg 'Something went wrong -'\
            'Could not format SkeletonChat config file content!'
        return 0
    fi
    clear_file "${FF_DEFAULT['sklc-conf-file']}"
    write_to_file "${FF_DEFAULT['sklc-conf-file']}" "$FILE_CONTENT"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong -"\
            "Could not update SkeletonChat config file"\
            "(${RED}${FF_DEFAULT['sklc-conf-file']}${RESET})"
    else
        echo "$FILE_CONTENT
        "
        ok_msg "Successfully updated SkeletonChat config file"\
            "(${GREEN}${FF_DEFAULT['sklc-conf-file']}${RESET})."
    fi
    return $EXIT_CODE
}

function action_skeleton_chat() {
    cd `dirname "${FF_CARGO['skeleton-chat']}"` && ${FF_CARGO['skeleton-chat']}; cd - &> /dev/null
    return $?
}

function cli_action_plumbing_signal() {
    local SIGNAL="$@"
    local ARGUMENTS=( `format_low_level_serial_signal_cargo_arguments "${SIGNAL}"` )
    action_firefly_cargo ${ARGUMENTS[@]}
    return $?
}

function cli_action_porcelain_signal() {
    local SIGNAL="$@"
    local ARGUMENTS=( `format_serial_signal_cargo_arguments "${SIGNAL}"` )
    action_firefly_cargo ${ARGUMENTS[@]}
    return $?
}

function cli_update_config_json_file() {
    local FILE_CONTENT="`format_config_json_file_content`"
    if [ $? -ne 0 ] || [ -z "$FILE_CONTENT" ]; then
        return 1
    fi
    echo "${FILE_CONTENT}" > ${MD_DEFAULT['conf-json-file']}
    return $?
}

function action_setup_procedure() {
    echo; info_msg "About to execute (${BLUE}${SCRIPT_NAME}${RESET}) setup procedure sketch... (${MAGENTA}${FF_PROCEDURES['setup']}${RESET})"
    if [[ "${MD_DEFAULT['action-prompt']}" == 'on' ]]; then
        fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
        if [ $? -ne 0 ]; then
            info_msg "Aborting action."
            return 0
        fi
    fi
    flowctrl_start "${FF_PROCEDURES['setup']}"
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: Purging previous FlowCtrl session..."
        flowctrl_purge
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong! Could not purge previous FlowCtrl session!"
            return 1
        fi
        flowctrl_start "${FF_PROCEDURES['setup']}"
    fi
    return $?
}

function action_plumbing_signal() {
    echo; info_msg "Issue plumbing signal to (${BLUE}${SCRIPT_NAME}${RESET}) LAMP controller or (${MAGENTA}.back${RESET})-"
    display_available_plumbing_signals
    local SIGNAL=`fetch_string_from_user 'LAMP-CTRL'`
    if [ $? -ne 0 ] || [ -z "$SIGNAL" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    validate_plumbing_signal "${SIGNAL}"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Invalid plumbing SPL signal! (${RED}${SIGNAL}${RESET})"
        return $EXIT_CODE
    fi
    issue_signal_to_lamp_controller_over_serial "${SIGNAL}" 'plumbing'
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not issue plumbing signal over serial to LAMP controller."\
            "(${RED}$SIGNAL${RESET})"
    else
        ok_msg "Successfully sent plumbing signal over serial to LAMP controller."\
            "(${GREEN}$SIGNAL${RESET})"
    fi
    return $EXIT_CODE
}

function action_firefly_cargo() {
    local ARGUMENTS=( $@ )
    trap 'trap - SIGINT; echo ''[ SIGINT ]: Aborting action.''; return 0' SIGINT
    echo; ${FF_CARGO['firefly']} ${ARGUMENTS[@]}; local EXIT_CODE=$?; trap - SIGINT
    return $EXIT_CODE
}

function action_porcelain_signal() {
    echo; info_msg "Issue porcelain signal to (${BLUE}${SCRIPT_NAME}${RESET}) LAMP controller or (${MAGENTA}.back${RESET}) -"
    display_available_porcelain_signals
    local SIGNAL=`fetch_string_from_user 'LAMP-CTRL'`
    if [ $? -ne 0 ] || [ -z "$SIGNAL" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    validate_porcelain_signal "${SIGNAL}"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Invalid porcelain SPL signal! (${RED}${SIGNAL}${RESET})"
        return $EXIT_CODE
    fi
    issue_signal_to_lamp_controller_over_serial "${SIGNAL}"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not issue porcelain signal over serial to LAMP controller."\
            "(${RED}$SIGNAL${RESET})"
    else
        ok_msg "Successfully sent porcelain signal over serial to LAMP controller."\
            "(${GREEN}$SIGNAL${RESET})"
    fi
    return $EXIT_CODE
}

function action_set_config_file() {
    echo; info_msg "Setting config file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_config_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) config file."
    else
        ok_msg "Successfully set config file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_config_json_file() {
    echo; info_msg "Setting JSON config file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_json_config_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) JSON config file."
    else
        ok_msg "Successfully set JSON config file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_update_config_json_file() {
    local FILE_CONTENT="`format_config_json_file_content`"
    debug_msg "Formatted JSON config file content: ${FILE_CONTENT}"
    if [ $? -ne 0 ] || [ -z "$FILE_CONTENT" ]; then
        echo; nok_msg 'Something went wrong -'\
            'Could not format JSON config file content!'
        return 0
    fi
    clear_file "${FF_DEFAULT['conf-json-file']}"
    write_to_file "${FF_DEFAULT['conf-json-file']}" "$FILE_CONTENT"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong -"\
            "Could not update JSON config file"\
            "(${RED}${FF_DEFAULT['conf-json-file']}${RESET})"
    else
        echo "$FILE_CONTENT
        "
        ok_msg "Successfully updated JSON config file"\
            "(${GREEN}${FF_DEFAULT['conf-json-file']}${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_debug_flag() {
    echo; case "${FF_DEFAULT['debug']}" in
        'on'|'On'|'ON')
            info_msg "Debug is (${GREEN}ON${RESET}), switching to (${RED}OFF${RESET}) -"
            action_set_debug_off
            ;;
        'off'|'Off'|'OFF')
            info_msg "Debug is (${RED}OFF${RESET}), switching to (${GREEN}ON${RESET}) -"
            action_set_debug_on
            ;;
        *)
            info_msg "Debug not set, switching to (${GREEN}OFF${RESET}) -"
            action_set_debug_off
            ;;
    esac
    return $?
}

function action_set_silence_flag() {
    echo; case "${FF_DEFAULT['silence']}" in
        'on'|'On'|'ON')
            info_msg "Silence is (${GREEN}ON${RESET}), switching to (${RED}OFF${RESET}) -"
            action_set_silence_off
            ;;
        'off'|'Off'|'OFF')
            info_msg "Silence is (${RED}OFF${RESET}), switching to (${GREEN}ON${RESET}) -"
            action_set_silence_on
            ;;
        *)
            info_msg "Silence not set, switching to (${GREEN}OFF${RESET}) -"
            action_set_silence_off
            ;;
    esac
    return $?
}

# CODE DUMP

