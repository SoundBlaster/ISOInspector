# Bento4 Source Code References

This document lists key Bento4 source modules that can be used as implementation references for ISO Base Media File Format tooling. The files live under [`DOCS/SAMPLES/Bento4-master`](./SAMPLES/Bento4-master) and are organized by language.

## C++ Implementation Highlights

- **Core library** – foundational atom definitions, I/O primitives, and utility classes that power all Bento4 tooling. [`Source/C++/Core`](./SAMPLES/Bento4-master/Source/C++/Core)
- **Applications** – command-line utilities demonstrating how to manipulate MP4 files with the library, such as `mp4info`, `mp4dump`, and `mp4fragment`. [`Source/C++/Apps`](./SAMPLES/Bento4-master/Source/C++/Apps)
- **Codecs support** – codec-specific helpers and descriptors used by the core when parsing tracks. [`Source/C++/Codecs`](./SAMPLES/Bento4-master/Source/C++/Codecs)
- **System wrappers** – platform abstractions for file access, threading, and networking that you can reuse or adapt. [`Source/C++/System`](./SAMPLES/Bento4-master/Source/C++/System)
- **Adapters and Metadata** – optional layers for integrating DRM, metadata handling, and packaging workflows. [`Source/C++/Adapters`](./SAMPLES/Bento4-master/Source/C++/Adapters), [`Source/C++/MetaData`](./SAMPLES/Bento4-master/Source/C++/MetaData)

### Notable Entry Points

| Purpose | Reference |
| --- | --- |
| Library umbrella header | [`AP4.h`](./SAMPLES/Bento4-master/Source/C++/Core/Ap4.h)
| Sample CLI for MP4 inspection | [`Mp4Info.cpp`](./SAMPLES/Bento4-master/Source/C++/Apps/Mp4Info/Mp4Info.cpp)
| Fragmentation workflow | [`Mp4Fragment.cpp`](./SAMPLES/Bento4-master/Source/C++/Apps/Mp4Fragment/Mp4Fragment.cpp)

## Java Implementation Highlights

The Java bindings mirror the C++ atom model and provide a pure-Java parser for MP4 structures.

- **Package root** – core atom classes and parsing utilities. [`Source/Java/com/axiosys/bento4`](./SAMPLES/Bento4-master/Source/Java/com/axiosys/bento4)
- **Container hierarchy** – classes such as `ContainerAtom`, `AtomParent`, and `Track` that illustrate how to model box relationships. Useful when building Java-based inspectors. Examples include [`ContainerAtom.java`](./SAMPLES/Bento4-master/Source/Java/com/axiosys/bento4/ContainerAtom.java) and [`Track.java`](./SAMPLES/Bento4-master/Source/Java/com/axiosys/bento4/Track.java).
- **Sample entries and codecs** – implementations of `AudioSampleEntry`, `Mp4aSampleEntry`, `Mp4vSampleEntry`, and encrypted variants for understanding codec descriptors. See [`AudioSampleEntry.java`](./SAMPLES/Bento4-master/Source/Java/com/axiosys/bento4/AudioSampleEntry.java), [`Mp4aSampleEntry.java`](./SAMPLES/Bento4-master/Source/Java/com/axiosys/bento4/Mp4aSampleEntry.java), and [`EncvSampleEntry.java`](./SAMPLES/Bento4-master/Source/Java/com/axiosys/bento4/EncvSampleEntry.java).
- **Testing harness** – `Test.java` provides a compact example of wiring the parser and traversing atoms. [`Test.java`](./SAMPLES/Bento4-master/Source/Java/com/axiosys/bento4/Test.java)

## Python Implementation Highlights

Python utilities offer scripting examples for common packaging tasks.

- **Utility scripts** – command-line helpers for DASH/HLS packaging, manifest manipulation, and DRM workflows. [`Source/Python/utils`](./SAMPLES/Bento4-master/Source/Python/utils)
- **Core helpers** – shared helpers such as `mp4utils.py` and `aes.py` encapsulate box parsing and cryptographic primitives. [`mp4utils.py`](./SAMPLES/Bento4-master/Source/Python/utils/mp4utils.py), [`aes.py`](./SAMPLES/Bento4-master/Source/Python/utils/aes.py)
- **Streaming workflows** – ready-made scripts for building adaptive streaming presentations, including [`mp4-dash.py`](./SAMPLES/Bento4-master/Source/Python/utils/mp4-dash.py), [`mp4-hls.py`](./SAMPLES/Bento4-master/Source/Python/utils/mp4-hls.py), and [`mp4-dash-encode.py`](./SAMPLES/Bento4-master/Source/Python/utils/mp4-dash-encode.py).
- **Key management** – DRM-related utilities such as [`pr-derive-key.py`](./SAMPLES/Bento4-master/Source/Python/utils/pr-derive-key.py) and [`wv-request.py`](./SAMPLES/Bento4-master/Source/Python/utils/wv-request.py) illustrate how to automate key workflows.

Use these references as starting points when designing or extending ISOInspector features across different language stacks.
