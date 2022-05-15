#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# SETUP

# LOADERS

function load_project_config () {
    load_project_logging_levels
    load_project_script_name
    load_project_prompt_string
    load_project_defaults
    load_project_cargo
    load_project_dependencies
}

function load_project_dependencies () {
    load_apt_dependencies ${FF_APT_DEPENDENCIES[@]}
    load_pip3_dependencies ${FF_PIP3_DEPENDENCIES[@]}
    return $?
}

function load_project_prompt_string () {
    load_prompt_string "$FF_PS3"
    return $?
}

function load_project_logging_levels () {
    load_logging_levels ${FF_LOGGING_LEVELS[@]}
    return $?
}

function load_project_cargo () {
    for project_cargo in ${!FF_CARGO[@]}; do
        load_cargo "$project_cargo" ${FF_CARGO[$project_cargo]}
    done
    return $?
}

function load_project_defaults () {
    for project_setting in ${!FF_DEFAULT[@]}; do
        load_default_setting \
            "$project_setting" ${FF_DEFAULT[$project_setting]}
    done
    return $?
}

function load_project_script_name () {
    load_script_name "$FF_SCRIPT_NAME"
    return $?
}

# PROJECT SETUP

function project_setup () {
    lock_and_load
    load_project_config
    create_project_menu_controllers
    setup_project_menu_controllers
}

function setup_project_menu_controllers () {
    setup_project_dependencies
    setup_main_menu_controller
    setup_manual_ctrl_menu_controller
    setup_log_viewer_menu_controller
    setup_settings_menu_controller
    done_msg "${BLUE}$SCRIPT_NAME${RESET} controller setup complete."
    return 0
}

# SETUP DEPENDENCIES

function setup_project_dependencies () {
    apt_install_dependencies
    pip3_install_dependencies
    return $?
}

# MANUAL CTRL SETUP

function setup_manual_ctrl_menu_controller() {
    setup_manual_ctrl_menu_option_porcelain_signal
    setup_manual_ctrl_menu_option_plumbing_signal
    setup_manual_ctrl_menu_option_setup_procedure
    setup_manual_ctrl_menu_option_help
    setup_manual_ctrl_menu_option_back
    done_msg "(${CYAN}$MANUALCTL_CONTROLLER_LABEL${RESET}) controller"\
        "option binding complete."
    return 0
}

function setup_manual_ctrl_menu_option_setup_procedure() {
    setup_menu_controller_action_option \
        "$MANUALCTL_CONTROLLER_LABEL" 'Setup-Procedure' \
        'action_setup_procedure'
    return $?
}

function setup_manual_ctrl_menu_option_porcelain_signal () {
    setup_menu_controller_action_option \
        "$MANUALCTL_CONTROLLER_LABEL" 'Porcelain-Signal' \
        'action_porcelain_signal'
    return $?
}

function setup_manual_ctrl_menu_option_plumbing_signal () {
    setup_menu_controller_action_option \
        "$MANUALCTL_CONTROLLER_LABEL" 'Plumbing-Signal' \
        'action_plumbing_signal'
    return $?
}

function setup_manual_ctrl_menu_option_help() {
    setup_menu_controller_action_option \
        "$MANUALCTL_CONTROLLER_LABEL" 'Help-Me-Understand' \
        'action_help'
    return $?
}

function setup_manual_ctrl_menu_option_back() {
    setup_menu_controller_action_option \
        "$MANUALCTL_CONTROLLER_LABEL" 'Back' \
        'action_back'
    return $?
}

# LOG VIEWER SETUP

function setup_log_viewer_menu_controller () {
    setup_log_viewer_menu_option_display_tail
    setup_log_viewer_menu_option_display_head
    setup_log_viewer_menu_option_display_more
    setup_log_viewer_menu_option_clear_log
    setup_log_viewer_menu_option_back
    done_msg "(${CYAN}$LOGVIEWER_CONTROLLER_LABEL${RESET}) controller"\
        "option binding complete."
    return 0
}

function setup_log_viewer_menu_option_clear_log () {
    setup_menu_controller_action_option \
        "$LOGVIEWER_CONTROLLER_LABEL"  'Clear-Log' 'action_clear_log_file'
    return $?
}

function setup_log_viewer_menu_option_display_tail () {
    setup_menu_controller_action_option \
        "$LOGVIEWER_CONTROLLER_LABEL"  'Display-Tail' 'action_log_view_tail'
    return $?
}

function setup_log_viewer_menu_option_display_head () {
    setup_menu_controller_action_option \
        "$LOGVIEWER_CONTROLLER_LABEL"  'Display-Head' 'action_log_view_head'
    return $?
}

function setup_log_viewer_menu_option_display_more () {
    setup_menu_controller_action_option \
        "$LOGVIEWER_CONTROLLER_LABEL"  'Display-More' 'action_log_view_more'
    return $?
}

function setup_log_viewer_menu_option_back () {
    setup_menu_controller_action_option \
        "$LOGVIEWER_CONTROLLER_LABEL"  'Back' 'action_back'
    return $?
}

# SETTINGS SETUP

function setup_settings_menu_option_set_debug_flag() {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Set-Debug-FLAG' \
        'action_set_debug_flag'
    return $?
}

function setup_settings_menu_option_set_silent_flag() {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Set-Silence-FLAG' \
        'action_set_silence_flag'
    return $?
}

function setup_settings_menu_option_set_conf_file() {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Set-Conf-File' \
        'action_set_config_file'
    return $?
}

function setup_settings_menu_option_set_conf_json() {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Set-Conf-JSON' \
        'action_set_config_json_file'
    return $?
}

function setup_settings_menu_option_update_conf_json() {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Update-Conf-JSON' \
        'action_update_config_json_file'
    return $?
}

function setup_settings_menu_option_set_log_file () {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Set-Log-File' \
        'action_set_log_file'
    return $?
}

function setup_settings_menu_option_set_log_lines () {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Set-Log-Lines' \
        'action_set_log_lines'
    return $?
}

function setup_settings_menu_option_install_dependencies () {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Install-Dependencies' \
        'action_install_dependencies'
    return $?
}

function setup_settings_menu_option_back () {
    setup_menu_controller_action_option \
        "$SETTINGS_CONTROLLER_LABEL" 'Back' 'action_back'
    return $?
}

function setup_settings_menu_controller () {
    setup_settings_menu_option_set_conf_file
    setup_settings_menu_option_set_conf_json
    setup_settings_menu_option_update_conf_json
    setup_settings_menu_option_set_debug_flag
    setup_settings_menu_option_set_silent_flag
    setup_settings_menu_option_set_log_file
    setup_settings_menu_option_set_log_lines
    setup_settings_menu_option_install_dependencies
    setup_settings_menu_option_back
    done_msg "(${CYAN}$SETTINGS_CONTROLLER_LABEL${RESET}) controller"\
        "option binding complete."
    return 0
}

# MAIN MENU SETUP

function setup_main_menu_controller() {
    setup_main_menu_option_manual_ctrl
    setup_main_menu_option_log_viewer
    setup_main_menu_option_control_panel
    setup_main_menu_option_back
    done_msg "(${CYAN}$MAIN_CONTROLLER_LABEL${RESET}) controller"\
        "option binding complete."
    return 0
}

function setup_main_menu_option_manual_ctrl() {
    setup_menu_controller_menu_option \
        "$MAIN_CONTROLLER_LABEL"  "Manual-Control" \
        "$MANUALCTL_CONTROLLER_LABEL"
    return $?
}

function setup_main_menu_option_log_viewer () {
    setup_menu_controller_menu_option \
        "$MAIN_CONTROLLER_LABEL"  "Log-Viewer" \
        "$LOGVIEWER_CONTROLLER_LABEL"
    return $?
}

function setup_main_menu_option_control_panel () {
    setup_menu_controller_menu_option \
        "$MAIN_CONTROLLER_LABEL"  "Control-Panel" \
        "$SETTINGS_CONTROLLER_LABEL"
    return $?
}

function setup_main_menu_option_back () {
    setup_menu_controller_action_option \
        "$MAIN_CONTROLLER_LABEL"  "Back" \
        'action_back'
    return $?
}

