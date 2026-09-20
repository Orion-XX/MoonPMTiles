///|
test "header malformed corpus rejects without panic" {
  let valid = match @codec.encode_header(@model.empty_header()) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  let cases = [
    Bytes::new(0),
    Bytes::new(1),
    Bytes::makei(126, _ => 0),
    Bytes::makei(127, i => if i == 7 { 4 } else { valid[i] }),
    Bytes::makei(127, i => if i == 96 { 2 } else { valid[i] }),
    Bytes::makei(127, i => if i == 97 { 255 } else { valid[i] }),
  ]
  for input in cases {
    assert_true(@codec.decode_header(input) is Err(_))
  }
}
