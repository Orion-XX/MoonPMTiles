///|
/// Convert z/x/y to the PMTiles cumulative Hilbert TileID.
pub fn zxy_to_tile_id(coord : @model.TileCoord) -> Result[UInt64, String] {
  if coord.z > 31U {
    return Err("zoom exceeds UInt64 tile id capacity")
  }
  let zi = coord.z.reinterpret_as_int()
  let n = 1U << zi
  if coord.x >= n || coord.y >= n {
    return Err("coordinate outside zoom")
  }
  let mut d = 0UL
  if coord.z > 0U {
    d = ((1UL << (2 * zi)) - 1UL) / 3UL
  }
  let mut x = coord.x
  let mut y = coord.y
  let mut s = n / 2U
  while s > 0U {
    let rx = if (x & s) > 0U { 1U } else { 0U }
    let ry = if (y & s) > 0U { 1U } else { 0U }
    d = d + s.to_uint64() * s.to_uint64() * ((3U * rx) ^ ry).to_uint64()
    if ry == 0U {
      if rx == 1U {
        x = s * 2U - 1U - x
        y = s * 2U - 1U - y
      }
      let t = x
      x = y
      y = t
    }
    s = s / 2U
  }
  Ok(d)
}

///|
/// Convert a cumulative Hilbert TileID to z/x/y.
pub fn tile_id_to_zxy(tile_id : UInt64) -> Result[@model.TileCoord, String] {
  let mut z = 0U
  let mut base = 0UL
  while z < 32U {
    let next_zi = (z + 1U).reinterpret_as_int()
    let next = ((1UL << (2 * next_zi)) - 1UL) / 3UL
    if tile_id < next {
      break
    }
    base = next
    z = z + 1U
  }
  if z >= 32U {
    return Err("tile id out of range")
  }
  let mut t = tile_id - base
  let n = 1U << z.reinterpret_as_int()
  let mut x = 0U
  let mut y = 0U
  let mut s = 1U
  while s < n {
    let rx = (t / 2UL).to_uint() & 1U
    let ry = (t ^ rx.to_uint64()).to_uint() & 1U
    if ry == 0U {
      if rx == 1U {
        x = s - 1U - x
        y = s - 1U - y
      }
      let q = x
      x = y
      y = q
    }
    x = x + s * rx
    y = y + s * ry
    t = t / 4UL
    s = s * 2U
  }
  Ok(@model.make_tile_coord(z, x, y))
}
