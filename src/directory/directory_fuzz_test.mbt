///|
test "directory malformed corpus stays bounded" {
  let limits = @directory.make_limits(64UL, 4U)
  let cases = [
    Bytes::new(0),
    Bytes::makei(1, _ => 128),
    Bytes::makei(8, _ => 255),
    Bytes::makei(16, i => if i == 0 { 127 } else { 0 }),
  ]
  for input in cases {
    assert_true(@directory.decode_directory(input, limits) is Err(_))
  }
}
