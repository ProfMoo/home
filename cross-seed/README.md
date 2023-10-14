# Cross-Seed

Tool for detecting potential cross-seed opportunities and automatically realizing it.

## Details

The tool's homepage is found [here](https://github.com/cross-seed/cross-seed). Under the hood, this instantiation of the tool uses [prowlarr](../prowlarr/) as a facade API around the backend trackers. Prowlarr ensures that cross-seed doesn't need to know the details of each underlying tracker and can instead understand one Torznab specification.

This instantiation is built to run in daemon mode. This means that it will run on a schedule on some interval, defined in the runtime parameters.
