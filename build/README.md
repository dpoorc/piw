# build/ — image build inputs

`build/archives/` holds the archives and binaries the variant Dockerfiles
install. Image builds run with the repo root as the Docker build context
(see the root `.dockerignore`) so that `COPY build/archives/<file>` works
from every variant Dockerfile.

## When to fetch manually

If your network cannot reach GitHub (VPN blocks, proxy restrictions), fetch
the files below in a browser and place them here with the exact names shown.
`piw build --offline <profile>` refuses to build when a needed archive is
missing and prints this list.

## Manifest

All entries are amd64/x86_64. For aarch64 builds, fetch the matching
architecture asset and adjust the COPY filename in the variant Dockerfile.

| File | Source URL | Variants | Purpose |
|------|-----------|----------|---------|
| go1.27.1.linux-amd64.tar.gz | https://go.dev/dl/go1.27.1.linux-amd64.tar.gz | workstation | Go toolchain |
| rust-1.98.1-x86_64-unknown-linux-gnu.tar.xz | https://static.rust-lang.org/dist/rust-1.98.1-x86_64-unknown-linux-gnu.tar.xz | workstation | Rust GNU toolchain (default) |
| rust-1.98.1-x86_64-unknown-linux-musl.tar.xz | https://static.rust-lang.org/dist/rust-1.98.1-x86_64-unknown-linux-musl.tar.xz | workstation | Rust musl std (static-build target) |
| rizin-v0.9.1-static-x86_64.tar.xz | https://github.com/rizinorg/rizin/releases/download/v0.9.1/rizin-v0.9.1-static-x86_64.tar.xz | workstation | rizin reverse-engineering suite |
| 7z2603-linux-x64.tar.xz | https://github.com/ip7z/7zip/releases/download/26.03/7z2603-linux-x64.tar.xz | workstation | 7-Zip 26.03 official build (7zz; RAR4/RAR5 extraction) |
| ffmpeg-n9.0-latest-linux64-gpl-9.0.tar.xz | https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n9.0-latest-linux64-gpl-9.0.tar.xz | workstation | ffmpeg + ffprobe 9.0 static build |
| yq_linux_amd64.tar.gz | https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64.tar.gz | devops, workstation | yq YAML processor |
| yadm-3.5.0 | https://raw.githubusercontent.com/TheLocehiliosan/yadm/3.5.0/yadm | workstation | yadm dotfile manager script |
| tofu_1.12.6_linux_amd64.tar.gz | https://github.com/opentofu/opentofu/releases/download/v1.12.6/tofu_1.12.6_linux_amd64.tar.gz | workstation | OpenTofu IaC tool |
| packer_1.16.0_linux_amd64.zip | https://releases.hashicorp.com/packer/1.16.0/packer_1.16.0_linux_amd64.zip | workstation | Hashicorp Packer |
| hadolint-linux-x86_64 | https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 | workstation | Dockerfile linter |
| tflint_linux_amd64.zip | https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip | workstation | Terraform/OpenTofu linter |
| uv-x86_64-unknown-linux-gnu.tar.gz | https://github.com/astral-sh/uv/releases/download/0.12.13/uv-x86_64-unknown-linux-gnu.tar.gz | workstation | uv Python package manager |
| mise-v2026.9.17-linux-x64.tar.gz | https://github.com/jdx/mise/releases/download/v2026.9.17/mise-v2026.9.17-linux-x64.tar.gz | core | mise tool manager (toolchains + release binaries) |

Note on ffmpeg: the `latest` BtbN release tag is rebuilt daily; the
`n9.0` filename pins the 9.0 branch. The manifest checksum commits the
exact archive used by this repo.

Note on yadm: fetch the standalone script (the raw.githubusercontent URL
above saves the `yadm` file directly). If you instead downloaded GitHub's
repo tarball (`yadm-3.5.0.tar.gz`), extract the script from it:
`tar -xzf yadm-3.5.0.tar.gz -O yadm-3.5.0/yadm > yadm-3.5.0`.

## Checksums (sha256)

Present archives, for integrity verification:

```
dc99eff5008f1ab79bd7084c68513701547a808a89502bf4133683535ab3c695  7z2603-linux-x64.tar.xz
16e4a4a13088ca9f0b5a8ad4d17a1a296bc3cbf007a5ac612986a2220d329395  ffmpeg-n9.0-latest-linux64-gpl-9.0.tar.xz
63d339f0da5ab53635a56f2490a7984dfe12dfcff22ad749f63edaf590168445  go1.27.1.linux-amd64.tar.gz
c7187db94eeeeca956519a6af171adc31453941a1e777961f6e680f697c8c507  hadolint-linux-x86_64
8d1bcbc0b2ba167ee765e7410502c3f89974d0195eb8ec74537bc93bb367420d  mise-v2026.9.17-linux-x64.tar.gz
5edcd14ab59b535040c512dbecd6ec9ef976a000b073c19d93e4c431c948581e  packer_1.16.0_linux_amd64.zip
9102249a9f0b6319c5334a2e5cf8d9cc3f2035e1d3def027c41f6a90f647e8cf  rizin-v0.9.1-static-x86_64.tar.xz
5326b36c53de11d148c8f8dab6553a3d1006c2cfd32123683073fad3c302605b  rust-1.98.1-x86_64-unknown-linux-gnu.tar.xz
2ada47301c1b232e1d98d59bd11df13274ba76ddd07336b90464010cf4644628  rust-1.98.1-x86_64-unknown-linux-musl.tar.xz
cca9d13e2e1d7a2c627af60ff899a3c9b74212899416aeb96ec764d2ef954537  tflint_linux_amd64.zip
50a6106fa4de523d09c87af85f3db1dd47535fc005727fdca6852146476b88ec  tofu_1.12.6_linux_amd64.tar.gz
745765a3b6e360ad76743599ae5c42e9278c7edf8bbff9fc76d05bf2623a04dd  uv-x86_64-unknown-linux-gnu.tar.gz
d8c2d661725b98e9910e4a59b58beed5cfb01f5196a825a08668ff0887f7441d  yadm-3.5.0
38b907b21b1b04327fb9481c595331d925a67c6ee1aabd0ef419d0b7d12dfb3d  yq_linux_amd64.tar.gz
```

## Rules

- This directory is gitignored. Never commit archives.
- The root `.dockerignore` must never exclude `build/archives/` (builds need
  it); only `.gitignore` ignores it.
- Version pins live in the archive filenames and the Dockerfile COPY lines.
  Bump both together.
