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
