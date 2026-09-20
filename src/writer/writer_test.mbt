///|
test "writer is deterministic" {
  let tiles = [make_tile(0UL, b"a"), make_tile(1UL, b"bc")]
  let first = match write(tiles) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  let second = match write(tiles) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  assert_eq(first, second)
  assert_true(first.length() > 127)
  assert_true(first.length() < 16384 + 127)
}

///|
test "writer rejects unordered and empty tiles" {
  assert_true(write([make_tile(2UL, b"a"), make_tile(1UL, b"b")]) is Err(_))
  assert_true(write([make_tile(1UL, b"")]) is Err(_))
}
