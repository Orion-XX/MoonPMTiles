///|
pub struct Limits {
  max_root_bytes : UInt64
  max_directory_entries : UInt
}

///|
pub fn make_limits(
  max_root_bytes : UInt64,
  max_directory_entries : UInt,
) -> Limits {
  { max_root_bytes, max_directory_entries }
}

///|
pub struct TileResult {
  data : Bytes
  tile_type : @model.TileType
  compression : @model.Compression
}

///|
pub fn tile_data(result : TileResult) -> Bytes {
  result.data
}

///|
pub fn tile_type(result : TileResult) -> @model.TileType {
  result.tile_type
}

///|
pub fn tile_compression(result : TileResult) -> @model.Compression {
  result.compression
}

///|
pub struct Archive {
  source : @memory.MemorySource
  header : @model.Header
  entries : Array[@directory.DirectoryEntry]
}

///|
pub fn open(
  source : @memory.MemorySource,
  limits : Limits,
) -> Result[Archive, String] {
  let header_bytes = match @memory.read_range(source, 0UL, 127UL) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let header = match @codec.decode_header(header_bytes) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if header.root_length > limits.max_root_bytes {
    return Err("root exceeds limit")
  }
  match @compression.validate(header.internal_compression) {
    Ok(_) => ()
    Err(_) => return Err("unsupported root compression")
  }
  match @compression.validate(header.tile_compression) {
    Ok(_) => ()
    Err(_) => return Err("unsupported tile compression")
  }
  let root = match
    @memory.read_range(source, header.root_offset, header.root_length) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let directory_limits = @directory.make_limits(
    limits.max_root_bytes,
    limits.max_directory_entries,
  )
  let entries = match @directory.decode_directory(root, directory_limits) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ source, header, entries })
}

///|
pub fn get_tile(
  archive : Archive,
  coord : @model.TileCoord,
) -> Result[TileResult?, String] {
  let tile_id = match @tileid.zxy_to_tile_id(coord) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let entry = match @directory.find_entry(archive.entries, tile_id) {
    Some(value) => value
    None => return Ok(None)
  }
  let entry_id = @directory.entry_tile_id(entry)
  let run_length = @directory.entry_run_length(entry)
  if run_length == 0UL && tile_id != entry_id {
    return Ok(None)
  }
  let relative = tile_id - entry_id
  if run_length > 0UL && relative >= run_length {
    return Ok(None)
  }
  let length = @directory.entry_length(entry)
  let offset_delta = relative * length
  if length != 0UL && offset_delta / length != relative {
    return Err("tile range overflow")
  }
  let offset = @directory.entry_offset(entry) + offset_delta
  if offset < @directory.entry_offset(entry) {
    return Err("tile offset overflow")
  }
  let data = match @memory.read_range(archive.source, offset, length) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(
    Some({
      data,
      tile_type: archive.header.tile_type,
      compression: archive.header.tile_compression,
    }),
  )
}

///|
pub fn request_count(archive : Archive) -> Int {
  @memory.request_count(archive.source)
}
