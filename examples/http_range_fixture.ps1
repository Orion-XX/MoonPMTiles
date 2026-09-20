param(
  [int]$Port = 8765,
  [string]$Root = (Get-Location).Path
)

# Local-only fixture server command placeholder. The HTTP adapter consumes a
# host transport; this script documents the loopback-only integration boundary.
Write-Output "Start a loopback server on 127.0.0.1:$Port serving $Root with byte ranges."
