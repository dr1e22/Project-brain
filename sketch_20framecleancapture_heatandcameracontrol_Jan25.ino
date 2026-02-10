const int switchPin = 10;          // Digital pin for switch input
const int heatingElementPin = 11;  // Digital pin for heating element control
const int cameraTriggerPin = 13;   // Digital pin for camera trigger control
const unsigned long OUTPUT_TIME_CAMERA = 3000;  // Set the camera trigger output time in milliseconds
const unsigned long OUTPUT_TIME_HEATING = 3000; // Set the heating element output time in milliseconds

unsigned long startTime = 0; // Variable to store the start time
bool cameraTriggerActive = false;

void setup() {
  pinMode(switchPin, INPUT);
  pinMode(heatingElementPin, OUTPUT);
  pinMode(cameraTriggerPin, OUTPUT);

  Serial.begin(9600); // Begin Serial communication
}

void loop() {
  int sw = digitalRead(switchPin);  // Reads the switch state

  Serial.print("Switch State: ");
  Serial.println(sw);

  // Check if the button is pressed (assuming HIGH indicates the button is pressed)
  if (sw == HIGH && !cameraTriggerActive) {
    Serial.println("Button pressed");

    // Record the start time
    startTime = millis();

    // Generate LVTTL pulse for the camera to start capturing
    Serial.println("Triggering camera for background frames");
    digitalWrite(cameraTriggerPin, HIGH);

    // Delay for capturing 20 background frames at 383 Hz
    delay(132); // Approx. 52 ms for 20 frames (20 x 2.61 ms per frame)+80ms for camera 

    // Turn on the heating element
    Serial.println("Turning on heating element");
    digitalWrite(heatingElementPin, HIGH);

    // Continue triggering the camera and set the flag
    cameraTriggerActive = true;
  }

  // Check if the camera trigger duration has elapsed
  if (cameraTriggerActive && millis() - startTime >= OUTPUT_TIME_CAMERA) {
    Serial.println("Turning off camera trigger");
    digitalWrite(cameraTriggerPin, LOW);
    cameraTriggerActive = false;
  }

  // Check if the heating element duration has elapsed
  if (digitalRead(heatingElementPin) == HIGH && millis() - startTime >= OUTPUT_TIME_HEATING) {
    Serial.println("Turning off heating element");
    digitalWrite(heatingElementPin, LOW);
  }

  // Wait for a brief moment to debounce the button
  delay(50);

  // Wait until the button input signal returns to LOW
  Serial.println("Waiting for button release");
  while (digitalRead(switchPin) == HIGH) {
    delay(10);
  }

  Serial.println("Button released");

  // End of loop, add a delay to prevent overwhelming the Serial Monitor
  delay(1000);
}
