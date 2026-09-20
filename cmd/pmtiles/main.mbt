///|
/// Deterministic CLI command result used by the native entry point.
pub enum Command {
  Inspect
  GetTile
  Verify
}

///|
/// Parse the three supported commands without performing I/O.
pub fn parse_command(name : String) -> Result[Command, String] {
  match name {
    "inspect" => Ok(Inspect)
    "get-tile" => Ok(GetTile)
    "verify" => Ok(Verify)
    _ => Err("unknown command")
  }
}

///|
/// Return stable usage text for invalid invocations.
pub fn usage() -> String {
  "pmtiles <inspect|get-tile|verify>"
}
