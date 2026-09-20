# CLI demo

The supported command names are deterministic:

```text
pmtiles inspect <archive>
pmtiles get-tile <archive> <z> <x> <y>
pmtiles verify <archive>
```

The current repository toolchain has no verified native file I/O binding, so
these commands expose the parser contract and return an explicit transport
error until a native adapter is available.
