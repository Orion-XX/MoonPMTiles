///|
/// A deterministic tile input. Inputs must be strictly increasing by tile id.
pub struct Tile {
  id : UInt64
  data : Bytes
}

///|
/// Construct a tile input from a tile id and its uncompressed bytes.
pub fn make_tile(id : UInt64, data : Bytes) -> Tile {
  { id, data }
}

///|
/// Return the encoded archive bytes for an ordered set of tiles.
/// The archive uses no metadata, no leaves, and no compression.
pub fn write(tiles : Array[Tile]) -> Result[Bytes, String] {
  let mut tile_data_length = 0UL
  for i = 0; i < tiles.length(); i = i + 1 {
    if i > 0 && tiles[i].id <= tiles[i - 1].id {
      return Err("tiles must be strictly increasing")
    }
    let length = tiles[i].data.length().to_uint64()
    if length == 0UL {
      return Err("tile data must not be empty")
    }
    let next = tile_data_length + length
    if next < tile_data_length {
      return Err("tile data length overflow")
    }
    tile_data_length = next
  }
  let root_offset = 127UL
  let mut root_length = 0UL
  let tile_data_offset = root_offset
  let mut root : Bytes = Bytes::makei(0, _ => 0)
  let mut attempts = 0
  while attempts < 4 {
    let tile_offset = tile_data_offset + root_length
    if tile_offset < tile_data_offset {
      return Err("tile data offset overflow")
    }
    let entries : Array[@directory.DirectoryEntry] = Array::make(
      tiles.length(),
      @directory.make_entry(0UL, 0UL, 1UL, 0UL),
    )
    let mut offset = tile_offset
    for i = 0; i < tiles.length(); i = i + 1 {
      let length = tiles[i].data.length().to_uint64()
      entries[i] = @directory.make_entry(tiles[i].id, offset, length, 0UL)
      let next = offset + length
      if next < offset {
        return Err("tile data offset overflow")
      }
      offset = next
    }
    root = match
      @directory.encode_directory(
        entries,
        @directory.make_limits(16384UL, 100000U),
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let next_root_length = root.length().to_uint64()
    if next_root_length == root_length {
      break
    }
    root_length = next_root_length
    attempts = attempts + 1
  }
  if root.length().to_uint64() > 16384UL {
    return Err("root exceeds 16 KiB")
  }
  let metadata_offset = root_offset + root.length().to_uint64()
  let tile_data_offset_final = metadata_offset
  let total = tile_data_offset_final + tile_data_length
  if total < tile_data_offset_final || total > 2147483647UL {
    return Err("archive is too large")
  }
  let header = @model.make_header(
    root_offset,
    root.length().to_uint64(),
    0UL,
    0UL,
    0UL,
    0UL,
    tile_data_offset_final,
    tile_data_length,
    tiles.length().to_uint64(),
    tiles.length().to_uint64(),
    tiles.length().to_uint64(),
    false,
    @model.compression_none(),
    @model.compression_none(),
    @model.tile_type_mvt(),
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  )
  let header_bytes = match @codec.encode_header(header) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let out_length = total.to_int()
  let out : Array[Byte] = Array::make(out_length, 0)
  for i = 0; i < header_bytes.length(); i = i + 1 {
    out[i] = header_bytes[i]
  }
  for i = 0; i < root.length(); i = i + 1 {
    out[127 + i] = root[i]
  }
  let mut cursor = tile_data_offset_final.to_int()
  for tile in tiles {
    for i = 0; i < tile.data.length(); i = i + 1 {
      out[cursor + i] = tile.data[i]
    }
    cursor = cursor + tile.data.length()
  }
  Ok(Bytes::from_array(out))
}
