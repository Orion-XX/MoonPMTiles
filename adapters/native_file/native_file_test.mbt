///|
test "native file reports unsupported I/O explicitly" {
  let source = make("fixture.pmtiles")
  assert_true(
    read_range(source, 4294967296UL, 4UL)
    is Err("native file I/O unavailable in current MoonBit toolchain"),
  )
}
