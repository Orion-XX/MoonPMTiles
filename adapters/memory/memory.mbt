///|
pub struct MemorySource {
  data : Bytes
  requests : Array[(UInt64, UInt64)]
}

///|
pub fn from_bytes(data : Bytes) -> MemorySource {
  { data, requests: [] }
}

///|
pub fn read_range(
  source : MemorySource,
  offset : UInt64,
  length : UInt64,
) -> Result[Bytes, String] {
  let end = offset + length
  if end < offset {
    return Err("range overflow")
  }
  if offset > source.data.length().to_uint64() ||
    end > source.data.length().to_uint64() {
    return Err("range out of bounds")
  }
  source.requests.push((offset, length))
  let start = offset.to_int()
  let count = length.to_int()
  Ok(Bytes::makei(count, i => source.data[start + i]))
}

///|
pub fn request_count(source : MemorySource) -> Int {
  source.requests.length()
}

///|
pub fn data_length(source : MemorySource) -> UInt64 {
  source.data.length().to_uint64()
}
