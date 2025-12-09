/**
 * TTP223 Touch Sensor Test
 * 
 * Este sketch testa o sensor de toque capacitivo TTP223
 * conectado ao GPIO4 do ESP32.
 * 
 * Conexões:
 * - TTP223 VCC -> ESP32 3.3V
 * - TTP223 GND -> ESP32 GND
 * - TTP223 SIG -> ESP32 GPIO4
 * 
 * Comportamento esperado:
 * - Sem toque: LED apagado, Serial mostra "○ No touch"
 * - Com toque: LED aceso, Serial mostra "✓ TOUCH DETECTED"
 */

#include <Arduino.h>

// Configuração de pinos
#define TOUCH_PIN 4
#define LED_PIN 2  // LED interno do ESP32

// Variáveis de estado
bool lastTouchState = false;
unsigned long lastDebounceTime = 0;
const unsigned long DEBOUNCE_DELAY = 50;  // 50ms debounce

void setup() {
  // Inicializar Serial
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n=== TTP223 Touch Sensor Test ===");
  Serial.println("Touch the sensor to test...\n");
  
  // Configurar pinos
  pinMode(TOUCH_PIN, INPUT_PULLDOWN);
  pinMode(LED_PIN, OUTPUT);
  
  // LED apagado inicialmente
  digitalWrite(LED_PIN, LOW);
  
  Serial.println("✓ Setup complete");
  Serial.println("Monitoring touch sensor on GPIO4...\n");
}

void loop() {
  // Ler estado do sensor
  bool currentState = digitalRead(TOUCH_PIN);
  
  // Debouncing simples
  if (currentState != lastTouchState) {
    lastDebounceTime = millis();
  }
  
  if ((millis() - lastDebounceTime) > DEBOUNCE_DELAY) {
    // Estado estável
    if (currentState == HIGH && lastTouchState == LOW) {
      // Transição: não tocado -> tocado
      Serial.println("✓ TOUCH DETECTED");
      digitalWrite(LED_PIN, HIGH);
    } 
    else if (currentState == LOW && lastTouchState == HIGH) {
      // Transição: tocado -> não tocado
      Serial.println("○ Touch released");
      digitalWrite(LED_PIN, LOW);
    }
    
    lastTouchState = currentState;
  }
  
  // Mostrar estado atual a cada 500ms
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 500) {
    if (currentState == HIGH) {
      Serial.print("● ");
    } else {
      Serial.print("○ ");
    }
    lastPrint = millis();
  }
  
  delay(10);
}

/**
 * Teste avançado com contador de toques
 * 
 * Descomente para usar:
 */

/*
int touchCount = 0;
unsigned long touchStartTime = 0;
bool isTouching = false;

void loop() {
  bool currentState = digitalRead(TOUCH_PIN);
  
  if (currentState == HIGH && !isTouching) {
    // Início do toque
    isTouching = true;
    touchStartTime = millis();
    touchCount++;
    
    Serial.print("Touch #");
    Serial.print(touchCount);
    Serial.println(" started");
    
    digitalWrite(LED_PIN, HIGH);
  }
  else if (currentState == LOW && isTouching) {
    // Fim do toque
    isTouching = false;
    unsigned long duration = millis() - touchStartTime;
    
    Serial.print("Touch #");
    Serial.print(touchCount);
    Serial.print(" ended - Duration: ");
    Serial.print(duration);
    Serial.println("ms");
    
    digitalWrite(LED_PIN, LOW);
  }
  
  delay(10);
}
*/
