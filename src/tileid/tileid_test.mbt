///|
test "tile id known prefix" {
  assert_eq(@tileid.zxy_to_tile_id(@model.make_tile_coord(0U, 0U, 0U)), Ok(0UL))
  assert_eq(@tileid.zxy_to_tile_id(@model.make_tile_coord(1U, 0U, 0U)), Ok(1UL))
  assert_eq(@tileid.zxy_to_tile_id(@model.make_tile_coord(1U, 0U, 1U)), Ok(2UL))
}

///|
test "tile id round trip and coordinate validation" {
  for z = 0U; z < 8U; z = z + 1U {
    let n = 1U << z.reinterpret_as_int()
    for x = 0U; x < n; x = x + 1U {
      for y = 0U; y < n; y = y + 1U {
        let id = match @tileid.zxy_to_tile_id(@model.make_tile_coord(z, x, y)) {
          Ok(v) => v
          Err(e) => fail(e)
        }
        let back = match @tileid.tile_id_to_zxy(id) {
          Ok(v) => v
          Err(e) => fail(e)
        }
        assert_eq(back, @model.make_tile_coord(z, x, y))
      }
    }
  }
  assert_true(
    @tileid.zxy_to_tile_id(@model.make_tile_coord(2U, 4U, 0U)) is Err(_),
  )
}
