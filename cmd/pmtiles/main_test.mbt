///|
test "cli command parsing is stable" {
  assert_true(parse_command("inspect") is Ok(Inspect))
  assert_true(parse_command("get-tile") is Ok(GetTile))
  assert_true(parse_command("verify") is Ok(Verify))
  assert_true(parse_command("other") is Err(_))
  assert_eq(usage(), "pmtiles <inspect|get-tile|verify>")
}
