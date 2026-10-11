#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");

const projectRoot = path.resolve(__dirname, "..", "..");
const sourcePath = path.join(
  projectRoot,
  "assets/characters/player/neko_nightfall_character_full/models/neko_nightfall_rigged.glb",
);
const outputPath = path.join(
  projectRoot,
  "assets/characters/player/neko_nightfall_anime_complete/models/neko_nightfall_rigged.glb",
);

function align4(value) {
  return (value + 3) & ~3;
}

function quaternionX(radians) {
  return [Math.sin(radians / 2), 0, 0, Math.cos(radians / 2)];
}

function quaternionZ(radians) {
  return [0, 0, Math.sin(radians / 2), Math.cos(radians / 2)];
}

function parseGlb(bytes) {
  if (bytes.toString("ascii", 0, 4) !== "glTF" || bytes.readUInt32LE(4) !== 2) {
    throw new Error("Input must be a binary glTF 2.0 file.");
  }
  let offset = 12;
  let json = null;
  let binary = null;
  while (offset < bytes.length) {
    const chunkLength = bytes.readUInt32LE(offset);
    const chunkType = bytes.readUInt32LE(offset + 4);
    const chunk = bytes.subarray(offset + 8, offset + 8 + chunkLength);
    if (chunkType === 0x4e4f534a) json = JSON.parse(chunk.toString("utf8").trim());
    else if (chunkType === 0x004e4942) binary = Buffer.from(chunk);
    offset += 8 + chunkLength;
  }
  if (!json || !binary || !json.buffers || json.buffers.length !== 1) {
    throw new Error("GLB must contain one JSON chunk and one embedded binary buffer.");
  }
  return { json, binary };
}

function readAccessor(json, binary, accessorIndex) {
  const accessor = json.accessors[accessorIndex];
  const view = json.bufferViews[accessor.bufferView];
  const components = { SCALAR: 1, VEC2: 2, VEC3: 3, VEC4: 4 }[accessor.type];
  const bytesPerComponent = { 5121: 1, 5123: 2, 5125: 4, 5126: 4 }[accessor.componentType];
  if (!components || !bytesPerComponent || accessor.sparse || view.byteStride) {
    throw new Error(`Unsupported character accessor layout at ${accessorIndex}.`);
  }
  const values = [];
  const start = (view.byteOffset || 0) + (accessor.byteOffset || 0);
  for (let item = 0; item < accessor.count; item += 1) {
    const value = [];
    for (let component = 0; component < components; component += 1) {
      const offset = start + (item * components + component) * bytesPerComponent;
      if (accessor.componentType === 5126) value.push(binary.readFloatLE(offset));
      else if (accessor.componentType === 5123) value.push(binary.readUInt16LE(offset));
      else if (accessor.componentType === 5125) value.push(binary.readUInt32LE(offset));
      else value.push(binary.readUInt8(offset));
    }
    values.push(value);
  }
  return values;
}

function refineSkinnedMeshes(json, binary, appendAccessor) {
  let originalIndices = 0;
  let refinedIndices = 0;
  let originalVertices = 0;
  let refinedVertices = 0;
  for (const mesh of json.meshes || []) {
    for (const primitive of mesh.primitives || []) {
      if (primitive.mode !== undefined && primitive.mode !== 4) continue;
      const positions = readAccessor(json, binary, primitive.attributes.POSITION);
      const indices = primitive.indices === undefined
        ? Array.from({ length: positions.length }, (_, index) => index)
        : readAccessor(json, binary, primitive.indices).flat();
      if (indices.length % 3 !== 0) throw new Error("Only triangle-list character meshes can be refined.");
      const streams = Object.fromEntries(Object.entries(primitive.attributes)
        .map(([semantic, accessor]) => [semantic, readAccessor(json, binary, accessor)]));
      const edgeCache = new Map();
      const outputIndices = [];
      function midpoint(a, b) {
        const first = Math.min(a, b);
        const second = Math.max(a, b);
        const key = `${first}:${second}`;
        if (edgeCache.has(key)) return edgeCache.get(key);
        const index = streams.POSITION.length;
        for (const [semantic, values] of Object.entries(streams)) {
          if (semantic === "JOINTS_0") continue;
          if (semantic === "WEIGHTS_0") {
            const influences = new Map();
            for (const source of [a, b]) {
              for (let slot = 0; slot < 4; slot += 1) {
                const joint = streams.JOINTS_0[source][slot];
                influences.set(joint, (influences.get(joint) || 0) + values[source][slot] * 0.5);
              }
            }
            const best = [...influences.entries()].sort((left, right) => right[1] - left[1]).slice(0, 4);
            const total = best.reduce((sum, influence) => sum + influence[1], 0) || 1;
            streams.JOINTS_0.push([...best.map((influence) => influence[0]), 0, 0, 0, 0].slice(0, 4));
            values.push([...best.map((influence) => influence[1] / total), 0, 0, 0, 0].slice(0, 4));
            continue;
          }
          const value = values[a].map((component, slot) => (component + values[b][slot]) * 0.5);
          if (semantic === "NORMAL") {
            const magnitude = Math.hypot(...value) || 1;
            for (let slot = 0; slot < value.length; slot += 1) value[slot] /= magnitude;
          }
          values.push(value);
        }
        if (streams.JOINTS_0 && !streams.WEIGHTS_0) streams.JOINTS_0.push(streams.JOINTS_0[a].slice());
        edgeCache.set(key, index);
        return index;
      }
      for (let index = 0; index < indices.length; index += 3) {
        const a = indices[index];
        const b = indices[index + 1];
        const c = indices[index + 2];
        const ab = midpoint(a, b);
        const bc = midpoint(b, c);
        const ca = midpoint(c, a);
        outputIndices.push(a, ab, ca, ab, b, bc, ca, bc, c, ab, bc, ca);
      }
      for (const [semantic, values] of Object.entries(streams)) {
        const oldAccessor = json.accessors[primitive.attributes[semantic]];
        primitive.attributes[semantic] = appendAccessor(values.flat(), oldAccessor.type, values[0].length, undefined, undefined, oldAccessor.componentType);
      }
      primitive.indices = appendAccessor(outputIndices, "SCALAR", 1, undefined, undefined, 5125);
      originalVertices += positions.length;
      refinedVertices += streams.POSITION.length;
      originalIndices += indices.length;
      refinedIndices += outputIndices.length;
    }
  }
  if (originalIndices === 0 || refinedIndices !== originalIndices * 4 || refinedVertices <= originalVertices) {
    throw new Error("Mid-poly refinement failed its geometry-density checks.");
  }
  return { originalVertices, refinedVertices, originalIndices, refinedIndices };
}

function createExtendedGlb(inputBytes) {
  const { json, binary: originalBinary } = parseGlb(inputBytes);
  const currentNames = new Set((json.animations || []).map((animation) => animation.name));
  if (currentNames.has("Hit") || currentNames.has("Death")) {
    throw new Error("Refusing to overwrite existing Hit/Death animations.");
  }

  const nodeIndices = new Map((json.nodes || []).map((node, index) => [node.name, index]));
  const requiredBones = ["Root", "Spine", "Chest", "Head", "UpperArm_L", "UpperArm_R", "UpperLeg_L", "UpperLeg_R"];
  for (const name of requiredBones) {
    if (!nodeIndices.has(name)) throw new Error(`Required animation bone is missing: ${name}`);
  }

  const binaryParts = [originalBinary];
  let binaryLength = originalBinary.length;
  function appendAccessor(values, type, components, min, max, componentType = 5126) {
    const byteOffset = align4(binaryLength);
    if (byteOffset > binaryLength) binaryParts.push(Buffer.alloc(byteOffset - binaryLength));
    const componentBytes = { 5121: 1, 5123: 2, 5125: 4, 5126: 4 }[componentType];
    const data = Buffer.alloc(values.length * componentBytes);
    values.forEach((value, index) => {
      if (componentType === 5126) data.writeFloatLE(value, index * componentBytes);
      else if (componentType === 5125) data.writeUInt32LE(value, index * componentBytes);
      else if (componentType === 5123) data.writeUInt16LE(value, index * componentBytes);
      else data.writeUInt8(value, index * componentBytes);
    });
    binaryParts.push(data);
    binaryLength = byteOffset + data.length;

    const bufferView = json.bufferViews.length;
    json.bufferViews.push({ buffer: 0, byteOffset, byteLength: data.length });
    const accessor = json.accessors.length;
    const entry = { bufferView, componentType, count: values.length / components, type };
    if (min) entry.min = min;
    if (max) entry.max = max;
    json.accessors.push(entry);
    return accessor;
  }

  const meshStats = refineSkinnedMeshes(json, originalBinary, appendAccessor);

  function addAnimation(name, times, tracks) {
    const inputAccessor = appendAccessor(times, "SCALAR", 1, [times[0]], [times[times.length - 1]]);
    const animation = { name, samplers: [], channels: [] };
    for (const track of tracks) {
      const node = nodeIndices.get(track.bone);
      if (node === undefined) throw new Error(`Missing animation node: ${track.bone}`);
      const values = track.values.flat();
      const outputAccessor = appendAccessor(values, track.path === "translation" ? "VEC3" : "VEC4", track.path === "translation" ? 3 : 4);
      const sampler = animation.samplers.length;
      animation.samplers.push({ input: inputAccessor, output: outputAccessor, interpolation: "LINEAR" });
      animation.channels.push({ sampler, target: { node, path: track.path } });
    }
    json.animations.push(animation);
  }

  addAnimation("Hit", [0, 0.07, 0.19, 0.36, 0.58], [
    { bone: "Spine", path: "rotation", values: [0, -0.12, -0.24, 0.08, 0].map(quaternionX) },
    { bone: "Chest", path: "rotation", values: [0, -0.19, -0.12, 0.05, 0].map(quaternionX) },
    { bone: "Head", path: "rotation", values: [0, 0.16, 0.1, -0.04, 0].map(quaternionX) },
    { bone: "UpperArm_L", path: "rotation", values: [0, -0.08, -0.14, 0.03, 0].map(quaternionZ) },
    { bone: "UpperArm_R", path: "rotation", values: [0, 0.08, 0.14, -0.03, 0].map(quaternionZ) },
  ]);

  addAnimation("Death", [0, 0.16, 0.42, 0.78, 1.16, 1.65, 2.1], [
    { bone: "Root", path: "translation", values: [[0, 0, 0], [0, 0, 0], [0, -0.03, 0], [0, -0.15, 0], [0, -0.38, 0], [0, -0.66, 0], [0, -0.72, 0]] },
    { bone: "Hips", path: "rotation", values: [0, 0.04, 0.14, 0.42, 0.83, 1.08, 1.08].map(quaternionZ) },
    { bone: "Spine", path: "rotation", values: [0, -0.1, -0.24, -0.48, -0.7, -0.76, -0.76].map(quaternionX) },
    { bone: "Chest", path: "rotation", values: [0, 0.08, 0.2, 0.3, 0.26, 0.24, 0.24].map(quaternionX) },
    { bone: "Head", path: "rotation", values: [0, 0.05, 0.2, 0.4, 0.52, 0.58, 0.58].map(quaternionX) },
    { bone: "UpperArm_L", path: "rotation", values: [0, -0.12, -0.48, -0.82, -1.05, -1.1, -1.1].map(quaternionZ) },
    { bone: "UpperArm_R", path: "rotation", values: [0, 0.1, 0.42, 0.72, 0.92, 0.98, 0.98].map(quaternionZ) },
    { bone: "UpperLeg_L", path: "rotation", values: [0, 0.04, -0.12, -0.38, -0.62, -0.66, -0.66].map(quaternionX) },
    { bone: "UpperLeg_R", path: "rotation", values: [0, -0.04, 0.16, 0.44, 0.7, 0.75, 0.75].map(quaternionX) },
  ]);

  const binary = Buffer.concat(binaryParts);
  json.buffers[0].byteLength = binary.length;
  const jsonChunk = Buffer.from(JSON.stringify(json), "utf8");
  const paddedJsonLength = align4(jsonChunk.length);
  const paddedBinaryLength = align4(binary.length);
  const jsonPadding = Buffer.alloc(paddedJsonLength - jsonChunk.length, 0x20);
  const binaryPadding = Buffer.alloc(paddedBinaryLength - binary.length);
  const totalLength = 12 + 8 + paddedJsonLength + 8 + paddedBinaryLength;
  const header = Buffer.alloc(12);
  header.write("glTF", 0, "ascii");
  header.writeUInt32LE(2, 4);
  header.writeUInt32LE(totalLength, 8);
  const jsonHeader = Buffer.alloc(8);
  jsonHeader.writeUInt32LE(paddedJsonLength, 0);
  jsonHeader.writeUInt32LE(0x4e4f534a, 4);
  const binaryHeader = Buffer.alloc(8);
  binaryHeader.writeUInt32LE(paddedBinaryLength, 0);
  binaryHeader.writeUInt32LE(0x004e4942, 4);
  return Buffer.concat([header, jsonHeader, jsonChunk, jsonPadding, binaryHeader, binary, binaryPadding]);
}

function main() {
  const mode = process.argv[2];
  if (mode !== "--generate" && mode !== "--verify") {
    throw new Error("Usage: node tools/characters/extend_neko_animations.js --generate|--verify");
  }
  const generated = createExtendedGlb(fs.readFileSync(sourcePath));
  if (mode === "--generate") {
    fs.writeFileSync(outputPath, generated);
    console.log(`Wrote ${path.relative(projectRoot, outputPath)} (${generated.length} bytes).`);
    return;
  }
  const committed = fs.readFileSync(outputPath);
  if (!generated.equals(committed)) throw new Error("Committed character GLB differs from deterministic generated output.");
  console.log("Character GLB matches deterministic source generation.");
}

main();
