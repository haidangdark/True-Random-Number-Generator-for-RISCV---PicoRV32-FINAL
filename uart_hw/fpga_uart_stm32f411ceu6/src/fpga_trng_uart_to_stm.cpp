#include <Arduino.h>

// ======= Pin & UART =======
static const uint8_t PIN_BTN    = PC13;   // nút nhấn, PULLUP, nhấn = LOW
static const uint8_t PIN_STARTI = PB0;    // xung start_i -> FPGA
HardwareSerial &UartFromFPGA = Serial1;   // USART1 (PA9/PA10); dùng PA10 RX

// ======= Tham số đo & buffer =======
static const uint32_t BAUD_UART      = 115200;   // 8N1 mặc định
static const uint16_t WORDS_TARGET   = 350;      // nhận đúng 350 word
static const uint32_t BYTES_TARGET   = (uint32_t)WORDS_TARGET * 4U; // 1400 byte
static const uint32_t PER_BYTE_MS    = 50;       // timeout/byte

static uint8_t  raw_bytes[BYTES_TARGET];
static uint32_t data_buf[WORDS_TARGET];

// debounce nhanh cho PC13
struct Debouncer {
  uint8_t stable, prev; uint32_t t; bool flag;
  void begin(uint8_t lv){ stable=prev=lv; t=millis(); flag=false; }
  void poll(uint8_t lv){ uint32_t n=millis(); if(n-t<1) return; t=n;
    if(lv==prev){ if(stable!=lv){ stable=lv; if(stable==LOW) flag=true; } }
    prev=lv; }
  bool pressed(){ if(flag){flag=false; return true;} return false; }
} btn;

static void pulse_start_i() {
  pinMode(PIN_STARTI, OUTPUT);
  digitalWrite(PIN_STARTI, HIGH);
  delayMicroseconds(500);
  digitalWrite(PIN_STARTI, LOW);
}

static void flushRx(HardwareSerial &U){ while(U.available()) (void)U.read(); }

static bool readExact(uint8_t *dst, uint32_t n, uint32_t per_byte_ms) {
  uint32_t got = 0, t0 = millis();
  while (got < n) {
    if (UartFromFPGA.available()) {
      dst[got++] = (uint8_t)UartFromFPGA.read();
      t0 = millis();
    } else {
      if ((millis() - t0) > per_byte_ms) return false;
      yield();
    }
  }
  return true;
}

void setup() {
  Serial.begin(115200);
  while (!Serial) {}

  UartFromFPGA.setRx(PA10);
  UartFromFPGA.begin(BAUD_UART /*, SERIAL_8N1*/);

  pinMode(PIN_BTN, INPUT_PULLUP);
  pinMode(PIN_STARTI, OUTPUT);
  digitalWrite(PIN_STARTI, LOW);

  btn.begin(digitalRead(PIN_BTN));
  Serial.println("STM32F411 ready. Press PC13 to capture 350 words...");
}

void loop() {
  btn.poll(digitalRead(PIN_BTN));
  if (!btn.pressed()) { delay(1); return; }

  // Bắt đầu: dọn RX & phát start, bắt đầu bấm giờ
  flushRx(UartFromFPGA);
  const uint32_t t_start_us = micros();
  pulse_start_i();

  // Nhận ĐỦ 350*4 = 1400 byte
  if (!readExact(raw_bytes, BYTES_TARGET, PER_BYTE_MS)) {
    Serial.println("RX timeout before reaching 350*4 bytes.");
    return;
  }
  const uint32_t t_end_us = micros();

  // Tính thời gian: us & s.us (không dùng float)
  const uint32_t delta_us = t_end_us - t_start_us;
  const uint32_t delta_s  = delta_us / 1000000UL;
  const uint32_t delta_us_rem = delta_us % 1000000UL;

  // Convert LSB->MSB
  for (uint32_t i = 0, j = 0; i < WORDS_TARGET; ++i, j += 4) {
    data_buf[i] = (uint32_t)raw_bytes[j]
                | ((uint32_t)raw_bytes[j+1] << 8)
                | ((uint32_t)raw_bytes[j+2] << 16)
                | ((uint32_t)raw_bytes[j+3] << 24);
  }

  // In kết quả
  Serial.println("----- RESULT (350 words) -----");
  Serial.printf("Time start->350 words: %lu us\n", (unsigned long)delta_us);
  // in dạng giây + micro giây (zero-pad 6 chữ số phần lẻ)
  Serial.printf("Time start->350 words: %lu.%06lu s\n",
                (unsigned long)delta_s, (unsigned long)delta_us_rem);

  const uint32_t WORDS_PER_LINE = 8;
  for (uint32_t i = 0; i < WORDS_TARGET; ++i) {
    Serial.printf("0x%08lX", (unsigned long)data_buf[i]);
    if (((i + 1) % WORDS_PER_LINE) == 0) Serial.println();
    else Serial.print(' ');
  }
  if ((WORDS_TARGET % WORDS_PER_LINE) != 0) Serial.println();
  Serial.println("----- END -----");
}
