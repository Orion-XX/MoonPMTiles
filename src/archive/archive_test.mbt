///|
fn fixture() -> Result[Bytes, String] {
  let tile_offset = 200UL
  let entries = [@directory.make_entry(0UL, tile_offset, 1UL, 0UL)]
  let directory = match
    @directory.encode_directory(entries, @directory.make_limits(64UL, 4U)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let header = @model.make_header(
    127UL,
    directory.length().to_uint64(),
    0UL,
    0UL,
    0UL,
    0UL,
    tile_offset,
    1UL,
    1UL,
    1UL,
    1UL,
    false,
    @model.compression_none(),
    @model.compression_none(),
    @model.tile_type_mvt(),
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  )
  let encoded_header = match @codec.encode_header(header) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(
    Bytes::makei(tile_offset.to_int() + 1, i => {
      if i < 127 {
        encoded_header[i]
      } else if i < 127 + directory.length() {
        directory[i - 127]
      } else if i == tile_offset.to_int() {
        b't'
      } else {
        0
      }
    }),
  )
}

///|
test "memory archive reads header root and tile with exact requests" {
  let fixture_bytes = match fixture() {
    Ok(value) => value
    Err(error) => fail(error)
  }
  let source = @memory.from_bytes(fixture_bytes)
  let archive = match @archive.open(source, @archive.make_limits(64UL, 4U)) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  let result = match
    @archive.get_tile(archive, @model.make_tile_coord(0U, 0U, 0U)) {
    Ok(Some(value)) => value
    Ok(None) => fail("tile missing")
    Err(error) => fail(error)
  }
  assert_eq(@archive.tile_data(result), b"t")
  assert_eq(@archive.request_count(archive), 3)
}

///|
test "memory archive enforces root and short read limits" {
  let fixture_bytes = match fixture() {
    Ok(value) => value
    Err(error) => fail(error)
  }
  let source = @memory.from_bytes(fixture_bytes)
  assert_true(@archive.open(source, @archive.make_limits(4UL, 4U)) is Err(_))
  assert_true(@memory.read_range(source, 1000UL, 1UL) is Err(_))
}
