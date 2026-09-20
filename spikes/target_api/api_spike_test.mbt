///|
test "UInt64 little-endian round trip" {
  let values = [0UL, 1UL, 0x0102030405060708UL, 0xFFFFFFFFFFFFFFFFUL]
  for value in values {
    let encoded = encode_probe(value)
    assert_eq(encoded.length(), 8)
    assert_eq(decode_probe(encoded), value)
  }
}

///|
test "UInt64 max value is representable" {
  assert_eq(max_probe(), 18446744073709551615UL)
}

///|
test "Bytes supports bounded views" {
  let encoded = encode_probe(0x0807060504030201UL)
  let view = encoded[2:6]
  assert_eq(view.length(), 4)
  assert_eq(view[0], b'\x03')
  assert_eq(view[3], b'\x06')
}

///|
test "QuickCheck package is available" {
  @quickcheck.check(
    fn(value : UInt64) { decode_probe(encode_probe(value)) == value },
    count=32,
  )
}
