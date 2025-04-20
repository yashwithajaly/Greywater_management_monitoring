#include <WiFi.h>
#include <ThingSpeak.h>

const char* ssid = "TP-Link_33";
const char* password = "vce@2024";
WiFiClient client;

unsigned long myChannelNumber = 2859622;
const char * myWriteAPIKey = "DVKYWTRFTW9GAEOD";

int waterSensorPin = 34; // Analog pin
int sensorValue = 0;

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }

  Serial.println("WiFi Connected");
  ThingSpeak.begin(client);
}

void loop() {
  sensorValue = analogRead(waterSensorPin);
  Serial.print("Water Level: ");
  Serial.println(sensorValue);

  ThingSpeak.setField(1, sensorValue);
  int status = ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);

  if (status == 200) {
    Serial.println("Data sent to ThingSpeak");
  } else {
    Serial.print("Error: ");
    Serial.println(status);
  }

  delay(20000); // ThingSpeak allows 15-second interval minimum
}