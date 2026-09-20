///|
test "tile id boundary corpus rejects invalid coordinates" {
  assert_true(
    @tileid.zxy_to_tile_id(@model.make_tile_coord(32U, 0U, 0U)) is Err(_),
  )
  assert_true(
    @tileid.zxy_to_tile_id(@model.make_tile_coord(1U, 2U, 0U)) is Err(_),
  )
  assert_true(@tileid.tile_id_to_zxy(18446744073709551615UL) is Err(_))
}
