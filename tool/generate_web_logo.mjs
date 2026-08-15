import { createHash } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { deflateSync } from "node:zlib";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const webDir = join(root, "web");
const iconsDir = join(webDir, "icons");

const COLORS = {
  ".": [0x3d, 0x24, 0x65, 0xff], // purple background
  "#": [0xf1, 0xfa, 0xee, 0xff], // cart body + wheels
};

// 16x16 side-view cart: basket, grid, handle, two wheels.
const SPRITE = [
  "................",
  "..........####..",
  "..........#..#..",
  ".##########..#..",
  ".#........#..#..",
  ".#.######.#..#..",
  ".#.#....#.#..#..",
  ".#.#....#.#..#..",
  ".#.######.#..#..",
  ".#........#..#..",
  ".##########..#..",
  "..#......#......",
  ".###....###.....",
  ".#.#....#.#.....",
  ".###....###.....",
  "................",
];

const SIZE = SPRITE.length;

function crc32(buf) {
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    crc ^= buf[i];
    for (let j = 0; j < 8; j++) {
      crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const typeBuf = Buffer.from(type, "ascii");
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const crcBuf = Buffer.alloc(4);
  crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])));
  return Buffer.concat([len, typeBuf, data, crcBuf]);
}

function encodePng(width, height, rgba) {
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0;
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk("IHDR", ihdr),
    chunk("IDAT", deflateSync(raw, { level: 9 })),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

function spriteRgba({ transparentBg = false } = {}) {
  const data = Buffer.alloc(SIZE * SIZE * 4);
  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      const ch = SPRITE[y][x];
      const color =
        ch === "." && transparentBg ? [0, 0, 0, 0] : COLORS[ch] ?? COLORS["."];
      const i = (y * SIZE + x) * 4;
      data[i] = color[0];
      data[i + 1] = color[1];
      data[i + 2] = color[2];
      data[i + 3] = color[3];
    }
  }
  return data;
}

function scaleNearest(src, sw, sh, scale) {
  const dw = sw * scale;
  const dh = sh * scale;
  const dst = Buffer.alloc(dw * dh * 4);
  for (let y = 0; y < dh; y++) {
    for (let x = 0; x < dw; x++) {
      const si = (Math.floor(y / scale) * sw + Math.floor(x / scale)) * 4;
      src.copy(dst, (y * dw + x) * 4, si, si + 4);
    }
  }
  return { width: dw, height: dh, data: dst };
}

function padToSquare(src, sw, sh, canvas, rgba = COLORS["."]) {
  const dst = Buffer.alloc(canvas * canvas * 4);
  for (let i = 0; i < canvas * canvas; i++) {
    dst[i * 4] = rgba[0];
    dst[i * 4 + 1] = rgba[1];
    dst[i * 4 + 2] = rgba[2];
    dst[i * 4 + 3] = rgba[3];
  }
  const ox = Math.floor((canvas - sw) / 2);
  const oy = Math.floor((canvas - sh) / 2);
  for (let y = 0; y < sh; y++) {
    for (let x = 0; x < sw; x++) {
      src.copy(dst, ((oy + y) * canvas + (ox + x)) * 4, (y * sw + x) * 4, (y * sw + x) * 4 + 4);
    }
  }
  return { width: canvas, height: canvas, data: dst };
}

function writePng(path, image) {
  writeFileSync(path, encodePng(image.width, image.height, image.data));
}

function encodeIco(pngs) {
  const count = pngs.length;
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(count, 4);
  const entries = Buffer.alloc(16 * count);
  const blobs = [];
  let offset = 6 + 16 * count;
  pngs.forEach((png, i) => {
    const size = png.length;
    const o = i * 16;
    const dim = [16, 32, 48][i] ?? 0;
    entries[o] = dim === 256 ? 0 : dim;
    entries[o + 1] = dim === 256 ? 0 : dim;
    entries.writeUInt16LE(1, o + 4);
    entries.writeUInt16LE(32, o + 6);
    entries.writeUInt32LE(size, o + 8);
    entries.writeUInt32LE(offset, o + 12);
    blobs.push(png);
    offset += size;
  });
  return Buffer.concat([header, entries, ...blobs]);
}

function svgFromSprite({ transparentBg = false, silhouette = false } = {}) {
  const bg = COLORS["."];
  const cart = COLORS["#"];
  const hex = (c) =>
    `#${c
      .slice(0, 3)
      .map((n) => n.toString(16).padStart(2, "0"))
      .join("")}`;
  const rects = [];
  if (!transparentBg && !silhouette) {
    rects.push(`  <rect width="${SIZE}" height="${SIZE}" fill="${hex(bg)}"/>`);
  }
  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      const ch = SPRITE[y][x];
      if (ch === ".") continue;
      const fill = silhouette ? "#000000" : hex(cart);
      rects.push(`  <rect x="${x}" y="${y}" width="1" height="1" fill="${fill}"/>`);
    }
  }
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${SIZE} ${SIZE}" width="${SIZE}" height="${SIZE}" shape-rendering="crispEdges">
${rects.join("\n")}
</svg>
`;
}

mkdirSync(iconsDir, { recursive: true });

const sprite = spriteRgba();
const mark = spriteRgba({ transparentBg: true });

const scaled = (scale, src = sprite) => scaleNearest(src, SIZE, SIZE, scale);

writePng(join(iconsDir, "favicon-16x16.png"), { width: SIZE, height: SIZE, data: sprite });
writePng(join(iconsDir, "favicon-32x32.png"), scaled(2));
writePng(join(webDir, "favicon.png"), scaled(2));
writePng(join(iconsDir, "Icon-192.png"), scaled(12));
writePng(join(iconsDir, "Icon-512.png"), scaled(32));

const apple = padToSquare(scaled(11).data, SIZE * 11, SIZE * 11, 180);
writePng(join(iconsDir, "apple-touch-icon.png"), apple);

const maskable192 = padToSquare(scaled(10).data, SIZE * 10, SIZE * 10, 192);
const maskable512 = padToSquare(scaled(24).data, SIZE * 24, SIZE * 24, 512);
writePng(join(iconsDir, "Icon-maskable-192.png"), maskable192);
writePng(join(iconsDir, "Icon-maskable-512.png"), maskable512);

writePng(join(iconsDir, "logo-mark.png"), scaled(32, mark));

const ico = encodeIco([
  encodePng(SIZE, SIZE, sprite),
  encodePng(SIZE * 2, SIZE * 2, scaled(2).data),
  encodePng(SIZE * 3, SIZE * 3, scaled(3).data),
]);
writeFileSync(join(webDir, "favicon.ico"), ico);

writeFileSync(join(iconsDir, "logo.svg"), svgFromSprite());
writeFileSync(join(iconsDir, "logo-mark.svg"), svgFromSprite({ transparentBg: true }));
writeFileSync(join(iconsDir, "safari-pinned-tab.svg"), svgFromSprite({ transparentBg: true, silhouette: true }));

const hash = createHash("sha256").update(sprite).digest("hex").slice(0, 8);
console.log(`Wrote grocery cart logo package (${hash})`);
