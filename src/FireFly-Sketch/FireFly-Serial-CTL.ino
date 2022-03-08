//
// Regards, the Alveare Solutions #!/Society -x
//

byte vccPin = 4;
byte greenPin = 5;
byte redPin = 6;
byte bluePin = 7;
byte resetPin = 8;
unsigned long bootTime;
String command = "";            // SPLT:white@3,red@5; || SPLT:reset@0;
String cmdPrefix = "SPLT";
unsigned int longDelayTime = 500;
unsigned int shortDelayTime = 200;
unsigned int repeatCount = 0;
String splResponse = "";

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
    bool currentState = digitalRead(pinNo);
    if (pinState == 0) {
        if (currentState == false) {
            return true;
        }
        digitalWrite(pinNo, LOW);
//      Serial.print("[ INFO ]: Pin LOW - ");
//      Serial.println(pinNo);
    } else if (pinState == 1) {
        if (currentState == true) {
            return true;
        }
        digitalWrite(pinNo, HIGH);
//      Serial.print("[ INFO ]: Pin HIGH - ");
//      Serial.println(pinNo);
    } else {
//      Serial.print("[ ERROR ]: Invalid pin state! ");
//      Serial.println(pinState);
//      Serial.print("[ INFO ]: Defaulting to LOW - ");
//      Serial.println(pinNo);
        return false;
    }
    return true;
}

bool power(int pinState) {
    setPinState(vccPin, pinState);
    return true;
}

bool green(int pinState) {
    setPinState(greenPin, pinState);
    return true;
}

bool red(int pinState) {
    setPinState(redPin, pinState);
    return true;
}

bool blue(int pinState) {
    setPinState(bluePin, pinState);
    return true;
}

bool black() {
    power(0);
    green(0);
    red(0);
    blue(0);
    return true;
}

bool cleanup() {
    splResponse = "";
    return true;
}

bool alternatePinState(int pinNo, int repetitions) {
    for (int i = 0; i < repetitions; i++) {
        digitalWrite(pinNo, HIGH);
        delay(shortDelayTime);
        digitalWrite(pinNo, LOW);
        delay(shortDelayTime);
    }
    return true;
}

int processInstruction(String instruction) {
    int insDelimiterIndex = instruction.indexOf("@");
    String colorValue = instruction.substring(0, insDelimiterIndex);
    String repeatValue = instruction.substring(insDelimiterIndex + 1);
    int exitCode = 0;
    black();
    if (colorValue == "white") {
        red(1);
        green(1);
        blue(1);
        alternatePinState(vccPin, repeatValue.toInt());
    } else if (colorValue == "red") {
        red(1);
        alternatePinState(vccPin, repeatValue.toInt());
    } else if (colorValue == "green") {
        green(1);
        alternatePinState(vccPin, repeatValue.toInt());
    } else if (colorValue == "blue") {
        blue(1);
        alternatePinState(vccPin, repeatValue.toInt());
    } else if (colorValue == "reset") {
        command = "";
        repeatCount = 0;
//      Serial.println("[ INFO ]: FireFly message reset!");
    } else {
        exitCode = 1;
//      Serial.print("[ WARNING ]: Invalid SPL message - instruction color not found! ");
//      Serial.println(colorValue);
    }
    black();
    return exitCode;
}

int interpretCmd(String cmd) {
    // WARNING: This version only supports 1 command at a time
    int cmdPrefixIndex = command.indexOf(':');
    int cmdSuffixIndex = command.indexOf(';');
    String prefix = command.substring(0, cmdPrefixIndex);
    String instruction = command.substring(cmdPrefixIndex + 1, cmdSuffixIndex);
    int cmdSeparatorIndex = instruction.indexOf(',');
    String identificationMsg = instruction.substring(0, cmdSeparatorIndex);
    String payloadMsg = instruction.substring(cmdSeparatorIndex + 1);
    int idExec = processInstruction(identificationMsg);
    if (prefix != cmdPrefix) {
//      Serial.print("[ WARNING ]: Invalid command prefix! ");
//      Serial.println(prefix);
        return 1;
    }
    delay(longDelayTime);
    int payloadExec = processInstruction(payloadMsg);
    if ((idExec != 0) || (payloadExec != 0)) {
        return 2;
    }
    return 0;
}

void setup() {
    Serial.begin(9600);
    msgReset.begin();
    bootTime = millis();
//  Serial.print("[ INFO ]: FireFly boot time - ");
//  Serial.println(bootTime);
}

void loop() {
    if (msgReset.isReleased()) {
        command = "";
        repeatCount = 0;
//      Serial.println("FireFly message reset!");
    }
    if (Serial.available() > 0) {
//      command = command + Serial.readString();
        command = Serial.readString();
        command.trim();
//      Serial.print("[ INFO ]: New SPL command - ");
//      Serial.println(command);
    }
    if (command == "") {
        delay(longDelayTime);
        return;
    }
    int interpret = interpretCmd(command);
    String displayCount = String(repeatCount);
    if (interpret != 0) {
        splResponse = "SPLT:ERR@" + displayCount + ";";
    } else {
        splResponse = "SPLT:ACK@" + displayCount + ";";
    }
    Serial.println(splResponse);
    cleanup();
    repeatCount = repeatCount + 1;
    delay(longDelayTime);
}

// CODE DUMP

