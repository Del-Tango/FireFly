//
// Regards, the Alveare Solutions #!/Society -x
//

byte vccPin = 4;
byte redPin = 6;
byte greenPin = 5;
byte bluePin = 7;
byte resetPin = 8;
unsigned long bootTime;
String command = "";            // SPLT:white@3,red@5; || SPLT:reset; || SPLT:color@(white|red|green|blue) || SPLT:power@(on|off);
String cmdBacklog = "";         // SPLT:white@3,red@5;SPLT:blue@3;
String cmdPrefix = "SPLT";
String cmdEnd = ";";
String cmdSeparator = "@";
unsigned int reallyLongDelayTime = 1000;
unsigned int longDelayTime = 500;
unsigned int shortDelayTime = 200;
unsigned int repeatCount = 0;
unsigned int serialTimeout = 10;
unsigned int serialChannel = 9600;
String splResponse = "";        // SPLT:ACK@<action-id>; || SPLT:ERR@<action-id>;
String defaultColor = "black";  // white || red || blue || green || black

class Button {
    private:
        bool _state;
        uint8_t _pin;
    public:
        Button(uint8_t pin) : _pin(pin) {}
        void begin() {
            pinMode(_pin, INPUT_PULLUP);
            _state = digitalRead(_pin);
        }
        bool isReleased() {
            bool v = digitalRead(_pin);
            if (v != _state) {
                _state = v;
                if (_state) {
                return true;
                }
            }
            return false;
        }
};

Button msgReset(resetPin);

bool setPinState(int pinNo, int pinState) {
    int currentState = digitalRead(pinNo);
    if (pinState == 0) {
        if (currentState == 0) {
            return true;
        }
        digitalWrite(pinNo, LOW);
    } else if (pinState == 1) {
        if (currentState == 1) {
            return true;
        }
        digitalWrite(pinNo, HIGH);
    } else {
        return false;
    }
    return true;
}

bool power(int pinState) {
    setPinState(vccPin, pinState);
    return true;
}

bool green(int pinState) {
    power(LOW);
    setPinState(greenPin, pinState);
    return true;
}

bool red(int pinState) {
    power(LOW);
    setPinState(redPin, pinState);
    return true;
}

bool blue(int pinState) {
    power(LOW);
    setPinState(bluePin, pinState);
    return true;
}

bool black() {
    green(HIGH);
    red(HIGH);
    blue(HIGH);
    return true;
}

bool white() {
    power(LOW);
    green(LOW);
    red(LOW);
    blue(LOW);
    power(LOW);
    return true;
}

bool cleanup() {
    splResponse = "";
    command = "";
//  repeatCount = 0;
    return true;
}

int alternatePinState(int pinNo, int repetitions) {
    int initialState = digitalRead(pinNo);
    digitalWrite(pinNo, HIGH);
    for (int i = 0; i <= repetitions; i++) {
        digitalWrite(pinNo, HIGH);
        delay(shortDelayTime);
        digitalWrite(pinNo, LOW);
        delay(shortDelayTime);
    }
    digitalWrite(pinNo, initialState);
    return 0;
}

int cmdReset() {
    int exitCode = 0;
    command = "";
    cmdBacklog = "";
    repeatCount = 0;
    exitCode = activateDefaultColor();
    Serial.println("[ INFO ]: FireFly reset!");
    return exitCode;
}

int setPower(String flag) {
    int exitCode = 0;
    int pinState = 0;
    if (flag == "on" || flag == "ON") {
        pinState = 0;
    } else if (flag == "off" || flag == "OFF") {
        pinState = 1;
    }
    bool exec = power(pinState);
    if (! exec) {
        exitCode = 1;
    }
    return exitCode;
}

int setDefaultColor(String color) {
    int exitCode = 0;
    defaultColor = color;
    exitCode = activateDefaultColor();
    return exitCode;
}

int ohForTheLoveOfGodJustBlinkAlready(int actionCode, int blinkCount) {
    int exitCode = 0;
    black();
    power(0);
    switch (actionCode) {
        case 4:
            for (int i = 0; i <= blinkCount; i++) {
                black();
                delay(shortDelayTime);
                white();
                delay(shortDelayTime);
            }
            break;
        case 5:
            exitCode = alternatePinState(redPin, blinkCount);
            break;
        case 6:
            exitCode = alternatePinState(greenPin, blinkCount);
            break;
        case 7:
            exitCode = alternatePinState(bluePin, blinkCount);
            break;
        case 8:
            for (int i = 0; i <= blinkCount; i++) {
                black();
                delay(shortDelayTime);
                exitCode = activateDefaultColor();
                delay(shortDelayTime);
            }
            break;
    }
    return exitCode;
}

int fetchActionCode(String cmdPrefix) {
    int actionCode = 0;
    if (cmdPrefix == "power") {
        actionCode = 1;
    } else if (cmdPrefix == "reset") {
        actionCode = 2;
    } else if (cmdPrefix == "color") {
        actionCode = 3;
    } else if (cmdPrefix == "white") {
        actionCode = 4;
    } else if (cmdPrefix == "red") {
        actionCode = 5;
    } else if (cmdPrefix == "green") {
        actionCode = 6;
    } else if (cmdPrefix == "blue") {
        actionCode = 7;
    } else if (cmdPrefix == "black") {
        actionCode = 8;
    } else {
        actionCode = 999;
    }
    return actionCode;
}

int actionExec(String action) {
    int exitCode = 0;
    int cmdSeparatorIndex = action.indexOf(cmdSeparator);
    String actionPrefix = action.substring(0, cmdSeparatorIndex);
    String actionSuffix = action.substring(cmdSeparatorIndex + 1);
    int actionCode = fetchActionCode(actionPrefix);
    switch (actionCode) {
        case 1:
            exitCode = setPower(actionSuffix);
            break;
        case 2:
            exitCode = cmdReset();
            break;
        case 3:
            exitCode = setDefaultColor(actionSuffix);
            break;
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
            black();
            exitCode = ohForTheLoveOfGodJustBlinkAlready(actionCode, actionSuffix.toInt() - 1);
            if (command != "" && command != cmdBacklog) {
                cmdBacklog = cmdBacklog + command;
            }
            break;
        default:
            Serial.print("[ WARNING ]: Invalid action! ");
            Serial.println(action);
            exitCode = 1;
            break;
    }
    return exitCode;
}

String searchCSV(String data, char separator, int index) {
    int strIndex[] = {0, -1};
    int counter = 0;
    String found = "";
    byte foundStart = 0;
    byte foundEnd = 0;
    for (int i = 0; i < data.length(); i++) {
        if (counter != 0 && counter == index) {
            if (foundStart == 0) {
                strIndex[0] = i;
                foundStart = 1;
            }
        } else if (counter == index + 1) {
            if (foundEnd == 0) {
                strIndex[1] = i;
                foundEnd = 1;
            }
            break;
        } else if (data[i] == separator) {
            counter++;
        }
    }
    found = data.substring(strIndex[0], strIndex[1]);
    return found;
}

int activateDefaultColor() {
    black();
    if (defaultColor == "white") {
            white();
    } else if (defaultColor == "red") {
            red(LOW);
    } else if (defaultColor == "green") {
            green(LOW);
    } else if (defaultColor == "blue") {
            blue(LOW);
    } else if (defaultColor == "black") {
            black();
    }
    return 0;
}

int countOccurrences(String str, char ch) {
    int counter = 0;
    for (int i = 0; i < str.length(); i++) {
        if (str[i] == ch) {
            counter++;
        }
    }
    return counter;
}

int processInstruction(String instruction) {
    int failures = 0;
    int cmdSeperatorOccurances = countOccurrences(instruction, ',');
    for (int i = 0; i <= cmdSeperatorOccurances; i++) {
        String cmdAction = searchCSV(instruction, ',', i);
        int cmdExec = actionExec(cmdAction);
        if (cmdExec != 0) {
            failures += 1;
            Serial.print("[ WARNING ]: Action ");
            Serial.print(cmdAction);
            Serial.print(" failed with exit code ");
            Serial.println(cmdExec);
        }
        delay(shortDelayTime);
    }
    return failures;
}

int interpretCmd(String cmd) {
    int cmdPrefixIndex = cmd.indexOf(':');
    int cmdSuffixIndex = cmd.indexOf(';');
    String prefix = cmd.substring(0, cmdPrefixIndex);
    String instruction = cmd.substring(cmdPrefixIndex + 1, cmdSuffixIndex);
    if (prefix != cmdPrefix) {
        Serial.print("[ WARNING ]: Invalid command prefix! ");
        Serial.println(prefix);
        return 1;
    }
    int exitCode = processInstruction(instruction);
    return exitCode;
}

int interpretCmdBacklog (String cmd) {
    int failures = 0;
    int cmdSeperatorOccurances = countOccurrences(cmd, ';');
    int cmdExec = 0;
    String cmdInstruction = "";
    activateDefaultColor();
    delay(reallyLongDelayTime);
    for (int i = 0; i <= cmdSeperatorOccurances; i++) {
        cmdInstruction = searchCSV(cmd, ';', i);
        cmdExec = interpretCmd(cmdInstruction);
        if (cmdExec != 0) {
            failures += 1;
            Serial.print("[ WARNING ]: Instruction ");
            Serial.print(cmdInstruction);
            Serial.print(" failed with exit code ");
            Serial.println(cmdExec);
        }
        delay(longDelayTime);
    }
    return failures;
}

void setup() {
    Serial.setTimeout(serialTimeout);
    Serial.begin(serialChannel);
    msgReset.begin();
    bootTime = millis();
    pinMode(vccPin, OUTPUT);
    pinMode(redPin, OUTPUT);
    pinMode(greenPin, OUTPUT);
    pinMode(bluePin, OUTPUT);
    Serial.print("[ INFO ]: FireFly boot time - ");
    Serial.println(bootTime);
    black();
    Serial.flush();
    Serial.println("[ INFO ]: FireFly boot sequence complete!");
}

void loop() {
    int interpret = 0;
    if (msgReset.isReleased()) {
        cmdReset();
    }
    if (Serial.available() > 0) {
        command = Serial.readStringUntil(&cmdEnd);
        command.trim();
        if (command == "") {
            return;
        }
        Serial.print("[ INFO ]: New SPL command - ");
        Serial.println(command);
    }
    if (command == "" && cmdBacklog == "") {
        delay(longDelayTime);
        return;
    } else if (command == "" && cmdBacklog != "") {
        interpret = interpretCmdBacklog(cmdBacklog);
    } else if (command != "") {
        interpret = interpretCmd(command);
    }
    String displayCount = String(repeatCount);
    if (interpret != 0) {
        splResponse = cmdPrefix + ":ERR" + cmdEnd;
    } else {
        splResponse = cmdPrefix + ":ACK" + cmdEnd;
    }
    Serial.println(splResponse);
    cleanup();
    repeatCount = repeatCount + 1;
    delay(longDelayTime);
}

// CODE DUMP

