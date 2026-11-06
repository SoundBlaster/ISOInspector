# tkhd differential fixtures

`generate_tkhd_differential.py` generates synthetic standalone boxes in
`tkhd_differential_inputs.json`. The checked-in reference output was obtained
from [MP4Box.js 2.5.0](https://github.com/gpac/mp4box.js/tree/v2.5.0),
distributed under the BSD-3-Clause license. No MP4Box.js code is vendored.

The reference capture normalizes the signed fixed-point transformation matrix
and dimensions to the same units as ISOInspector. The 64-bit values in these
fixtures remain exactly representable by JavaScript numbers. A missing parsed
box means only that MP4Box.js did not produce a box from the supplied bytes;
in particular it may be waiting for more data rather than reporting an error.

To reproduce, install exactly `mp4box@2.5.0` in a separate directory, regenerate
the inputs with Python 3, then run:

```sh
node capture_tkhd_mp4box.cjs /path/to/node_modules/mp4box --check
```

Run the command from this directory. `--write` updates the recorded output.
The recorded bundle SHA-256 identifies the reference implementation. The Swift
tests consume the recorded output without requiring Node or network access.
