///|
fn sample_header() -> @model.Header {
  @model.make_header(
    127UL,
    10UL,
    137UL,
    2UL,
    139UL,
    0UL,
    139UL,
    3UL,
    1UL,
    1UL,
    1UL,
    true,
    @model.compression_none(),
    @model.compression_gzip(),
    @model.tile_type_mvt(),
    0,
    3,
    -1800000000,
    -900000000,
    1800000000,
    900000000,
    2,
    0,
    0,
  )
}

///|
test "header encodes to 127 bytes and round trips" {
  let header = sample_header()
  let bytes = match @codec.encode_header(header) {
    Ok(v) => v
    Err(e) => fail(e)
  }
  assert_eq(bytes.length(), 127)
  let decoded = match @codec.decode_header(bytes) {
    Ok(v) => v
    Err(e) => fail(e)
  }
  assert_eq(decoded.root_offset, header.root_offset)
  assert_eq(decoded.tile_data_length, header.tile_data_length)
  assert_eq(decoded.tile_type, @model.tile_type_mvt())
}

///|
test "header rejects bad magic version enum and zoom" {
  let good = match @codec.encode_header(sample_header()) {
    Ok(v) => v
    Err(e) => fail(e)
  }
  let bad_magic = Bytes::makei(127, i => if i == 0 { b'X' } else { good[i] })
  assert_true(@codec.decode_header(bad_magic) is Err(_))
  let bad_version = Bytes::makei(127, i => if i == 7 { 2 } else { good[i] })
  assert_true(@codec.decode_header(bad_version) is Err(_))
  let bad_enum = Bytes::makei(127, i => if i == 97 { 9 } else { good[i] })
  assert_true(@codec.decode_header(bad_enum) is Err(_))
  let short = Bytes::new(126)
  assert_true(@codec.decode_header(short) is Err(_))
}
