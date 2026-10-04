# build/ - image build inputs

## Layer archives

A layer declares its downloads in an `archives` file in the layer directory.
Each line holds three fields:

```
<url> <sha256> <destination>
```

`piw build` turns each line into an `ADD --checksum=sha256:<sha> <url>
<destination>` step in the generated Dockerfile. The download and the
checksum stay together, and a mismatch fails the build. The shipped
workstation layer uses this mechanism for rizin, ffmpeg, and yadm.

## Manual downloads

A layer can copy a file from the build context instead of fetching it. Place
the file in `build/archives/` with the exact name the layer expects. The
directory is gitignored, and the root `.dockerignore` keeps it in the build
context. Use this path when the build host cannot reach a download URL.

The default image builds from the repository root, so a layer step can copy
`build/archives/<file>`.

## Rules

- `build/archives/` is gitignored. Never commit an archive.
- The root `.dockerignore` must never exclude `build/archives/`.
- A version pin lives in the layer's `archives` file and in the layer's
  `install.sh`. Bump both together.
