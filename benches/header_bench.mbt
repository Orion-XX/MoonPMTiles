///|
fn sample_header() -> @model.Header {
  @model.make_header(
    127UL,
    16UL,
    0UL,
    0UL,
    0UL,
    0UL,
    143UL,
    1024UL,
    16UL,
    16UL,
    16UL,
    false,
    @model.compression_none(),
    @model.compression_none(),
    @model.tile_type_mvt(),
    0,
    14,
    -1800000000,
    -900000000,
    1800000000,
    900000000,
    8,
    0,
    0,
  )
}

///|

///|
test "header encode decode" (it : @bench.T) {
  it.bench(fn() {
    let encoded = match @codec.encode_header(sample_header()) {
      Ok(value) => value
      Err(_) => panic()
    }
    it.keep(@codec.decode_header(encoded))
  })
}
