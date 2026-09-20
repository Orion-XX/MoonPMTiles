///|
/// A parsed HTTP byte range response. Network transport is supplied by a host.
pub struct RangeResponse {
  status : UInt
  content_range : String?
  body : Bytes
}

///|
/// Construct a response returned by a host transport.
pub fn make_response(
  status : UInt,
  content_range : String?,
  body : Bytes,
) -> RangeResponse {
  { status, content_range, body }
}

///|
/// Validate a response for an exact requested range.
/// 206 requires Content-Range; 200 is accepted only when the body is exactly
/// the requested length, which keeps fallback bounded and deterministic.
pub fn validate_response(
  response : RangeResponse,
  requested_offset : UInt64,
  requested_length : UInt64,
  allow_full_body_fallback : Bool,
  max_fallback_bytes : UInt64,
) -> Result[Bytes, String] {
  if response.status == 206U {
    match response.content_range {
      Some(value) =>
        if value.length() == 0 {
          return Err("missing Content-Range value")
        }
      None => return Err("missing Content-Range header")
    }
    if response.body.length().to_uint64() != requested_length {
      return Err("short range response")
    }
    Ok(response.body)
  } else if response.status == 200U {
    if !allow_full_body_fallback {
      return Err("full-body fallback is disabled")
    }
    if requested_offset != 0UL || requested_length > max_fallback_bytes {
      return Err("full-body fallback exceeds policy")
    }
    if response.body.length().to_uint64() != requested_length {
      return Err("short full-body response")
    }
    Ok(response.body)
  } else {
    Err("unexpected HTTP status")
  }
}
