///|
pub enum CompressionError {
  UnsupportedCompression
} derive(Eq, @debug.Debug)

///|
pub fn supports(compression : @model.Compression) -> Bool {
  compression == @model.compression_none()
}

///|
pub fn validate(
  compression : @model.Compression,
) -> Result[Unit, CompressionError] {
  if supports(compression) {
    Ok(())
  } else {
    Err(UnsupportedCompression)
  }
}

///|
/// Decompress bytes using a target provider. Gzip is rejected explicitly until
/// a target-verified provider is available.
pub fn decompress(
  codec : @model.Compression,
  input : Bytes,
) -> Result[Bytes, String] {
  match codec {
    @model.None => Ok(input)
    @model.Gzip => Err("unsupported compression: gzip provider unavailable")
    _ => Err("unsupported compression codec")
  }
}
