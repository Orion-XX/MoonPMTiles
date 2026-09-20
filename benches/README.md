# Native benchmark baseline

Run from the repository root:

```powershell
moon bench benches --target native --release
```

The benchmark measures one PMTiles v3 header encode/decode cycle. Record the
toolchain version, commit, host, release mode, and rendered sample output when
comparing candidates. No absolute performance threshold is asserted here.
