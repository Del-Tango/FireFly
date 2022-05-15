#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# FORMATTERS

function format_serial_signal_cargo_arguments() {
    local SIGNAL="$@"
    local ARGUMENTS=(
        `format_floodgate_cargo_constant_args`
        "--action serial-signal"
        "--signal ${SIGNAL}"
    )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_floodgate_cargo_constant_args() {
    local ARGUMENTS=(
        "--log-file ${MD_DEFAULT['log-file']}"
        "--config-file ${MD_DEFAULT['conf-json-file']}"
    )
    if [[ ${MD_DEFAULT['silence']} == 'on' ]]; then
        local ARGUMENTS=( ${ARGUMENTS[@]} '--silence' )
    fi
    if [[ ${MD_DEFAULT['debug']} == 'on' ]]; then
        local ARGUMENTS=( ${ARGUMENTS[@]} '--debug' )
    fi
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_cargo_exec_string() {
    local ARGUMENTS=( ${@} )
    if [ ${#ARGUMENTS[@]} -eq 0 ]; then
        return 1
    fi
    local EXEC_STR="~$ ./`basename ${FF_CARGO['firefly']}` ${ARGUMENTS[@]}"
    echo "${EXEC_STR}"
    return $?
}

function format_setup_machine_cargo_arguments() {
    local ARGUMENTS=( `format_flood_cargo_constant_args` '--action setup' )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_config_json_flag() {
    local FLAG_VALUE="$1"
    case "$FLAG_VALUE" in
        'on'|'On'|'ON')
            echo 'true'
            ;;
        'off'|'Off'|'OFF')
            echo 'false'
            ;;
        *)
            echo $FLAG_VALUE
            return 1
            ;;
    esac
    return 0
}

function format_config_json_file_content() {
    cat<<EOF
{
    "FF_SCRIPT_NAME":        "${FF_SCRIPT_NAME}",
    "FF_VERSION":            "${FF_VERSION}",
    "FF_VERSION_NO":         "${FF_VERSION_NO}",
    "FF_DIRECTORY":          "$FF_DIRECTORY",
    "FF_DEFAULT": {
         "project-path":     "${MD_DEFAULT['project-path']}",
         "home-dir":         "${MD_DEFAULT['home-dir']}",
         "log-dir":          "${MD_DEFAULT['log-dir']}",
         "conf-dir":         "${MD_DEFAULT['conf-dir']}",
         "lib-dir":          "${MD_DEFAULT['lib-dir']}",
         "src-dir":          "${MD_DEFAULT['src-dir']}",
         "dox-dir":          "${MD_DEFAULT['dox-dir']}",
         "dta-dir":          "${MD_DEFAULT['dta-dir']}",
         "tmp-dir":          "${MD_DEFAULT['tmp-dir']}",
         "log-file":         "`basename ${MD_DEFAULT['log-file']}`",
         "conf-file":        "`basename ${MD_DEFAULT['conf-json-file']}`",
         "log-format":       "${MD_DEFAULT['log-format']}",
         "timestamp-format": "${MD_DEFAULT['timestamp-format']}",
         "debug":            `format_config_json_flag ${MD_DEFAULT['debug']}`,
         "silence":          `format_config_json_flag ${MD_DEFAULT['silence']}`,
         "serial-port":      "${MD_DEFAULT['serial-port']}",
         "serial-reads":     "${MD_DEFAULT['serial-reads']}",
         "serial-interval":  "${MD_DEFAULT['serial-interval']}",
         "spl-prefix":       "${MD_DEFAULT['spl-prefix']}",
         "spl-ack-sig":      "${MD_DEFAULT['spl-ack-sig']}",
         "spl-err-sig":      "${MD_DEFAULT['spl-err-sig']}"
    },
    "FF_CARGO": {
        "firefly":           "${MD_CARGO['firefly']}"
    }
}
EOF
    return $?
}

function format_display_manual_ctrl_settings_args () {
    format_display_main_settings_args
    return $?
}

function format_display_main_settings_args () {
    local ARGUMENTS=( 'machine-id' 'local-ip' 'external-ip')
    echo ${ARGUMENTS[@]}
    return $?
}

function format_display_project_settings_args () {
    local ARGUMENTS=(
        'machine-id'
        'local-ip'
        'external-ip'
        'log-lines'
        'debug'
        'silence'
        'project-path'
        'log-file'
        'conf-file'
        'conf-json-file'
    )
    echo ${ARGUMENTS[@]}
    return $?
}

# CODE DUMP

