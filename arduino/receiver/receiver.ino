#include <Wire.h>
#include <LiquidCrystal_I2C.h>

/*
  Morse Code Receiver (LDR + 16x2 I2C LCD)
  For Arduino Nano
*/

// Set the LCD address to 0x27 for a 16 chars and 2 line display
// If 0x27 doesn't work, try 0x3F
LiquidCrystal_I2C lcd(0x27, 16, 2);

const int ldrPin = A0;      // LDR sensor connected to Analog Pin A0
const int ledPin = 13;      // Built-in LED for visual feedback

// TIMING (Must match Flutter app)
const int unit = 250;       // ms
const int threshold = 225;  // LDR threshold (Value < 225 means Light Detected)
                            // Ranges: Normal (250-450), LED Flash (100-200)

unsigned long pulseStart = 0;
bool isLightOn = false;
String currentMorse = "";
String receivedMessage = "";

// Morse Code Dictionary
String morseMap[] = {
  ".-","-...","-.-.","-..",".","..-.","--.","....","..",".---","-.-",".-..",
  "--","-.","---",".--.","--.-",".-.","...","-","..-","...-",".--","-..-",
  "-.--","--.."
};
char letters[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

char decodeMorse(String morse) {
  for (int i = 0; i < 26; i++) {
    if (morseMap[i] == morse) {
      return letters[i];
    }
  }
  return '?';
}

void setup() {
  pinMode(ledPin, OUTPUT);
  
  lcd.init();          // Initialize the LCD
  lcd.backlight();     // Turn on the backlight
  
  lcd.setCursor(0, 0);
  lcd.print("Morse Receiver");
  lcd.setCursor(0, 1);
  lcd.print("Waiting...");
  Serial.begin(9600);
}

void loop() {
  int ldrValue = analogRead(ldrPin);
  
  // UNCOMMENT to calibrate: See values in Serial Monitor
   Serial.print("LDR: "); Serial.println(ldrValue);
  
  unsigned long now = millis();
  unsigned long duration = now - pulseStart;

  // LIGHT DETECTED (LDR value decreases when light hits it in your setup)
  if (ldrValue < threshold) {
    if (!isLightOn) {
      // Light just turned on - process the GAP
      if (duration > unit * 4) {
         // Word gap (usually > 1500ms)
         receivedMessage += " ";
         updateDisplay();
      } else if (duration > unit * 2) {
         // Letter gap (usually > 750ms)
         if (currentMorse != "") {
            receivedMessage += decodeMorse(currentMorse);
            currentMorse = "";
            updateDisplay();
         }
      }
      
      pulseStart = now;
      isLightOn = true;
      digitalWrite(ledPin, HIGH);
    }
  } 
  // NO LIGHT
  else {
    if (isLightOn) {
      // Light just turned off - process the SYMBOL
      if (duration > unit * 2) {
        currentMorse += "-"; // DASH (approx 750ms)
      } else {
        currentMorse += "."; // DOT (approx 250ms)
      }
      
      pulseStart = now;
      isLightOn = false;
      digitalWrite(ledPin, LOW);
    }
  }

  // Handle timeout (auto-decode last letter if silence for too long)
  if (!isLightOn && duration > unit * 6 && currentMorse != "") {
      receivedMessage += decodeMorse(currentMorse);
      currentMorse = "";
      updateDisplay();
  }
  
  // Clean screen if message is too long
  if (receivedMessage.length() > 16) {
    receivedMessage = receivedMessage.substring(receivedMessage.length() - 16);
    updateDisplay();
  }
}

void updateDisplay() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Received:");
  lcd.setCursor(0, 1);
  lcd.print(receivedMessage);
  Serial.println(receivedMessage);
}
