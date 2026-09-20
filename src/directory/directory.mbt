///|
pub struct DirectoryEntry {
  tile_id : UInt64
  offset : UInt64
  length : UInt64
  run_length : UInt64
} derive(Eq, @debug.Debug)

///|
pub fn make_entry(
  tile_id : UInt64,
  offset : UInt64,
  length : UInt64,
  run_length : UInt64,
) -> DirectoryEntry {
  { tile_id, offset, length, run_length }
}

///|
pub fn entry_tile_id(entry : DirectoryEntry) -> UInt64 {
  entry.tile_id
}

///|
pub fn entry_offset(entry : DirectoryEntry) -> UInt64 {
  entry.offset
}

///|
pub fn entry_length(entry : DirectoryEntry) -> UInt64 {
  entry.length
}

///|
pub fn entry_run_length(entry : DirectoryEntry) -> UInt64 {
  entry.run_length
}

///|
pub struct Limits {
  max_bytes : UInt64
  max_entries : UInt
}

///|
pub fn make_limits(max_bytes : UInt64, max_entries : UInt) -> Limits {
  { max_bytes, max_entries }
}

///|
fn add_u64(a : UInt64, b : UInt64) -> Result[UInt64, String] {
  let value = a + b
  if value < a {
    Err("integer overflow")
  } else {
    Ok(value)
  }
}

///|
fn read_varint(
  bytes : Bytes,
  cursor : Int,
  limit : Int,
) -> Result[(UInt64, Int), String] {
  let mut value = 0UL
  let mut shift = 0
  let mut position = cursor
  while position < limit && shift < 70 {
    let byte = bytes[position].to_uint64()
    position = position + 1
    if shift == 63 && byte > 1UL {
      return Err("varint overflow")
    }
    value = value | ((byte & 127UL) << shift)
    if (byte & 128UL) == 0UL {
      return Ok((value, position))
    }
    shift = shift + 7
  }
  if position >= limit {
    Err("truncated varint")
  } else {
    Err("varint too long")
  }
}

///|
fn write_varint(value : UInt64, out : Array[Byte], cursor : Int) -> Int {
  let mut value = value
  let mut position = cursor
  while value >= 128UL {
    out[position] = ((value & 127UL) | 128UL).to_byte()
    position = position + 1
    value = value >> 7
  }
  out[position] = value.to_byte()
  position + 1
}

///|
/// Decode the PMTiles four-column directory representation with independent limits.
pub fn decode_directory(
  bytes : Bytes,
  limits : Limits,
) -> Result[Array[DirectoryEntry], String] {
  if bytes.length().to_uint64() > limits.max_bytes {
    return Err("directory exceeds byte limit")
  }
  let mut cursor = 0
  let end = bytes.length()
  let (count, next) = match read_varint(bytes, cursor, end) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  cursor = next
  if count > limits.max_entries.to_uint64() {
    return Err("directory exceeds entry limit")
  }
  if count > 2147483647UL {
    return Err("directory entry count is not representable")
  }
  if limits.max_bytes < 10UL || count > (limits.max_bytes - 10UL) / 40UL {
    return Err("directory entry count exceeds byte budget")
  }
  let count_int = count.to_int()
  let tile_ids : Array[UInt64] = Array::make(count_int, 0UL)
  let run_lengths : Array[UInt64] = Array::make(count_int, 0UL)
  let lengths : Array[UInt64] = Array::make(count_int, 0UL)
  let offsets : Array[UInt64] = Array::make(count_int, 0UL)
  for i = 0; i < count_int; i = i + 1 {
    let (delta, position) = match read_varint(bytes, cursor, end) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    cursor = position
    let previous = if i == 0 { 0UL } else { tile_ids[i - 1] }
    tile_ids[i] = match add_u64(previous, delta) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
  }
  for i = 0; i < count_int; i = i + 1 {
    let (value, position) = match read_varint(bytes, cursor, end) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    cursor = position
    run_lengths[i] = value
  }
  for i = 0; i < count_int; i = i + 1 {
    let (value, position) = match read_varint(bytes, cursor, end) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    cursor = position
    lengths[i] = value
    if value == 0UL {
      return Err("directory entry has zero length")
    }
  }
  for i = 0; i < count_int; i = i + 1 {
    let (value, position) = match read_varint(bytes, cursor, end) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    cursor = position
    if i == 0 {
      offsets[i] = value
    } else {
      offsets[i] = match add_u64(offsets[i - 1], lengths[i - 1]) {
        Ok(v) =>
          match add_u64(v, value) {
            Ok(w) => w
            Err(e) => return Err(e)
          }
        Err(e) => return Err(e)
      }
    }
  }
  let entries : Array[DirectoryEntry] = Array::make(count_int, {
    tile_id: 0UL,
    offset: 0UL,
    length: 1UL,
    run_length: 0UL,
  })
  for i = 0; i < count_int; i = i + 1 {
    if i > 0 && tile_ids[i] <= tile_ids[i - 1] {
      return Err("directory tile ids are not strictly increasing")
    }
    entries[i] = {
      tile_id: tile_ids[i],
      offset: offsets[i],
      length: lengths[i],
      run_length: run_lengths[i],
    }
  }
  Ok(entries)
}

///|
/// Find an exact tile id using binary search in a validated directory.
pub fn find_entry(
  entries : Array[DirectoryEntry],
  tile_id : UInt64,
) -> DirectoryEntry? {
  let mut low = 0
  let mut high = entries.length()
  while low < high {
    let middle = low + (high - low) / 2
    if entries[middle].tile_id < tile_id {
      low = middle + 1
    } else {
      high = middle
    }
  }
  if low < entries.length() && entries[low].tile_id == tile_id {
    Some(entries[low])
  } else {
    None
  }
}

///|
/// Encode entries into the PMTiles four-column directory representation.
pub fn encode_directory(
  entries : Array[DirectoryEntry],
  limits : Limits,
) -> Result[Bytes, String] {
  if entries.length().reinterpret_as_uint() > limits.max_entries {
    return Err("directory exceeds entry limit")
  }
  if entries.length() > 53687091 {
    return Err("directory entry count is not representable")
  }
  let mut required = 10 * (entries.length() + 1)
  let mut previous_tile = 0UL
  let mut previous_offset = 0UL
  for i = 0; i < entries.length(); i = i + 1 {
    let entry = entries[i]
    if entry.length == 0UL || (i > 0 && entry.tile_id <= previous_tile) {
      return Err("invalid directory ordering or length")
    }
    if i > 0 && entry.offset < previous_offset {
      return Err("directory offsets are not increasing")
    }
    previous_tile = entry.tile_id
    previous_offset = entry.offset
    required = required + 32
  }
  let out : Array[Byte] = Array::make(required, 0)
  let mut cursor = 0
  cursor = write_varint(entries.length().to_uint64(), out, cursor)
  previous_tile = 0UL
  for entry in entries {
    cursor = write_varint(entry.tile_id - previous_tile, out, cursor)
    previous_tile = entry.tile_id
  }
  for entry in entries {
    cursor = write_varint(entry.run_length, out, cursor)
  }
  for entry in entries {
    cursor = write_varint(entry.length, out, cursor)
  }
  previous_offset = 0UL
  for entry in entries {
    let delta = if entry.offset < previous_offset {
      0UL
    } else {
      entry.offset - previous_offset
    }
    cursor = write_varint(delta, out, cursor)
    previous_offset = match add_u64(entry.offset, entry.length) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
  }
  let result = Bytes::makei(cursor, i => out[i])
  if result.length().to_uint64() > limits.max_bytes {
    Err("directory exceeds byte limit")
  } else {
    Ok(result)
  }
}
