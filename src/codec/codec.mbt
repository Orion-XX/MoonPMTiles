///|
fn read_u64(bytes : Bytes, offset : Int) -> UInt64 {
  let mut value = 0UL
  for i = 0; i < 8; i = i + 1 {
    value = value | (bytes[offset + i].to_uint64() << (i * 8))
  }
  value
}

///|
fn write_u64(value : UInt64, offset : Int, out : Array[Byte]) -> Unit {
  for i = 0; i < 8; i = i + 1 {
    out[offset + i] = ((value >> (i * 8)) & 255UL).to_byte()
  }
}

///|
fn read_i32(bytes : Bytes, offset : Int) -> Int {
  let raw = bytes[offset].to_int() |
    (bytes[offset + 1].to_int() << 8) |
    (bytes[offset + 2].to_int() << 16) |
    (bytes[offset + 3].to_int() << 24)
  raw
}

///|
fn write_i32(value : Int, offset : Int, out : Array[Byte]) -> Unit {
  for i = 0; i < 4; i = i + 1 {
    out[offset + i] = ((value >> (i * 8)) & 255).to_byte()
  }
}

///|
fn compression_from_byte(value : Byte) -> Result[@model.Compression, String] {
  @model.compression_of(value)
}

///|
fn tile_type_from_byte(value : Byte) -> Result[@model.TileType, String] {
  @model.tile_type_of(value)
}

///|
/// Encode a validated PMTiles v3 header into exactly 127 bytes.
pub fn encode_header(header : @model.Header) -> Result[Bytes, String] {
  if header.max_zoom < header.min_zoom {
    return Err("max zoom is less than min zoom")
  }
  if header.root_offset + header.root_length < header.root_offset {
    return Err("root range overflow")
  }
  let out : Array[Byte] = Array::make(127, 0)
  let magic = b"PMTiles"
  for i = 0; i < 7; i = i + 1 {
    out[i] = magic[i]
  }
  out[7] = 3
  write_u64(header.root_offset, 8, out)
  write_u64(header.root_length, 16, out)
  write_u64(header.metadata_offset, 24, out)
  write_u64(header.metadata_length, 32, out)
  write_u64(header.leaf_offset, 40, out)
  write_u64(header.leaf_length, 48, out)
  write_u64(header.tile_data_offset, 56, out)
  write_u64(header.tile_data_length, 64, out)
  write_u64(header.addressed_tiles_count, 72, out)
  write_u64(header.tile_entries_count, 80, out)
  write_u64(header.tile_contents_count, 88, out)
  out[96] = if header.clustered { 1 } else { 0 }
  out[97] = @model.compression_code(header.internal_compression)
  out[98] = @model.compression_code(header.tile_compression)
  out[99] = @model.tile_type_code(header.tile_type)
  out[100] = header.min_zoom
  out[101] = header.max_zoom
  write_i32(header.min_lon, 102, out)
  write_i32(header.min_lat, 106, out)
  write_i32(header.max_lon, 110, out)
  write_i32(header.max_lat, 114, out)
  out[118] = header.center_zoom
  write_i32(header.center_lon, 119, out)
  write_i32(header.center_lat, 123, out)
  Ok(Bytes::from_array(out))
}

///|
/// Decode and validate a PMTiles v3 header.
pub fn decode_header(bytes : Bytes) -> Result[@model.Header, String] {
  if bytes.length() < 127 {
    return Err("header is shorter than 127 bytes")
  }
  let magic = b"PMTiles"
  for i = 0; i < 7; i = i + 1 {
    if bytes[i] != magic[i] {
      return Err("invalid magic")
    }
  }
  if bytes[7] != 3 {
    return Err("unsupported version")
  }
  if bytes[96] > 1 {
    return Err("invalid clustered flag")
  }
  let internal = match compression_from_byte(bytes[97]) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let tile_compression = match compression_from_byte(bytes[98]) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let tile_type = match tile_type_from_byte(bytes[99]) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let min_zoom = bytes[100]
  let max_zoom = bytes[101]
  if max_zoom < min_zoom {
    return Err("max zoom is less than min zoom")
  }
  Ok(
    @model.make_header(
      read_u64(bytes, 8),
      read_u64(bytes, 16),
      read_u64(bytes, 24),
      read_u64(bytes, 32),
      read_u64(bytes, 40),
      read_u64(bytes, 48),
      read_u64(bytes, 56),
      read_u64(bytes, 64),
      read_u64(bytes, 72),
      read_u64(bytes, 80),
      read_u64(bytes, 88),
      bytes[96] == 1,
      internal,
      tile_compression,
      tile_type,
      min_zoom,
      max_zoom,
      read_i32(bytes, 102),
      read_i32(bytes, 106),
      read_i32(bytes, 110),
      read_i32(bytes, 114),
      bytes[118],
      read_i32(bytes, 119),
      read_i32(bytes, 123),
    ),
  )
}
