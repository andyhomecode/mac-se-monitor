#include <Adafruit_SI5351.h>
//
//# Andy Maxwell
//# 2025 04 08 
//# To drive the Mac SE monitor, I need a clock generator
//# the FPGA I have apparently has a PLL in it, but I can't 
//# figure out how to use it, so instead I'm going hardware
//# and using an Adafruit SI5351 breakout module to generate the frequency
//# and an Adafruit Feather Huzzah! arduino module to send it SPI settings
//# (way overkill, I know, but that's what I have on hand)
//#
//# The code was vibe-coded using Claude Sonnet 3.7 and it suuuuucked
//# I finally found some good sample code online, fed it into it to update the
//# frequency alone and that worked.
//#
//#
//# Wiring is very straight-forward:
//# SI5351A VCC → Feather 3V
//# SI5351A GND → Feather GND
//# SI5351A SDA → Feather GPIO4 (SDA)
//# SI5351A SCL → Feather GPIO5 (SCL)

Adafruit_SI5351 clockgen = Adafruit_SI5351();

void setup(void) {
  Serial.begin(115200);
  Serial.println("SI5351 Clock Generator for Mac SE");
  
  pinMode(LED_BUILTIN, OUTPUT);
  
  // Initialize the SI5351
  if (clockgen.begin() != ERROR_NONE) {
    Serial.println("Error: SI5351 not detected. Check your wiring!");
    while(1) {
      digitalWrite(LED_BUILTIN, HIGH);
      delay(100);
      digitalWrite(LED_BUILTIN, LOW);
      delay(100);
    }
  }
  Serial.println("SI5351 initialized successfully!");
  
  // Configure for 15.6672 MHz (Mac SE pixel clock)
  // We'll use PLL_A at 784 MHz (approx) and divide by 50.04
  // 784.5 MHz ÷ 50.04 = 15.6672 MHz
  
  // Setup PLL_A to 784.5 MHz (25 MHz × 31.38)
  // 31.38 = 31 + 19/50
  clockgen.setupPLL(SI5351_PLL_A, 31, 19, 50);
  
  // Setup MultiSynth0 to divide by 50.04
  // 50.04 = 50 + 1/25
  clockgen.setupMultisynth(0, SI5351_PLL_A, 50, 1, 25);
  
  // Enable the outputs
  clockgen.enableOutputs(true);
  
  Serial.println("SI5351 configured for 15.6672 MHz on CLK0");
}

void loop(void) {
  // Nothing to do in the loop
  delay(1000);
}
