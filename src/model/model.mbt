///|
pub const HEADER_LEN : Int = 127

///|
pub fn compression_values() -> Array[Compression] {
  [Unknown, None, Gzip, Brotli, Zstd]
}

///|
pub fn compression_none() -> Compression {
  None
}

///|
pub fn compression_gzip() -> Compression {
  Gzip
}

///|
pub fn tile_type_mvt() -> TileType {
  Mvt
}

///|
pub fn compression_of(code : Byte) -> Result[Compression, String] {
  match code {
    0 => Ok(Unknown)
    1 => Ok(None)
    2 => Ok(Gzip)
    3 => Ok(Brotli)
    4 => Ok(Zstd)
    _ => Err("invalid compression")
  }
}

///|
pub fn tile_type_of(code : Byte) -> Result[TileType, String] {
  match code {
    0 => Ok(Unknown)
    1 => Ok(Mvt)
    2 => Ok(Png)
    3 => Ok(Jpeg)
    4 => Ok(Webp)
    5 => Ok(Avif)
    6 => Ok(MapLibre)
    _ => Err("invalid tile type")
  }
}

///|
pub fn compression_code(value : Compression) -> Byte {
  match value {
    Unknown => 0
    None => 1
    Gzip => 2
    Brotli => 3
    Zstd => 4
  }
}

///|
pub fn tile_type_code(value : TileType) -> Byte {
  match value {
    Unknown => 0
    Mvt => 1
    Png => 2
    Jpeg => 3
    Webp => 4
    Avif => 5
    MapLibre => 6
  }
}

///|
pub fn tile_type_values() -> Array[TileType] {
  [Unknown, Mvt, Png, Jpeg, Webp, Avif, MapLibre]
}

///|
pub fn empty_header() -> Header {
  {
    root_offset: 0UL,
    root_length: 0UL,
    metadata_offset: 0UL,
    metadata_length: 0UL,
    leaf_offset: 0UL,
    leaf_length: 0UL,
    tile_data_offset: 0UL,
    tile_data_length: 0UL,
    addressed_tiles_count: 0UL,
    tile_entries_count: 0UL,
    tile_contents_count: 0UL,
    clustered: false,
    internal_compression: None,
    tile_compression: None,
    tile_type: Unknown,
    min_zoom: 0,
    max_zoom: 0,
    min_lon: 0,
    min_lat: 0,
    max_lon: 0,
    max_lat: 0,
    center_zoom: 0,
    center_lon: 0,
    center_lat: 0,
  }
}

///|
pub fn origin_coord() -> TileCoord {
  { z: 0U, x: 0U, y: 0U }
}

///|
pub fn make_tile_coord(z : UInt, x : UInt, y : UInt) -> TileCoord {
  { z, x, y }
}

///|
pub fn make_header(
  root_offset : UInt64,
  root_length : UInt64,
  metadata_offset : UInt64,
  metadata_length : UInt64,
  leaf_offset : UInt64,
  leaf_length : UInt64,
  tile_data_offset : UInt64,
  tile_data_length : UInt64,
  addressed_tiles_count : UInt64,
  tile_entries_count : UInt64,
  tile_contents_count : UInt64,
  clustered : Bool,
  internal_compression : Compression,
  tile_compression : Compression,
  tile_type : TileType,
  min_zoom : Byte,
  max_zoom : Byte,
  min_lon : Int,
  min_lat : Int,
  max_lon : Int,
  max_lat : Int,
  center_zoom : Byte,
  center_lon : Int,
  center_lat : Int,
) -> Header {
  {
    root_offset,
    root_length,
    metadata_offset,
    metadata_length,
    leaf_offset,
    leaf_length,
    tile_data_offset,
    tile_data_length,
    addressed_tiles_count,
    tile_entries_count,
    tile_contents_count,
    clustered,
    internal_compression,
    tile_compression,
    tile_type,
    min_zoom,
    max_zoom,
    min_lon,
    min_lat,
    max_lon,
    max_lat,
    center_zoom,
    center_lon,
    center_lat,
  }
}

///|
pub enum Compression {
  Unknown
  None
  Gzip
  Brotli
  Zstd
} derive(Eq, @debug.Debug)

///|
pub enum TileType {
  Unknown
  Mvt
  Png
  Jpeg
  Webp
  Avif
  MapLibre
} derive(Eq, @debug.Debug)

///|
pub struct Header {
  root_offset : UInt64
  root_length : UInt64
  metadata_offset : UInt64
  metadata_length : UInt64
  leaf_offset : UInt64
  leaf_length : UInt64
  tile_data_offset : UInt64
  tile_data_length : UInt64
  addressed_tiles_count : UInt64
  tile_entries_count : UInt64
  tile_contents_count : UInt64
  clustered : Bool
  internal_compression : Compression
  tile_compression : Compression
  tile_type : TileType
  min_zoom : Byte
  max_zoom : Byte
  min_lon : Int
  min_lat : Int
  max_lon : Int
  max_lat : Int
  center_zoom : Byte
  center_lon : Int
  center_lat : Int
}

///|
pub struct TileCoord {
  z : UInt
  x : UInt
  y : UInt
} derive(Eq, @debug.Debug)
