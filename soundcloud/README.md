# Soundcloud Tooling

# Use-Cases

## Download Capability

1. Soundcloud song has download link available, so we want to use that
2. Soundcloud song has alternative downlink link, so we need to use that. But we can still pull metadata from website

## Song Type
1. Single, solo-download
2. Single, but the artist is custom (sometimes Soundcloud artists put weird things)
3. Single, but part of a bigger album (i.e. change album tag on download). This is rare.

## How To Use

```
scdl -l https://soundcloud.com/yojasmusic/brrrt --force-metadata
```
