# TODO: Replace Bento4 Test Fixtures

## Background

Currently, the CLI compatibility tests use Bento4 sample files located in:

- `DOCS/SAMPLES/Bento4-master/Test/Data/`

Specifically, the test asserts that `DOCS/SAMPLES/Bento4-master/Test/Data/video-h264-001.mp4` exists before exercising the exporter.

## Task

Replace these external test fixtures with our own sample MP4 files to:

1. Remove dependency on Bento4 samples
2. Have full control over test data
3. Ensure test files match our specific testing needs

## Files to Replace

The following test data files are currently in use:

- video-h264-001.mp4
- video-h264-002.mp4
- audio-aac-001.mp4
- audio-aac-002.mp4
- audio-aac-003.mp4
- (check Test/Data directory for complete list)

## Steps

1. Create our own minimal MP4 sample files for testing
2. Update test references to point to new locations
3. Verify all CLI compatibility tests pass with new fixtures
4. Remove DOCS/SAMPLES/Bento4-master directory completely

## Priority

Low - tests are currently working with Bento4 fixtures
