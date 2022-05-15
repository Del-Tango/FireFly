#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# VALIDATORS

function validate_porcelain_signal() {
    local SIGNAL="$@"
    local FAILURES=0
    for signal in "`echo ${SIGNAL} | tr ',' ' '`"; do
        local PREFIX="${SIGNAL:0:4}"
        if [[ "${SIGNAL:0:5}" == 'blink' ]] || [[ "${SIGNAL:0:5}" == 'reset' ]] \
            || [[ "${SIGNAL:0:3}" == 'set' ]] || [[ "${SIGNAL:0:5}" == 'power' ]]; then
            continue
        else
            warning_msg "Malformed porcelain signal detected! (${RED}${SIGNAL}${RESET})"
        fi
        local FAILURES=$((FAILURES + 1))
    done
    return $FAILURES
}

function validate_plumbing_signal() {
    local SIGNAL="$@"
    local FAILURES=0
    for signal in "`echo ${SIGNAL} | tr ';' ' '`"; do
        local PREFIX="${SIGNAL:0:4}"
        if [[ "${SIGNAL:5:5}" == 'white' ]] || [[ "${SIGNAL:5:5}" == 'black' ]] \
            || [[ "${SIGNAL:5:5}" == 'color' ]] || [[ "${SIGNAL:5:5}" == 'power' ]] \
            || [[ "${SIGNAL:5:5}" == 'reset' ]] || [[ "${SIGNAL:5:5}" == 'green' ]] \
            || [[ "${SIGNAL:5:4}" == 'blue' ]] || [[ "${SIGNAL:5:3}" == 'red' ]]; then
            continue
        else
            warning_msg "Malformed plumbing signal detected! (${RED}${SIGNAL}${RESET})"
        fi
        local FAILURES=$((FAILURES + 1))
    done
    return $FAILURES
}
