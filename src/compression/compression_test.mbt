///|
test "gzip fixed vector remains explicitly unsupported" {
  let gzip_header : Bytes = b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\x03"
  assert_true(
    decompress(@model.compression_gzip(), gzip_header)
    is Err("unsupported compression: gzip provider unavailable"),
  )
}
