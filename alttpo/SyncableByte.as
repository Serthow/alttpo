
funcdef bool SyncableByteShouldCapture(uint32 addr, uint8 oldValue, uint8 newValue);

class SyncableByte {
  uint16 offs;

  uint32 timestamp;
  uint8 value;

  uint32 timestampCompare;
  int32 playerIndex;

  SyncableByteShouldCapture@ shouldCapture;

  SyncableByte(uint16 offs) {
    this.offs = offs;
    @this.shouldCapture = null;

    this.value = 0;
    this.timestamp = 0;
  }

  void register(SyncableByteShouldCapture@ shouldCapture) {
    @this.shouldCapture = shouldCapture;
    bus::add_write_interceptor("7e:" + fmtHex(offs, 4), bus::WriteInterceptCallback(this.wram_written));

    reset();
  }

  // initialize value to current WRAM value:
  void reset() {
    timestamp = 0;
    value = bus::read_u8(0x7E0000 + offs);
  }

  // initialize value to specific WRAM value:
  void resetTo(uint8 newValue) {
    timestamp = 0;
    value = newValue;
  }

  void serialize(array<uint8> &r) {
    r.write_u32(timestamp);
    r.write_u16(value);
  }

  int deserialize(array<uint8> &r, int c) {
    // deserialize new value:
    timestamp = uint32(r[c++]) | (uint32(r[c++]) << 8) | (uint32(r[c++]) << 16) | (uint32(r[c++]) << 24);
    value = uint16(r[c++]) | (uint16(r[c++]) << 8);

    return c;
  }

  // bus::WriteInterceptCallback
  void wram_written(uint32 addr, uint8 oldValue, uint8 newValue) {
    if (shouldCapture !is null) {
      bool capture = shouldCapture(addr, oldValue, newValue);
      if (debugData) {
        message("called  shouldCapture(); " + fmtBool(capture));
      }
      if (!capture) {
        return;
      }
    }

    this.value = newValue;
    this.timestamp = timestamp_now;
  }
};
