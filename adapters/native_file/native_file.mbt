///|
/// Native file range source contract. The current MoonBit toolchain does not
/// expose a stable file API, so this package provides a provider boundary and
/// returns an explicit unsupported error until a target-verified binding exists.
pub struct NativeFileSource {
  path : String
}

///|
/// Create a native file source descriptor.
pub fn make(path : String) -> NativeFileSource {
  { path, }
}

///|
/// Read an exact byte range from the file.
pub fn read_range(
  _source : NativeFileSource,
  _offset : UInt64,
  _length : UInt64,
) -> Result[Bytes, String] {
  Err("native file I/O unavailable in current MoonBit toolchain")
}
