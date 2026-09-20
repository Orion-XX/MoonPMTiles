///|
pub fn encode_probe(value : UInt64) -> Bytes {
  Bytes::makei(8, i => ((value >> (i * 8)) & 255UL).to_byte())
}

///|
pub fn decode_probe(bytes : Bytes) -> UInt64 {
  let mut value = 0UL
  for i = 0; i < 8; i = i + 1 {
    value = value | (bytes[i].to_uint64() << (i * 8))
  }
  value
}

///|
pub fn max_probe() -> UInt64 {
  0xFFFFFFFFFFFFFFFFUL
}
