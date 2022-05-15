#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# DISPLAY

function display_usage () {
    clear; display_header; local FILE_NAME="./`basename $0`"
    cat<<EOF

    [ DESCRIPTION ]: ${FF_SCRIPT_NAME} Interface.
    [ USAGE       ]: $FILE_NAME

    -h  | --help                   Display this message.

    -S  | --setup                  Setup machine.

    -a= | --alias=NICKNAME         Implies (--porcelain-signal). Number of times
        |                          the color set as the identification color
        |                          (default of which is white) will blink at the
        |                          beginning of the message.

    -W= | --white=FLASH_NO         Number of times the color white will blink.

    -r= | --red=FLASH_NO           Number of times the color red will blink.

    -g= | --green=FLASH_NO         Number of times the color green will blink.

    -b= | --blue=FLASH_NO          Number of times the color blue will blink.

    -B= | --black=FLASH_NO         Number of times the color set as default on
        |                          receiving terminal will blink.

    -i= | --identification-color=(white|black|red|green|blue)
        |                          Sets the color to be used at the beginning of
        |                          the firefly message in order to identify the
        |                          sender of the message (value of --alias in
        |                          case of --porcelain-signal, translated according
        |                          to the alias map data/ff-alias.json).

    -pS | --plumbing-signal        Starts the watchdog daemon process that
        |                          monitors signals comming through the GPIO
        |                          command pins.

    -PS | --porcelain-signal       Stops the watchdog daemon process that
        |                          monitors signals comming through the GPIO
        |                          command pins.


    [ EXAMPLE     ]:

        $~ $FILE_NAME --setup

        $~ $FILE_NAME --porcelain-signal --white=3 --red=5 --blue=1

EOF
    return $?
}

function display_header () {
    cat <<EOF
    ___________________________________________________________________________

     *                           *   ${BLUE}${FF_SCRIPT_NAME}${RESET}   *                          *
    ___________________________________________________________________________
                    Regards, the Alveare Solutions #!/Society -x
EOF
    return $?
}

function display_server_ctrl_settings () {
    local ARGUMENTS=( `format_display_server_ctrl_settings_args` )
    debug_msg "Displaying settings: (${MAGENTA}${ARGUMENTS[@]}${RESET})"
    display_fg_settings ${ARGUMENTS[@]} && echo
    return $?
}

function display_manual_ctrl_settings () {
    local ARGUMENTS=( `format_display_manual_ctrl_settings_args` )
    debug_msg "Displaying settings: (${MAGENTA}${ARGUMENTS[@]}${RESET})"
    display_fg_settings ${ARGUMENTS[@]} && echo
    return $?
}

function display_main_settings () {
    local ARGUMENTS=( `format_display_main_settings_args` )
    debug_msg "Displaying settings: (${MAGENTA}${ARGUMENTS[@]}${RESET})"
    display_fg_settings ${ARGUMENTS[@]} && echo
    return $?
}

function display_project_settings () {
    local ARGUMENTS=( `format_display_project_settings_args` )
    debug_msg "Displaying settings: (${MAGENTA}${ARGUMENTS[@]}${RESET})"
    display_fg_settings ${ARGUMENTS[@]} | column && echo
    return $?
}

function display_banners () {
    if [ -z "${MD_DEFAULT['banner']}" ]; then
        return 1
    fi
    case "${MD_DEFAULT['banner']}" in
        *','*)
            for cargo_key in `echo ${MD_DEFAULT['banner']} | sed 's/,/ /g'`; do
                ${MD_CARGO[$cargo_key]} "${MD_DEFAULT['conf-file']}"
            done
            ;;
        *)
            ${MD_CARGO[${MD_DEFAULT['banner']}]} "${MD_DEFAULT['conf-file']}"
            ;;
    esac
    return $?
}

function display_serial_port () {
    echo "[ ${CYAN}SPL Serial Port${RESET}          ]: ${BLUE}${MD_DEFAULT['serial-port']}${RESET}"
    return $?
}

function display_serial_reads () {
    echo "[ ${CYAN}SPL Reads No.${RESET}            ]: ${BLUE}${MD_DEFAULT['spl-reads']}${RESET}"
    return $?
}

function display_spl_prefix () {
    echo "[ ${CYAN}SPL Signal Prefix${RESET}        ]: ${BLUE}${MD_DEFAULT['spl-ack-sig']}${RESET}"
    return $?
}

function display_spl_ack_sig () {
    echo "[ ${CYAN}SPL OK Signal${RESET}            ]: ${BLUE}${MD_DEFAULT['spl-ack-sig']}${RESET}"
    return $?
}

function display_spl_err_sig () {
    echo "[ ${CYAN}SPL NOK Signal${RESET}           ]: ${BLUE}${MD_DEFAULT['spl-err-sig']}${RESET}"
    return $?
}

function display_setting_project_path () {
    echo "[ ${CYAN}Project Path${RESET}             ]: ${BLUE}${MD_DEFAULT['project-path']}${RESET}"
    return $?
}

function display_setting_log_dir_path () {
    echo "[ ${CYAN}Log Dir${RESET}                  ]: ${BLUE}${MD_DEFAULT['log-dir']}${RESET}"
    return $?
}

function display_setting_conf_dir_path () {
    echo "[ ${CYAN}Conf Dir${RESET}                 ]: ${BLUE}${MD_DEFAULT['conf-dir']}${RESET}"
    return $?
}

function display_setting_log_file_path () {
    echo "[ ${CYAN}Log File${RESET}                 ]: ${BLUE}`dirname ${MD_DEFAULT['log-file']}`/${YELLOW}`basename ${FF_DEFAULT['log-file']}`${RESET}"
    return $?
}

function display_setting_conf_file_path () {
    echo "[ ${CYAN}Conf File${RESET}                ]: ${BLUE}`dirname ${MD_DEFAULT['conf-file']}`/${YELLOW}`basename ${FF_DEFAULT['conf-file']}`${RESET}"
    return $?
}

function display_setting_conf_json_file_path () {
    echo "[ ${CYAN}Conf JSON${RESET}                ]: ${BLUE}`dirname ${MD_DEFAULT['conf-json-file']}`/${YELLOW}`basename ${FF_DEFAULT['conf-json-file']}`${RESET}"
    return $?
}

function display_setting_log_lines () {
    echo "[ ${CYAN}Log Lines${RESET}                ]: ${WHITE}${MD_DEFAULT['log-lines']}${RESET}"
    return $?
}

function display_setting_debug_flag () {
    echo "[ ${CYAN}Debug${RESET}                    ]: `format_flag_colors ${MD_DEFAULT['debug']}`"
    return $?
}

function display_setting_silence_flag () {
    echo "[ ${CYAN}Silence${RESET}                  ]: `format_flag_colors ${MD_DEFAULT['silence']}`"
    return $?
}

function display_setting_machine_id () {
    echo "[ ${CYAN}Machine ID${RESET}               ]: ${BLUE}`hostname`${RESET}"
    return $?
}

function display_setting_wifi_pass () {
    if [ -z "${FF_DEFAULT['wifi-pass']}" ]; then
        local VALUE="${RED}Not Set${RESET}"
    else
        local VALUE="${GREEN}Locked'n Loaded${RESET}"
    fi
    echo "[ ${CYAN}WiFi PSK${RESET}                 ]: $VALUE"
    return $?
}

function display_local_ipv4_address () {
    local LOCAL_IPV4=`fetch_local_ipv4_address`
    local TRIMMED_STDOUT=`echo -n ${LOCAL_IPV4} | sed 's/\[ WARNING \]: //g'`
    if [[ "${TRIMMED_STDOUT}" =~ "No LAN access!" ]]; then
        local DISPLAY_VALUE="${RED}Unknown${RESET}"
    else
        local DISPLAY_VALUE="${MAGENTA}$LOCAL_IPV4${RESET}"
    fi
    echo "[ ${CYAN}Local IPv4${RESET}               ]: ${DISPLAY_VALUE}"
    return $?
}

function display_external_ipv4_address () {
    local EXTERNAL_IPV4="`fetch_external_ipv4_address`"
    local EXIT_CODE=$?
    local TRIMMED_STDOUT=`echo -n ${EXTERNAL_IPV4} | sed 's/\[ WARNING \]: //g'`
    if [ $EXIT_CODE -ne 0 ] || [[ "${TRIMMED_STDOUT}" =~ "No internet access!" ]]; then
        local DISPLAY_VALUE="${RED}Unknown${RESET}"
    else
        local DISPLAY_VALUE="${MAGENTA}$EXTERNAL_IPV4${RESET}"
    fi
    echo "[ ${CYAN}External IPv4${RESET}            ]: ${DISPLAY_VALUE}"
    return $?
}

function display_fg_settings () {
    local SETTING_LABELS=( $@ )
    for setting in ${SETTING_LABELS[@]}; do
        case "$setting" in
            'project-path')
                display_setting_project_path; continue
                ;;
            'log-dir')
                display_setting_log_dir_path; continue
                ;;
            'conf-dir')
                display_setting_conf_dir_path; continue
                ;;
            'log-file')
                display_setting_log_file_path; continue
                ;;
            'conf-file')
                display_setting_conf_file_path; continue
                ;;
            'conf-json-file')
                display_setting_conf_json_file_path; continue
                ;;
            'log-lines')
                display_setting_log_lines; continue
                ;;
            'debug')
                display_setting_debug_flag; continue
                ;;
            'silence')
                display_setting_silence_flag; continue
                ;;
            'machine-id')
                display_setting_machine_id; continue
                ;;
            'local-ip')
                display_local_ipv4_address; continue
                ;;
            'external-ip')
                display_external_ipv4_address; continue
                ;;
            'data-dir')
                display_data_dir; continue
                ;;
            'serial-port')
                display_serial_port; continue
                ;;
            'serial-reads')
                display_serial_reads; continue
                ;;
            'spl-prefix')
                display_spl_prefix; continue
                ;;
            'spl-ack-sig')
                display_spl_ack_sig; continue
                ;;
            'spl-err-sig')
                display_spl_err_sig; continue
                ;;
        esac
    done
    return 0
}
