///|
fn sample_entries() -> Array[@directory.DirectoryEntry] {
  [
    @directory.make_entry(1UL, 100UL, 5UL, 1UL),
    @directory.make_entry(4UL, 105UL, 7UL, 0UL),
    @directory.make_entry(9UL, 120UL, 3UL, 2UL),
  ]
}

///|
test "directory round trip and binary search" {
  let limits = @directory.make_limits(1024UL, 16U)
  let encoded = match @directory.encode_directory(sample_entries(), limits) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  let decoded = match @directory.decode_directory(encoded, limits) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  assert_eq(decoded, sample_entries())
  assert_true(@directory.find_entry(decoded, 4UL) is Some(_))
  assert_true(@directory.find_entry(decoded, 5UL) is None)
}

///|
test "directory rejects malformed and bounded inputs" {
  let limits = @directory.make_limits(4UL, 16U)
  assert_true(
    @directory.decode_directory(Bytes::makei(5, _ => 0), limits) is Err(_),
  )
  let oversized = @directory.make_limits(1024UL, 1U)
  let encoded = match
    @directory.encode_directory(
      sample_entries(),
      @directory.make_limits(4096UL, 16U),
    ) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  assert_true(@directory.decode_directory(encoded, oversized) is Err(_))
}

///|
test "directory rejects truncated and overflowing varints" {
  let limits = @directory.make_limits(1024UL, 16U)
  assert_true(
    @directory.decode_directory(Bytes::makei(1, _ => 128), limits) is Err(_),
  )
  assert_true(
    @directory.decode_directory(
      Bytes::makei(11, i => if i == 10 { 2 } else { 128 }),
      limits,
    )
    is Err(_),
  )
}

///|
test "directory rejects duplicate ids and decreasing offsets" {
  let limits = @directory.make_limits(4096UL, 16U)
  let duplicate = [
    @directory.make_entry(2UL, 10UL, 1UL, 0UL),
    @directory.make_entry(2UL, 11UL, 1UL, 0UL),
  ]
  assert_true(@directory.encode_directory(duplicate, limits) is Err(_))
  let decreasing = [
    @directory.make_entry(2UL, 10UL, 2UL, 0UL),
    @directory.make_entry(3UL, 9UL, 1UL, 0UL),
  ]
  assert_true(@directory.encode_directory(decreasing, limits) is Err(_))
}
