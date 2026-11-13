/**
 * TeroVPN Chrome Extension - Pure JS QR Code Generator (SVG)
 * Supports Byte-mode UTF-8 strings (Versions 1-14, EC Level M)
 * Zero external dependencies, Manifest V3 CSP-compliant.
 */

const EXP_TABLE = new Array(256);
const LOG_TABLE = new Array(256);
for (let i = 0; i < 8; i++) EXP_TABLE[i] = 1 << i;
for (let i = 8; i < 256; i++) {
  EXP_TABLE[i] = EXP_TABLE[i - 4] ^ EXP_TABLE[i - 5] ^ EXP_TABLE[i - 6] ^ EXP_TABLE[i - 8];
}
for (let i = 0; i < 255; i++) LOG_TABLE[EXP_TABLE[i]] = i;

function glog(n) {
  if (n < 1) throw new Error('glog(' + n + ')');
  return LOG_TABLE[n];
}
function gexp(n) {
  while (n < 0) n += 255;
  while (n >= 256) n -= 255;
  return EXP_TABLE[n];
}

function polyMul(a, b) {
  const num = new Array(a.length + b.length - 1).fill(0);
  for (let i = 0; i < a.length; i++) {
    for (let j = 0; j < b.length; j++) {
      num[i + j] ^= gexp(glog(a[i]) + glog(b[j]));
    }
  }
  return num;
}

function polyMod(a, b) {
  if (a.length - b.length < 0) return a;
  const ratio = glog(a[0]) - glog(b[0]);
  const num = a.slice();
  for (let i = 0; i < b.length; i++) {
    num[i] ^= gexp(glog(b[i]) + ratio);
  }
  let shift = 0;
  while (shift < num.length && num[shift] === 0) shift++;
  return polyMod(num.slice(shift), b);
}

function getErrorCorrectPolynomial(ecLength) {
  let a = [1];
  for (let i = 0; i < ecLength; i++) {
    a = polyMul(a, [1, gexp(i)]);
  }
  return a;
}

// RS block table for EC Level M (versions 1..14)
// Format: [totalCount, dataCount] or [[count, totalCount, dataCount], ...]
const RS_BLOCKS_M = {
  1: [[1, 26, 16]],
  2: [[1, 44, 28]],
  3: [[1, 70, 44]],
  4: [[2, 50, 32]],
  5: [[2, 67, 43]],
  6: [[4, 43, 27]],
  7: [[4, 49, 31]],
  8: [[2, 60, 38], [2, 61, 39]],
  9: [[3, 58, 36], [2, 59, 37]],
  10: [[4, 69, 43], [1, 70, 44]],
  11: [[1, 80, 50], [4, 81, 51]],
  12: [[6, 58, 36], [2, 59, 37]],
  13: [[8, 59, 37], [1, 60, 38]],
  14: [[4, 64, 40], [5, 65, 41]]
};

const ALIGNMENT_PATTERNS = {
  1: [],
  2: [6, 18],
  3: [6, 22],
  4: [6, 26],
  5: [6, 30],
  6: [6, 34],
  7: [6, 22, 38],
  8: [6, 24, 42],
  9: [6, 26, 46],
  10: [6, 28, 50],
  11: [6, 30, 54],
  12: [6, 32, 58],
  13: [6, 34, 62],
  14: [6, 26, 46, 66]
};

function getBCHDigit(data) {
  let digit = 0;
  while (data !== 0) {
    digit++;
    data >>>= 1;
  }
  return digit;
}

const G15 = (1 << 10) | (1 << 8) | (1 << 5) | (1 << 4) | (1 << 2) | (1 << 1) | (1 << 0);
const G15_MASK = (1 << 14) | (1 << 12) | (1 << 10) | (1 << 4) | (1 << 1);
function getBCHTypeInfo(data) {
  let d = data << 10;
  while (getBCHDigit(d) - getBCHDigit(G15) >= 0) {
    d ^= G15 << (getBCHDigit(d) - getBCHDigit(G15));
  }
  return ((data << 10) | d) ^ G15_MASK;
}

const G18 = (1 << 12) | (1 << 11) | (1 << 10) | (1 << 9) | (1 << 8) | (1 << 5) | (1 << 2) | (1 << 0);
function getBCHTypeNumber(data) {
  let d = data << 12;
  while (getBCHDigit(d) - getBCHDigit(G18) >= 0) {
    d ^= G18 << (getBCHDigit(d) - getBCHDigit(G18));
  }
  return (data << 12) | d;
}

function getMask(maskPattern, i, j) {
  switch (maskPattern) {
    case 0: return (i + j) % 2 === 0;
    case 1: return i % 2 === 0;
    case 2: return j % 3 === 0;
    case 3: return (i + j) % 3 === 0;
    case 4: return (Math.floor(i / 2) + Math.floor(j / 3)) % 2 === 0;
    case 5: return ((i * j) % 2) + ((i * j) % 3) === 0;
    case 6: return (((i * j) % 2) + ((i * j) % 3)) % 2 === 0;
    case 7: return (((i * j) % 3) + ((i + j) % 2)) % 2 === 0;
    default: throw new Error('bad maskPattern:' + maskPattern);
  }
}

function chooseVersion(byteLen) {
  for (let v = 1; v <= 14; v++) {
    const blocks = RS_BLOCKS_M[v];
    let totalDataBytes = 0;
    for (const [count, , dataCount] of blocks) {
      totalDataBytes += count * dataCount;
    }
    const headerBits = 4 + (v >= 10 ? 16 : 8);
    if (headerBits + byteLen * 8 <= totalDataBytes * 8) {
      return v;
    }
  }
  throw new Error('Data too long for QR Code (max version 14)');
}

function encodeData(bytes, version) {
  const blocksSpec = RS_BLOCKS_M[version];
  const rsBlocks = [];
  let totalDataCount = 0;
  for (const [count, totalCount, dataCount] of blocksSpec) {
    for (let i = 0; i < count; i++) {
      rsBlocks.push({ totalCount, dataCount });
      totalDataCount += dataCount;
    }
  }

  const buffer = [];
  let currentByte = 0;
  let bitCount = 0;

  function put(num, length) {
    for (let i = 0; i < length; i++) {
      const bit = ((num >>> (length - i - 1)) & 1) === 1;
      currentByte = (currentByte << 1) | (bit ? 1 : 0);
      bitCount++;
      if (bitCount === 8) {
        buffer.push(currentByte);
        currentByte = 0;
        bitCount = 0;
      }
    }
  }

  // Mode: 8-bit byte (0100)
  put(4, 4);
  put(bytes.length, version >= 10 ? 16 : 8);
  for (const b of bytes) put(b, 8);

  // Terminator
  if (buffer.length * 8 + bitCount + 4 <= totalDataCount * 8) {
    put(0, 4);
  }
  while (bitCount > 0) put(0, 1);

  // Pad bytes
  let padToggle = true;
  while (buffer.length < totalDataCount) {
    buffer.push(padToggle ? 0xEC : 0x11);
    padToggle = !padToggle;
  }

  // Error correction & interleaving
  let offset = 0;
  let maxDcCount = 0;
  let maxEcCount = 0;
  const dcdata = [];
  const ecdata = [];

  for (let r = 0; r < rsBlocks.length; r++) {
    const dcCount = rsBlocks[r].dataCount;
    const ecCount = rsBlocks[r].totalCount - dcCount;
    maxDcCount = Math.max(maxDcCount, dcCount);
    maxEcCount = Math.max(maxEcCount, ecCount);

    const dc = buffer.slice(offset, offset + dcCount);
    offset += dcCount;
    dcdata.push(dc);

    const rsPoly = getErrorCorrectPolynomial(ecCount);
    const rawPoly = dc.concat(new Array(rsPoly.length - 1).fill(0));
    const modPoly = polyMod(rawPoly, rsPoly);
    const ec = new Array(rsPoly.length - 1).fill(0);
    for (let i = 0; i < ec.length; i++) {
      const modIndex = i + modPoly.length - ec.length;
      ec[i] = modIndex >= 0 ? modPoly[modIndex] : 0;
    }
    ecdata.push(ec);
  }

  const out = [];
  for (let i = 0; i < maxDcCount; i++) {
    for (let r = 0; r < rsBlocks.length; r++) {
      if (i < dcdata[r].length) out.push(dcdata[r][i]);
    }
  }
  for (let i = 0; i < maxEcCount; i++) {
    for (let r = 0; r < rsBlocks.length; r++) {
      if (i < ecdata[r].length) out.push(ecdata[r][i]);
    }
  }
  return out;
}

function buildMatrix(dataBytes, version, maskPattern) {
  const moduleCount = version * 4 + 17;
  const modules = Array.from({ length: moduleCount }, () => new Array(moduleCount).fill(null));

  function setupPositionProbePattern(row, col) {
    for (let r = -1; r <= 7; r++) {
      if (row + r <= -1 || moduleCount <= row + r) continue;
      for (let c = -1; c <= 7; c++) {
        if (col + c <= -1 || moduleCount <= col + c) continue;
        if (
          (0 <= r && r <= 6 && (c === 0 || c === 6)) ||
          (0 <= c && c <= 6 && (r === 0 || r === 6)) ||
          (2 <= r && r <= 4 && 2 <= c && c <= 4)
        ) {
          modules[row + r][col + c] = true;
        } else {
          modules[row + r][col + c] = false;
        }
      }
    }
  }

  function setupPositionAdjustPattern() {
    const pos = ALIGNMENT_PATTERNS[version] || [];
    for (let i = 0; i < pos.length; i++) {
      for (let j = 0; j < pos.length; j++) {
        const row = pos[i];
        const col = pos[j];
        if (modules[row][col] !== null) continue;
        for (let r = -2; r <= 2; r++) {
          for (let c = -2; c <= 2; c++) {
            modules[row + r][col + c] =
              r === -2 || r === 2 || c === -2 || c === 2 || (r === 0 && c === 0);
          }
        }
      }
    }
  }

  function setupTimingPattern() {
    for (let r = 8; r < moduleCount - 8; r++) {
      if (modules[r][6] === null) modules[r][6] = r % 2 === 0;
    }
    for (let c = 8; c < moduleCount - 8; c++) {
      if (modules[6][c] === null) modules[6][c] = c % 2 === 0;
    }
  }

  function setupTypeInfo(maskPat) {
    // EC Level M = 0 (00 in QR format bits: L=01, M=00, Q=11, H=10)
    const data = (0 << 3) | maskPat;
    const bits = getBCHTypeInfo(data);
    for (let i = 0; i < 15; i++) {
      const mod = ((bits >>> i) & 1) === 1;
      if (i < 6) modules[i][8] = mod;
      else if (i < 8) modules[i + 1][8] = mod;
      else modules[moduleCount - 15 + i][8] = mod;

      if (i < 8) modules[8][moduleCount - i - 1] = mod;
      else if (i < 9) modules[8][15 - i - 1 + 1] = mod;
      else modules[8][15 - i - 1] = mod;
    }
    modules[moduleCount - 8][8] = true;
  }

  function setupTypeNumber() {
    if (version < 7) return;
    const bits = getBCHTypeNumber(version);
    for (let i = 0; i < 18; i++) {
      const mod = ((bits >>> i) & 1) === 1;
      modules[Math.floor(i / 3)][(i % 3) + moduleCount - 8 - 3] = mod;
      modules[(i % 3) + moduleCount - 8 - 3][Math.floor(i / 3)] = mod;
    }
  }

  setupPositionProbePattern(0, 0);
  setupPositionProbePattern(moduleCount - 7, 0);
  setupPositionProbePattern(0, moduleCount - 7);
  setupPositionAdjustPattern();
  setupTimingPattern();
  setupTypeInfo(maskPattern);
  setupTypeNumber();

  let inc = -1;
  let row = moduleCount - 1;
  let bitIndex = 7;
  let byteIndex = 0;

  for (let col = moduleCount - 1; col > 0; col -= 2) {
    if (col === 6) col--;
    while (true) {
      for (let c = 0; c < 2; c++) {
        if (modules[row][col - c] === null) {
          let dark = false;
          if (byteIndex < dataBytes.length) {
            dark = ((dataBytes[byteIndex] >>> bitIndex) & 1) === 1;
          }
          if (getMask(maskPattern, row, col - c)) dark = !dark;
          modules[row][col - c] = dark;
          bitIndex--;
          if (bitIndex === -1) {
            byteIndex++;
            bitIndex = 7;
          }
        }
      }
      row += inc;
      if (row < 0 || moduleCount <= row) {
        row -= inc;
        inc = -inc;
        break;
      }
    }
  }
  return modules;
}

function calcPenalty(modules) {
  const n = modules.length;
  let lostPoint = 0;
  for (let row = 0; row < n; row++) {
    for (let col = 0; col < n; col++) {
      let sameCount = 0;
      const dark = modules[row][col];
      for (let r = -1; r <= 1; r++) {
        if (row + r < 0 || n <= row + r) continue;
        for (let c = -1; c <= 1; c++) {
          if (col + c < 0 || n <= col + c) continue;
          if (r === 0 && c === 0) continue;
          if (dark === modules[row + r][col + c]) sameCount++;
        }
      }
      if (sameCount > 5) lostPoint += 3 + sameCount - 5;
    }
  }
  for (let row = 0; row < n - 1; row++) {
    for (let col = 0; col < n - 1; col++) {
      let count = 0;
      if (modules[row][col]) count++;
      if (modules[row + 1][col]) count++;
      if (modules[row][col + 1]) count++;
      if (modules[row + 1][col + 1]) count++;
      if (count === 0 || count === 4) lostPoint += 3;
    }
  }
  let darkCount = 0;
  for (let row = 0; row < n; row++) {
    for (let col = 0; col < n; col++) {
      if (modules[row][col]) darkCount++;
    }
  }
  const ratio = Math.abs((100 * darkCount) / n / n - 50) / 5;
  lostPoint += ratio * 10;
  return lostPoint;
}

export function generateQrMatrix(text) {
  const bytes = Array.from(new TextEncoder().encode(text));
  const version = chooseVersion(bytes.length);
  const dataBytes = encodeData(bytes, version);

  let bestPattern = 0;
  let minLostPoint = Infinity;
  let bestModules = null;

  for (let p = 0; p < 8; p++) {
    const m = buildMatrix(dataBytes, version, p);
    const lost = calcPenalty(m);
    if (lost < minLostPoint) {
      minLostPoint = lost;
      bestPattern = p;
      bestModules = m;
    }
  }
  return bestModules;
}

export function renderQrSvg(text, size = 180) {
  const modules = generateQrMatrix(text);
  const count = modules.length;
  const quiet = 2;
  const total = count + quiet * 2;
  let rects = '';
  for (let r = 0; r < count; r++) {
    for (let c = 0; c < count; c++) {
      if (modules[r][c]) {
        rects += `<rect x="${c + quiet}" y="${r + quiet}" width="1" height="1" fill="#0B0D14"/>`;
      }
    }
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${total} ${total}" width="${size}" height="${size}" shape-rendering="crispEdges"><rect width="${total}" height="${total}" fill="#FFFFFF" rx="4"/>${rects}</svg>`;
}
