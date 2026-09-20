///|
test "validates 206 range response" {
  let response = make_response(206U, Some("bytes 4-6/10"), b"abc")
  assert_eq(validate_response(response, 4UL, 3UL, false, 0UL), Ok(b"abc"))
}

///|
test "rejects short reads and unbounded 200 fallback" {
  assert_true(
    validate_response(
      make_response(206U, Some("bytes 0-2/3"), b"ab"),
      0UL,
      3UL,
      false,
      0UL,
    )
    is Err(_),
  )
  assert_true(
    validate_response(make_response(200U, None, b"abc"), 4UL, 3UL, true, 8UL)
    is Err(_),
  )
}
