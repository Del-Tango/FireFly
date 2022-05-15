#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# Fire!! Fly! (Cargo)

__author__ = 'Alveare Solutions'
__version__ = '1.0'
__maintainer__ = '#!/Society'

import time
import optparse
import os
import json
import crypt
import threading
import pysnooper
import random
import subprocess
import RPi.GPIO as GPIO

from backpack.bp_log import log_init
from backpack.bp_ensurance import ensure_files_exist,ensure_directories_exist
from backpack.bp_shell import shell_cmd
from backpack.bp_checkers import check_file_exists, check_superuser
from backpack.bp_threads import threadify
from backpack.bp_convertors import file2list
from backpack.bp_general import stdout_msg, clear_screen, write2file
from backpack.bp_filters import filter_file_name_from_path, filter_directory_from_path
from backpack.spl_writer import SPLWriter
from backpack.spl_reader import SPLReader

# Hot Parameters

FF_SCRIPT_NAME = 'FireFly'
FF_VERSION = 'Semaphore'
FF_VERSION_NO = __version__
FF_DEFAULT = {
    'project-path': str(),
    'conf-dir': 'conf',
    'conf-file': 'firefly.conf.json',
    'log-dir': 'log',
    'log-file': 'firefly.log',
    'log-format': '[ %(asctime)s ] %(name)s [ %(levelname)s ] %(thread)s - '\
                  '%(filename)s - %(lineno)d: %(funcName)s - %(message)s',
    'timestamp-format': '%d/%m/%Y-%H:%M:%S',
    'debug': True,
    'silence': False,
    'serial-port': '/dev/serial0',        # no comment needed... hehe
    'serial-reads': 3,                    # read attempts
    'serial-interval': 1,                 # seconds
    'spl-prefix': 'SPLT',
    'spl-ack-sig': 'ACK',
    'spl-err-sig': 'ERR',
}
FF_CARGO = {
    'firefly': __file__,
}
FF_ACTIONS_CSV = str() # (help | serial-signal | serial-signal,help)
FF_SIGNAL_CSV = str() # blink-white:3,blink-red:3,blink-green:3,blink-blue:3
SPL_WRITER = SPLWriter(FF_DEFAULT['serial-port'])
SPL_READER = SPLReader(FF_DEFAULT['serial-port'])

# Cold Parameters

FF_PORCELAIN_CMDS = [
    'blink-white', 'blink-black', 'blink-red', 'blink-green', 'blink-blue',
    'set-color', 'set-power', 'reset'
]
log = log_init(
    '/'.join([FF_DEFAULT['log-dir'], FF_DEFAULT['log-file']]),
    FF_DEFAULT['log-format'], FF_DEFAULT['timestamp-format'],
    FF_DEFAULT['debug'], log_name=FF_SCRIPT_NAME
)

# CHECKERS

#@pysnooper.snoop()
def check_config_file():
    log.debug('')
    conf_file_path = FF_DEFAULT['conf-dir'] + "/" + FF_DEFAULT['conf-file']
    ensure_directories_exist(FF_DEFAULT['conf-dir'])
    cmd_out, cmd_err, exit_code = shell_cmd('touch ' + conf_file_path)
    return False if exit_code != 0 else True

#@pysnooper.snoop()
def check_log_file():
    log.debug('')
    log_file_path = FF_DEFAULT['log-dir'] + "/" + FF_DEFAULT['log-file']
    ensure_directories_exist(FF_DEFAULT['log-dir'])
    cmd_out, cmd_err, exit_code = shell_cmd('touch ' + log_file_path)
    return False if exit_code != 0 else True

def check_preconditions():
    log.debug('')
    checkers = {
        'preconditions-conf': check_config_file(),
        'preconditions-log': check_log_file(),
    }
    if False in checkers.values():
        return len([item for item in checkers.values() if not item])
    return 0

# ACTIONS

def action_low_level_serial_signal(*args, **kwargs):
    # [ NOTE ]: Fluffier instructions than high level signals but less computations
    log.debug('')
    serial_write = SPL_WRITER.write(FF_SIGNAL_CSV)
    if serial_write is False:
        stdout_msg(
            '[ NOK ]: Could not write message to serial port {}! Details: {}'
            .format(FF_DEFAULT['serial-port']), FF_ACTIONS_CSV,
        )
        return 1
    return process_serial_signal_response()

#@pysnooper.snoop()
def action_serial_signal(*args, **kwargs):
    log.debug('')
    spl_instructions, fragments = [], []
    for action in FF_SIGNAL_CSV.split(','):
        fragments = action.split(':')
        if not fragments or len(fragments) != 2 or fragments[0] not in FF_PORCELAIN_CMDS:
            stdout_msg('[ WARNING ]: Invalid action! ({})'.format(action))
            continue
        if len(fragments) == 2 and fragments[0].split('-')[0] in ['blink', 'set']:
            spl_action = fragments[0].split('-')[1] + '@' + fragments[1]
            new_spl_instruction = '{}:{};'.format(FF_DEFAULT['spl-prefix'], spl_action)
        elif len(fragments) == 2 and fragments[0] == 'reset':
            spl_action = fragments[0]
            new_spl_instruction = '{}:{};'.format(FF_DEFAULT['spl-prefix'], spl_action)
        else:
            stdout_msg("[ WARNING ]: Invalid action! ({})".format(action))
            continue
        spl_instructions.append(new_spl_instruction)
    serial_write = SPL_WRITER.write(''.join(spl_instructions))
    if serial_write is False:
        stdout_msg(
            '[ NOK ]: Could not write message to serial port {}! Details: {}'
            .format(FF_DEFAULT['serial-port']), FF_ACTIONS_CSV,
        )
        return 1
    return process_serial_signal_response()

def action_help():
    log.debug('')
    exit(display_usage())

# GENERAL

def process_serial_signal_response():
    log.debug('')
    exit_code = 1
    stdout_msg('[ INFO ]: Waiting for response from LAMP controller...')
    expected_answers = {
        'OK': '{}:{};'.format(FF_DEFAULT['spl-prefix'], FF_DEFAULT['spl-ack-sig']),
        'NOK': '{}:{};'.format(FF_DEFAULT['spl-prefix'], FF_DEFAULT['spl-err-sig']),
    }
    for item in range(int(FF_DEFAULT['serial-reads'])):
        serial_read = SPL_READER.read()
        if item == FF_DEFAULT['serial-reads']:
            stdout_msg('[ NOK ]: Timed out waiting for response from LAMP controller!')
            break
        elif not serial_read or (expected_answers['OK'] not in serial_read \
                and expected_answers['NOK'] not in serial_read):
            time.sleep(int(FF_DEFAULT['serial-interval']))
            continue
        elif expected_answers['NOK'] in serial_read:
            stdout_msg(
                '[ NOK ]: FireFly lamp controller could not properly process actions! {}'
                .format(spl_instructions)
            )
        elif expected_answers['OK'] in serial_read:
            stdout_msg('[ OK ]: FireFly lamp controller!')
            exit_code = 0
    return exit_code

#@pysnooper.snoop()
def load_config_file():
    log.debug('')
    global FF_DEFAULT
    global FF_SCRIPT_NAME
    global FF_VERSION
    global FF_VERSION_NO
    global SPL_WRITER
    global SPL_READER
    stdout_msg('[ INFO ]: Loading config file...')
    conf_file_path = FF_DEFAULT['conf-dir'] + '/' + FF_DEFAULT['conf-file']
    if not os.path.isfile(conf_file_path):
        stdout_msg('[ NOK ]: File not found! ({})'.format(conf_file_path))
        return False
    with open(conf_file_path, 'r', encoding='utf-8', errors='ignore') as conf_file:
        try:
            content = json.load(conf_file)
            if FF_DEFAULT['serial-port'] != content['FF_DEFAULT'].get('serial-port'):
                SPL_WRITER = SPLWriter(content['FF_DEFAULT']['serial-port'])
                SPL_READER = SPLReader(content['FF_DEFAULT']['serial-port'])
            FF_DEFAULT.update(content['FF_DEFAULT'])
            FF_CARGO.update(content['FF_CARGO'])
            FF_SCRIPT_NAME = content['FF_SCRIPT_NAME']
            FF_VERSION = content['FF_VERSION']
            FF_VERSION_NO = content['FF_VERSION_NO']
        except Exception as e:
            log.error(e)
            stdout_msg(
                '[ NOK ]: Could not load config file! ({})'.format(conf_file_path)
            )
            return False
    stdout_msg(
        '[ OK ]: Settings loaded from config file! ({})'.format(conf_file_path)
    )
    return True

# HANDLERS

#@pysnooper.snoop()
def handle_actions(actions=[], *args, **kwargs):
    log.debug('')
    failure_count = 0
    handlers = {
        'serial-signal': action_serial_signal,
        'low-lvl-signal': action_low_level_serial_signal,
        'help': action_help,
    }
    for action_label in actions:
        stdout_msg('[ INFO ]: Processing action... ({})'.format(action_label))
        if action_label not in handlers.keys():
            stdout_msg(
                '[ NOK ]: Invalid action label specified! ({})'.format(action_label)
            )
            continue
        handle = handlers[action_label](*args, **kwargs)
        if isinstance(handle, int) and handle != 0:
            stdout_msg(
                '[ NOK ]: Action ({}) failures detected! ({})'\
                .format(action_label, handle)
            )
            failure_count += 1
            continue
        stdout_msg(
            "[ OK ]: Action executed successfully! ({})".format(action_label)
        )
    return True if failure_count == 0 else failure_count

# FORMATTERS

def format_header_string():
    header = '''
    ___________________________________________________________________________

     *                         *   Fire! Fly!!   *                           *
    ___________________________________________________________________________
                    Regards, the Alveare Solutions #!/Society -x
    '''
    return header

def format_usage_string():
    usage = '''
    -h | --help                    Display this message.

    -q | --silence                 No STDOUT messages.

    -a | --action ACTIONS-CSV      Action to execute - Valid values include one
       |                           or more of the following labels given as a CSV
       |                           string: (help, serial-signal)

    -s | --signal SIGNAL-CSV       Implies (--action serial-signal). Specifies to the
       |                           FireFly lamp controller what colors to blink,
       |                           in what order and what number of times

    -l | --log-file FILE-PATH      Log file path... where it writes log messages to.

    -c | --config-file FILE-PATH   Config file path... where it reads configurations
       |                           from.

    -D | --debug                   Increases verbosity of log messages.
    '''
    return usage

# DISPLAY

def display_header():
    if FF_DEFAULT['silence']:
        return False
    print(format_header_string())
    return True

def display_usage():
    if FF_DEFAULT['silence']:
        return False
    display_header()
    print(format_usage_string())
    return True

# CREATORS

def create_command_line_parser():
    log.debug('')
    help_msg = format_header_string() + '''
    [ EXAMPLE ]: Send plumbing (low level) instruction to FireFly LAMP controller over serial -

        ~$ %prog \\
            -a  | --action low-lvl-signal \\
            -s  | --signal SPLT:power@on;SPLT:color@white;SPLT:white@3,red@4; \\
            -q  | --silence \\
            -c  | --config-file /etc/conf/firefly.conf.json \\
            -l  | --log-file /etc/log/firefly.log

    [ EXAMPLE ]: Send porcelain (high level) instruction to FireFly LAMP controller over serial -

        ~$ %prog \\
            -a  | --action serial-signal \\
            -s  | --signal blink-white:3,blink-red:3,blink-black:3,blink-blue:3,blink-green:3 \\
            -q  | --silence \\
            -c  | --config-file /etc/conf/firefly.conf.json \\
            -l  | --log-file /etc/log/firefly.log'''
    parser = optparse.OptionParser(help_msg)
    return parser

# PROCESSORS

#@pysnooper.snoop()
def process_config_file_argument(parser, options):
    global FF_DEFAULT
    log.debug('')
    file_path = options.config_file_path
    if file_path == None:
        log.warning(
            'No config file provided. Defaulting to ({}/{}).'\
            .format(FF_DEFAULT['conf-dir'], FF_DEFAULT['conf-file'])
        )
        return False
    FF_DEFAULT['conf-dir'] = filter_directory_from_path(file_path)
    FF_DEFAULT['conf-file'] = filter_file_name_from_path(file_path)
    load_config_file()
    stdout_msg(
        '[ + ]: Config file setup ({})'.format(FF_DEFAULT['conf-file'])
    )
    return True

def process_warning(warning):
    log.warning(warning['msg'])
    print('[ WARNING ]:', warning['msg'], 'Details:', warning['details'])
    return warning

def process_error(error):
    log.error(error['msg'])
    print('[ ERROR ]:', error['msg'], 'Details:', error['details'])
    return error

def process_command_line_options(parser):
    '''
    [ NOTE ]: In order to avoid a bad time in STDOUT land, please process the
            silence/quiet flag before all others.
    '''
    log.debug('')
    (options, args) = parser.parse_args()
    processed = {
        'silence_flag': process_silence_argument(parser, options),
        'config_file': process_config_file_argument(parser, options),
        'log_file': process_log_file_argument(parser, options),
        'action_csv': process_action_csv_argument(parser, options),
        'signal_csv': process_signal_csv_argument(parser, options),
        'debug_flag': process_debug_mode_argument(parser, options),
    }
    return processed

def process_silence_argument(parser, options):
    global FF_DEFAULT
    log.debug('')
    silence_flag = options.silence
    if silence_flag == None:
        return False
    FF_DEFAULT['silence'] = silence_flag
    stdout_msg(
        '[ + ]: Silence ({})'.format(silence_flag)
    )
    return True

def process_action_csv_argument(parser, options):
    global FF_ACTIONS_CSV
    log.debug('')
    action_csv = options.action_csv
    if action_csv == None:
        log.warning(
            'No actions provided. Defaulting to ({}).'\
            .format(FF_ACTIONS_CSV)
        )
        return False
    FF_ACTIONS_CSV = action_csv
    stdout_msg(
        '[ + ]: Actions setup ({})'.format(FF_ACTIONS_CSV)
    )
    return True

def process_signal_csv_argument(parser, options):
    global FF_SIGNAL_CSV
    log.debug('')
    sig_csv = options.signal_csv
    if sig_csv == None:
        log.warning(
            'No serial signals provided. Defaulting to ({}).'\
            .format(FF_SIGNAL_CSV)
        )
        return False
    FF_SIGNAL_CSV = sig_csv
    stdout_msg(
        '[ + ]: Serial signal setup ({})'.format(FF_SIGNAL_CSV)
    )
    return True

def process_debug_mode_argument(parser, options):
    global FF_DEFAULT
    log.debug('')
    debug_mode = options.debug_mode
    if debug_mode == None:
        log.warning(
            'Debug mode flag not specified. '
            'Defaulting to ({}).'.format(FF_DEFAULT['debug'])
        )
        return False
    FF_DEFAULT['debug'] = debug_mode
    stdout_msg(
        '[ + ]: Debug mode setup ({})'.format(FF_DEFAULT['debug'])
    )
    return True

def process_log_file_argument(parser, options):
    global FF_DEFAULT
    log.debug('')
    file_path = options.log_file_path
    if file_path == None:
        log.warning(
            'No log file provided. Defaulting to ({}/{}).'\
            .format(FF_DEFAULT['log-dir'], FF_DEFAULT['log-file'])
        )
        return False
    FF_DEFAULT['log-dir'] = filter_directory_from_path(file_path)
    FF_DEFAULT['log-file'] = filter_file_name_from_path(file_path)
    stdout_msg(
        '[ + ]: Log file setup ({})'.format(FF_DEFAULT['log-file'])
    )
    return True

# PARSERS

def add_command_line_parser_options(parser):
    log.debug('')
    parser.add_option(
        '-q', '--silence', dest='silence', action='store_true',
        help='Eliminates all STDOUT messages.'
    )
    parser.add_option(
        '-a', '--action', dest='action_csv', type='string', metavar='ACTION-CSV',
        help='Action to execute - valid values include one or more of the '
            'following labels given as a CSV string: (open-gates | close-gates '
            '| setup | check-gates | start-watchdog)'
    )
    parser.add_option(
        '-s', '--signal', dest='signal_csv', type='string', metavar='SIG-CSV',
        help='Implies (--action serial-signal) - Specify to the FireFly lamp '
            'controller what lights to blink for a given number of times. '
            'FORMAT: blink-<color>:<blink-count>, - available values for color '
            'are (white, black, reg, green, blue).'
    )
    parser.add_option(
        '-c', '--config-file', dest='config_file_path', type='string',
        help='Configuration file to load default values from.', metavar='FILE_PATH'
    )
    parser.add_option(
        '-D', '--debug-mode', dest='debug_mode', action='store_true',
        help='Display more verbose output and log messages.'
    )
    parser.add_option(
        '-l', '--log-file', dest='log_file_path', type='string',
        help='Path to the log file.', metavar='FILE_PATH'
    )

def parse_command_line_arguments():
    log.debug('')
    parser = create_command_line_parser()
    add_command_line_parser_options(parser)
    return process_command_line_options(parser)

# WARNINGS

def warning_action_not_handled_properly(warn_code=2, *args, **kwargs):
    warning = {
        'msg': 'Action not handled properly, failures detected!',
        'code': warn_code,
        'details': (args, kwargs),
    }
    return process_warning(warning)

def warning_gpio_setup_failed(warn_code=3, *args, **kwargs):
    warning = {
        'msg': 'Failures detected in GPIO setup! Some devices might not work properly.',
        'code': warn_code,
        'details': (args, kwargs),
    }
    return process_warning(warning)

def error_preconditions_not_met(err_code=1, *args, **kwargs):
    error = {
        'msg': 'Action preconditions not met!',
        'code': err_code,
        'details': (args, kwargs),
    }
    return process_error(error)

# INIT

#@pysnooper.snoop()
def init_firefly():
    log.debug('')
    display_header()
    stdout_msg('[ INFO ]: Verifying action preconditions...')
    check = check_preconditions()
    if not isinstance(check, int) or check != 0:
        return error_preconditions_not_met(check)
    stdout_msg('[ OK ]: Action preconditions met!')
    handle = handle_actions(
        FF_ACTIONS_CSV.split(','), **FF_DEFAULT
    )
    if not handle:
        warning_action_not_handled_properly(handle)
    return 0 if handle is True else handle

# MISCELLANEOUS

if __name__ == '__main__':
    parse_command_line_arguments()
    clear_screen(FF_DEFAULT['silence'])
    EXIT_CODE = init_firefly()
    stdout_msg('[ DONE ]: Terminating! ({})'.format(EXIT_CODE))
    if isinstance(EXIT_CODE, int):
        exit(EXIT_CODE)
    exit(0)

# CODE DUMP

