#!/bin/bash 
#
# Regards, the Alveare Solutions #!/Society -x
#

# Hot parameters
CONF_FILE_PATH="$1"

# Cold parameters
MESSAGE_FILE="/tmp/.sklc"

if [ -f "${CONF_FILE_PATH}" ]; then
	source "$CONF_FILE_PATH"
fi

function skeleton_receiver() {
	tail -Fn1000 "${MESSAGE_FILE}"
	return 0
}

# MISCELLANEOUS

skeleton_receiver
exit $?

