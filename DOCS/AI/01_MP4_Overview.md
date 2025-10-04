AI Overview

Container File Formats: Definitive Guide (2023) | Bitmovin
The MP4 (MPEG-4 Part 14) container specification is based on the ISO Base Media File Format (ISOBMFF or MPEG-4 Part 12), defining a hierarchical structure of atoms or boxes that organize media data (video, audio, subtitles) and metadata, including ftyp (file type), moov (movie metadata), and mdat (media data) boxes. This modular structure allows for flexibility in content, supports various codecs like H.264 and AAC, and enables efficient streaming and editing. The standard provides details on box headers (size, name, data), compatible brands, track information, and sample tables for precise playback control.  
Key Components of the MP4 Specification
ISO Base Media File Format (ISOBMFF): The foundational standard for time-based multimedia, defining the structure for MP4 files. 
Atoms/Boxes: The fundamental building blocks of an MP4 file. Each box contains a header with its size and four-character name (FourCC) followed by its data. 
Hierarchical Structure: Boxes can be nested within other boxes to create a structured hierarchy for organizing data. 
Major Boxes in an MP4 File
ftyp (File Type Box): Identifies the file type, providing compatibility information and specifying major and compatible brands, such as isom or avc1. 
moov (Movie Box): Contains all the movie's metadata, including information about the different media tracks (video, audio, subtitles), their codecs, and timing. 
mdat (Media Data Box): Holds the actual compressed audio, video, and other media content. 
Other Boxes: Many other boxes exist for specific functions, such as moof for video fragments, stts for time-to-sample tables, stsc for sample-to-chunk mapping, and stsz for sample sizes. 
Supported Codecs and Applications
Codecs: MP4 files support a wide range of codecs, including the most common video codecs H.264 (AVC) and HEVC, and the audio codec AAC. 
Functionality: The format's flexibility supports dynamic adaptive streaming over HTTP (DASH), progressive download, and streaming protocols like Apple's HLS. 
Where to Find the Full Specification 
The definitive source for the full MP4 specification is the ISO/IEC 14496-14 standard, which is the MPEG-4 Part 14 specification. The ISOBMFF is defined in ISO/IEC 14496-12.

1. [ISO/IEC 14496-14:2020 Information technology — Coding of audio-visual objects Part 14: MP4 file format](https://www.iso.org/standard/79110.html)