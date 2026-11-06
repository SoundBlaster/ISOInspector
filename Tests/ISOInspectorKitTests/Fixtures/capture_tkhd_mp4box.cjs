// Reproduce the reference output with mp4box@2.5.0; see README.md.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const [packageDir, mode] = process.argv.slice(2);
if (!packageDir || !['--write', '--check'].includes(mode)) {
  throw new Error('Usage: node capture_tkhd_mp4box.cjs /path/to/node_modules/mp4box --write|--check');
}
const root = path.resolve(packageDir);
const metadata = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
if (metadata.version !== '2.5.0') throw new Error(`Expected mp4box 2.5.0, got ${metadata.version}`);
const bundle = path.join(root, 'dist', 'mp4box.all.cjs');
const mp4box = require(bundle);
const inputs = JSON.parse(fs.readFileSync(path.join(__dirname, 'tkhd_differential_inputs.json'), 'utf8'));
const output = {
  reference: {
    package: 'mp4box',
    version: metadata.version,
    source: 'https://github.com/gpac/mp4box.js/blob/v2.5.0/src/boxes/tkhd.ts',
    bundleSHA256: crypto.createHash('sha256').update(fs.readFileSync(bundle)).digest('hex'),
  },
  parsed: {},
  notParsed: [],
};
for (const [name, encoded] of Object.entries(inputs)) {
  const bytes = Buffer.from(encoded, 'base64');
  const buffer = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
  buffer.fileStart = 0;
  const file = mp4box.createFile();
  file.appendBuffer(buffer);
  if (file.boxes.length === 0) {
    output.notParsed.push(name);
    continue;
  }
  if (file.boxes.length !== 1 || file.boxes[0].type !== 'tkhd') throw new Error(`Unexpected boxes: ${name}`);
  const box = file.boxes[0];
  output.parsed[name] = {
    version: box.version, flags: box.flags, creationTime: box.creation_time,
    modificationTime: box.modification_time, trackID: box.track_id, duration: box.duration,
    layer: box.layer, alternateGroup: box.alternate_group, volume: box.volume,
    matrix: Array.from(box.matrix, (value, index) => value / (index % 3 === 2 ? 2 ** 30 : 2 ** 16)),
    width: box.width / 2 ** 16, height: box.height / 2 ** 16,
  };
}
const result = JSON.stringify(output, null, 2) + '\n';
const target = path.join(__dirname, 'tkhd_mp4box_2_5_0.json');
if (mode === '--write') fs.writeFileSync(target, result);
else if (fs.readFileSync(target, 'utf8') !== result) throw new Error('MP4Box.js output differs from recorded reference');
console.log(`MP4Box.js reference ${mode === '--write' ? 'written' : 'verified'}`);
