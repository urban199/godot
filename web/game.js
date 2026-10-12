import * as THREE from 'three';

// The map is deliberately authored as a fixed set of room and prop placements.
// No layout, loot or tree positions are randomized at runtime.
const $ = (id) => document.getElementById(id);
const ui = {
  start: $('start-screen'), pause: $('pause-screen'), settings: $('settings-screen'),
  note: $('note-screen'), ending: $('end-screen'), hud: $('hud'), loading: $('loading'),
  objective: $('objective'), prompt: $('prompt'), toast: $('toast'),
};
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x10191c);
scene.fog = new THREE.FogExp2(0x10191c, 0.027);
const camera = new THREE.PerspectiveCamera(74, innerWidth / innerHeight, 0.08, 95);
camera.rotation.order = 'YXZ';
const renderer = new THREE.WebGLRenderer({ canvas: $('world'), antialias: true, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(devicePixelRatio || 1, 1.5));
renderer.setSize(innerWidth, innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 0.88;

const mats = {};
function mat(name, color, roughness = 0.86, metalness = 0, extra = {}) {
  if (!mats[name]) mats[name] = new THREE.MeshStandardMaterial({ color, roughness, metalness, ...extra });
  return mats[name];
}
mats.concrete = mat('concrete', 0x394144, 0.94);
mats.concreteDark = mat('concreteDark', 0x222c2f, 0.96);
mats.floor = mat('floor', 0x192427, 0.36, 0.12);
mats.mud = mat('mud', 0x171c18, 0.98);
mats.rust = mat('rust', 0x684334, 0.78, 0.34);
mats.metal = mat('metal', 0x303b3e, 0.54, 0.66);
mats.glass = mat('glass', 0x6d9b9b, 0.25, 0.18, { transparent: true, opacity: 0.32 });
mats.leaf = mat('leaf', 0x142b25, 0.95);
mats.leaf2 = mat('leaf2', 0x20392c, 1);
mats.bark = mat('bark', 0x302720, 0.98);
mats.dirtyWhite = mat('dirtyWhite', 0x9ba096, 0.81);
mats.red = mat('red', 0x8f302a, 0.52, 0.15, { emissive: 0x260704 });
mats.screen = mat('screen', 0x4a9a91, 0.35, 0.05, { emissive: 0x123e38, emissiveIntensity: 1.1 });
mats.creature = mat('creature', 0x100f13, 0.72, 0.08);
mats.eye = mat('eye', 0xe4372e, 0.28, 0.1, { emissive: 0x8f0805, emissiveIntensity: 1.5 });
mats.asphalt = mat('asphalt', 0x20272a, 0.95, 0.04);
mats.sidewalk = mat('sidewalk', 0x555957, 0.92);
mats.brick = mat('brick', 0x494342, 0.93);
mats.plaster = mat('plaster', 0x666863, 0.91);
mats.sandstone = mat('sandstone', 0x686457, 0.88);
mats.cityGlass = mat('cityGlass', 0x243b42, 0.3, 0.18, { emissive: 0x101c20, emissiveIntensity: 0.45 });
mats.litWindow = mat('litWindow', 0xc28b4b, 0.38, 0, { emissive: 0x6d3c17, emissiveIntensity: 0.55 });
mats.whitePaint = mat('whitePaint', 0xa7a696, 0.7);
mats.tire = mat('tire', 0x101314, 0.91);
mats.wood = mat('wood', 0x46382c, 0.82);
mats.tile = mat('tile', 0x3d4644, 0.7);
mats.fabric = mat('fabric', 0x373b39, 0.97);
mats.paper = mat('paper', 0xb5aa8f, 0.93);

function addSurfaceTexture(material, seed, pattern = 'grain') {
  const size = 256;
  const canvas = document.createElement('canvas'); canvas.width = size; canvas.height = size;
  const context = canvas.getContext('2d', { willReadFrequently: true });
  const image = context.createImageData(size, size);
  let state = seed >>> 0;
  const noise = () => { state = (state * 1664525 + 1013904223) >>> 0; return state / 0x100000000; };
  for (let py = 0; py < size; py++) for (let px = 0; px < size; px++) {
    const seam = pattern === 'brick' && (py % 32 < 3 || ((Math.floor(py / 32) % 2 === 0 ? px : px + 32) % 64 < 3));
    const grain = (noise() - 0.5) * (pattern === 'metal' ? 22 : 38);
    const wetStain = Math.sin(px * 0.039 + Math.cos(py * 0.052)) * 4 + Math.sin(py * 0.11) * 2;
    const value = Math.max(0, Math.min(255, (seam ? 58 : 128) + grain + wetStain));
    const i = (py * size + px) * 4;
    image.data[i] = value; image.data[i + 1] = value; image.data[i + 2] = value; image.data[i + 3] = 255;
  }
  context.putImageData(image, 0, 0);
  const texture = new THREE.CanvasTexture(canvas);
  texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
  texture.repeat.set(pattern === 'brick' ? 3 : 4, pattern === 'wood' ? 2 : 3);
  texture.colorSpace = THREE.SRGBColorSpace; texture.anisotropy = Math.min(8, renderer.capabilities.getMaxAnisotropy());
  const bump = new THREE.CanvasTexture(canvas);
  bump.wrapS = bump.wrapT = THREE.RepeatWrapping; bump.repeat.copy(texture.repeat);
  bump.anisotropy = texture.anisotropy;
  material.map = texture; material.bumpMap = bump; material.bumpScale = pattern === 'metal' ? 0.025 : 0.065; material.needsUpdate = true;
}
addSurfaceTexture(mats.concrete, 1441);
addSurfaceTexture(mats.concreteDark, 2017);
addSurfaceTexture(mats.floor, 701, 'tile');
addSurfaceTexture(mats.mud, 882, 'grain');
addSurfaceTexture(mats.rust, 991, 'metal');
addSurfaceTexture(mats.metal, 613, 'metal');
addSurfaceTexture(mats.asphalt, 3251);
addSurfaceTexture(mats.sidewalk, 842, 'tile');
addSurfaceTexture(mats.brick, 551, 'brick');
addSurfaceTexture(mats.plaster, 2281);
addSurfaceTexture(mats.sandstone, 673, 'grain');
addSurfaceTexture(mats.wood, 884, 'wood');
addSurfaceTexture(mats.tile, 183, 'tile');
addSurfaceTexture(mats.fabric, 352, 'grain');

const hemi = new THREE.HemisphereLight(0x8b9a9c, 0x101614, 0.54);
scene.add(hemi);
const moon = new THREE.DirectionalLight(0x718b9a, 0.7);
moon.position.set(-16, 28, 11); moon.castShadow = true;
moon.shadow.mapSize.set(1024, 1024);
moon.shadow.camera.left = -30; moon.shadow.camera.right = 30;
moon.shadow.camera.top = 30; moon.shadow.camera.bottom = -36;
scene.add(moon);

const solids = [];
const doors = new Map();
const interactables = [];
const lamps = [];
const rainCount = { low: 250, medium: 620, high: 1100 };
const rainPositions = new Float32Array(rainCount.high * 3);
const rainGeometry = new THREE.BufferGeometry();
rainGeometry.setAttribute('position', new THREE.BufferAttribute(rainPositions, 3));
for (let i = 0; i < rainCount.high; i++) {
  rainPositions[i * 3] = ((i * 37) % 560) / 10 - 28;
  rainPositions[i * 3 + 1] = (i * 29) % 160 / 10 + 1;
  rainPositions[i * 3 + 2] = ((i * 53) % 650) / 10 - 34;
}
const rain = new THREE.Points(rainGeometry, new THREE.PointsMaterial({ color: 0x9bacb3, size: 0.035, transparent: true, opacity: 0.48, sizeAttenuation: true }));
scene.add(rain);

function box(name, x, y, z, w, h, d, material, { solid = true, cast = true, receive = true, parent = scene } = {}) {
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
  mesh.name = name; mesh.position.set(x, y, z); mesh.castShadow = cast; mesh.receiveShadow = receive;
  parent.add(mesh);
  if (solid) solids.push({ minX: x - w / 2, maxX: x + w / 2, minZ: z - d / 2, maxZ: z + d / 2, minY: y - h / 2, maxY: y + h / 2, mesh });
  return mesh;
}
function cylinder(name, x, y, z, radiusTop, radiusBottom, height, material, segments = 10, parent = scene) {
  const mesh = new THREE.Mesh(new THREE.CylinderGeometry(radiusTop, radiusBottom, height, segments), material);
  mesh.name = name; mesh.position.set(x, y, z); mesh.castShadow = true; mesh.receiveShadow = true; parent.add(mesh); return mesh;
}
function addLight(name, color, intensity, range, x, y, z, target = null) {
  const light = new THREE.PointLight(color, intensity, range, 1.7);
  light.name = name; light.position.set(x, y, z); light.castShadow = false; scene.add(light); lamps.push(light);
  if (target) { const aim = new THREE.Object3D(); aim.position.set(...target); scene.add(aim); }
  return light;
}
function sign(text, x, y, z, rotation = 0) {
  const canvas = document.createElement('canvas'); canvas.width = 512; canvas.height = 96;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#172023'; ctx.fillRect(0, 0, 512, 96);
  ctx.fillStyle = '#aab1a7'; ctx.font = '600 29px monospace'; ctx.fillText(text, 18, 59);
  const texture = new THREE.CanvasTexture(canvas); texture.colorSpace = THREE.SRGBColorSpace;
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(3.5, 0.66), new THREE.MeshBasicMaterial({ map: texture, side: THREE.DoubleSide }));
  mesh.position.set(x, y, z); mesh.rotation.y = rotation; scene.add(mesh); return mesh;
}
function makeTree(name, x, z, scale = 1) {
  const trunkHeight = 4.7 * scale;
  cylinder(`${name} trunk`, x, trunkHeight / 2, z, 0.2 * scale, 0.48 * scale, trunkHeight, mats.bark, 9);
  const crown = new THREE.Group(); crown.name = `${name} crown`; crown.position.set(x, trunkHeight * 0.75, z); scene.add(crown);
  const bough1 = cylinder(`${name} bough A`, 0, 0, 0, 0.04 * scale, 0.13 * scale, 2.1 * scale, mats.bark, 7, crown);
  bough1.position.set(-0.65 * scale, 0.35 * scale, 0); bough1.rotation.z = 0.68;
  const bough2 = cylinder(`${name} bough B`, 0, 0, 0, 0.035 * scale, 0.12 * scale, 2.0 * scale, mats.bark, 7, crown);
  bough2.position.set(0.65 * scale, 0.2 * scale, 0.2 * scale); bough2.rotation.z = -0.66;
  for (const [px, py, pz, sx, sy, sz, material] of [
    [0, 0.85, 0, 1.35, 1.55, 1.2, mats.leaf], [-0.9, 0.4, 0.1, 1.1, 1.1, 1.1, mats.leaf2], [0.8, 0.48, 0.3, 1.2, 1.15, 1.2, mats.leaf], [0.05, 1.65, 0.08, 0.95, 1.0, 1.0, mats.leaf2],
  ]) {
    const cloud = new THREE.Mesh(new THREE.IcosahedronGeometry(0.84 * scale, 1), material);
    cloud.position.set(px * scale, py * scale, pz * scale); cloud.scale.set(sx, sy, sz); cloud.castShadow = true; crown.add(cloud);
  }
  solids.push({ minX: x - 0.35 * scale, maxX: x + 0.35 * scale, minZ: z - 0.35 * scale, maxZ: z + 0.35 * scale, minY: 0, maxY: trunkHeight, mesh: null });
}
function roomShell(name, cx, cz, w, d, openings = []) {
  const wall = 0.42, h = 3.6;
  box(`${name} floor`, cx, -0.12, cz, w, 0.24, d, mats.floor, { solid: true });
  box(`${name} ceiling`, cx, h, cz, w, 0.3, d, mats.concreteDark, { solid: false });
  const putWall = (side, length, along, centerX, centerZ) => box(`${name} ${side} wall`, centerX, h / 2, centerZ, side.includes('side') ? wall : length, h, side.includes('side') ? length : wall, mats.concrete);
  const openOnZ = (z, sideName) => {
    const door = openings.find((o) => o.side === sideName);
    if (!door) { putWall(sideName, w, 0, cx, z); return; }
    const gap = door.width;
    const sideLength = (w - gap) / 2;
    putWall(`${sideName} left`, sideLength, 0, cx - (gap + sideLength) / 2, z);
    putWall(`${sideName} right`, sideLength, 0, cx + (gap + sideLength) / 2, z);
    box(`${name} ${sideName} lintel`, cx, h - 0.42, z, gap, 0.84, wall, mats.concrete);
  };
  openOnZ(cz + d / 2, 'south'); openOnZ(cz - d / 2, 'north');
  for (const [side, x] of [['west', cx - w / 2], ['east', cx + w / 2]]) {
    const door = openings.find((o) => o.side === side);
    if (!door) putWall(`${side} side`, d, 0, x, cz);
    else {
      const gap = door.width, openingZ = door.z ?? cz;
      const negativeSegment = Math.max(0, openingZ - gap / 2 - (cz - d / 2));
      const positiveSegment = Math.max(0, (cz + d / 2) - (openingZ + gap / 2));
      if (negativeSegment > 0.02) box(`${name} ${side} rear`, x, h / 2, cz - d / 2 + negativeSegment / 2, wall, h, negativeSegment, mats.concrete);
      if (positiveSegment > 0.02) box(`${name} ${side} fore`, x, h / 2, openingZ + gap / 2 + positiveSegment / 2, wall, h, positiveSegment, mats.concrete);
      box(`${name} ${side} lintel`, x, h - 0.42, openingZ, wall, 0.84, gap, mats.concrete);
    }
  }
}

// Exterior approach: tree line, wet road, culvert, fence and numbered gate.
box('Forest floor', 0, -0.58, -6, 70, 0.48, 78, mats.mud);
box('Entry road', 0, -0.3, 2, 8.6, 0.12, 50, mats.floor, { solid: false });
for (const [n, x, z, s] of [
  ['Pine 01', -12, 15, 1.12], ['Pine 02', -19, 8, 1.28], ['Pine 03', -27, 18, 1.08], ['Pine 04', -31, 3, 1.22], ['Pine 05', -24, -8, 0.94], ['Pine 06', -16, -13, 1.14],
  ['Pine 07', 12, 17, 1.18], ['Pine 08', 19, 11, 1.0], ['Pine 09', 28, 17, 1.3], ['Pine 10', 33, 4, 1.17], ['Pine 11', 24, -9, 1.04], ['Pine 12', 16, -15, 1.24],
  ['Pine 13', -34, -18, 1.32], ['Pine 14', -25, -27, 1.0], ['Pine 15', -15, -34, 1.16], ['Pine 16', 15, -34, 1.1], ['Pine 17', 25, -26, 1.34], ['Pine 18', 34, -18, 1.08],
  ['Pine 19', -34, 31, 1.28], ['Pine 20', -22, 34, 1.08], ['Pine 21', -10, 31, 1.18], ['Pine 22', 11, 34, 1.04], ['Pine 23', 24, 32, 1.31], ['Pine 24', 35, 30, 1.11],
]) makeTree(n, x, z, s);
box('Gate concrete left', -5.4, 1.8, -7, 0.7, 3.6, 1.1, mats.concreteDark);
box('Gate concrete right', 5.4, 1.8, -7, 0.7, 3.6, 1.1, mats.concreteDark);
box('Gate beam', 0, 3.38, -7, 11.4, 0.56, 1.2, mats.metal);
sign('NORTH CASCADE  /  RESEARCH FACILITY', 0, 3.35, -7.63);
for (const x of [-4.5, 4.5]) for (const z of [-4, -8.8]) cylinder('Gate bollard', x, 0.62, z, 0.12, 0.16, 1.25, mats.rust, 8);

// North Cascade city district. Every block and landmark below has an authored,
// fixed location; repeated façade parts use the same hand-set module spacing.
box('City ground', 0, -0.38, 108, 174, 0.48, 164, mats.mud, { solid: false });
box('North Cascade main avenue', 0, -0.08, 108, 14, 0.12, 158, mats.asphalt, { solid: false });
for (const x of [-9.5, 9.5]) box('Main avenue sidewalk', x, 0.0, 108, 4.8, 0.16, 158, mats.sidewalk, { solid: false });
for (const x of [-7.15, 7.15]) box('Avenue curb', x, 0.07, 108, 0.22, 0.24, 158, mats.dirtyWhite, { solid: false });
for (const z of [55, 81, 107, 133, 159, 185]) {
  box('Cross street', 0, -0.075, z, 164, 0.13, 9.2, mats.asphalt, { solid: false });
  for (const x of [-7.6, -6.35, 6.35, 7.6]) box('Intersection crosswalk stripe', x, 0.005, z, 0.48, 0.018, 3.8, mats.whitePaint, { solid: false });
  for (let lane = -72; lane <= 72; lane += 12) {
    if (Math.abs(lane) > 11) box('Cross street lane dash', lane, 0.006, z, 4.3, 0.018, 0.12, mats.whitePaint, { solid: false });
  }
}
for (const x of [-78, 78]) box('Outer avenue sidewalk', x, 0, 108, 4, 0.16, 158, mats.sidewalk, { solid: false });
for (let z = 34; z <= 178; z += 12) {
  for (const x of [-11, 11]) {
    cylinder('Streetlight pole', x, 3.0, z, 0.075, 0.11, 6, mats.metal, 8);
    const arm = cylinder('Streetlight arm', x + Math.sign(x) * 0.8, 5.85, z, 0.045, 0.055, 1.7, mats.metal, 7);
    arm.rotation.z = Math.sign(x) * Math.PI / 2;
    box('Streetlight hood', x + Math.sign(x) * 1.55, 5.58, z, 0.7, 0.12, 0.42, mats.metal, { solid: false });
    box('Streetlight lens', x + Math.sign(x) * 1.55, 5.5, z, 0.48, 0.035, 0.29, mats.litWindow, { solid: false });
    const light = addLight('Sodium avenue lamp', 0xd3a16a, 0.72, 13, x + Math.sign(x) * 1.55, 5.25, z);
    light.userData.baseIntensity = 0.72;
  }
}
function addInstancedBoxes(name, size, material, positions) {
  if (positions.length === 0) return;
  const mesh = new THREE.InstancedMesh(new THREE.BoxGeometry(...size), material, positions.length);
  mesh.name = name; mesh.castShadow = false; mesh.receiveShadow = false;
  const dummy = new THREE.Object3D();
  positions.forEach((position, index) => { dummy.position.set(...position); dummy.updateMatrix(); mesh.setMatrixAt(index, dummy.matrix); });
  mesh.instanceMatrix.needsUpdate = true; scene.add(mesh);
}
function furnishCityInterior(building, towardRoad) {
  const { name, x, z, width, depth } = building;
  const inward = -towardRoad;
  const floorMat = /hospital|medical|pharmacy|school|market|grocery|laundromat/i.test(name) ? mats.tile : mats.wood;
  box(`${name} interior floor`, x, 0.035, z, width - 0.7, 0.1, depth - 0.7, floorMat, { solid: false });
  box(`${name} entry mat`, x + inward * (width * 0.29), 0.095, z + depth * 0.28, 1.25, 0.035, 1.8, mats.fabric, { solid: false });
  const lampX = x + inward * (width * 0.12);
  box(`${name} ceiling light fixture`, lampX, 3.05, z, 1.25, 0.09, 2.2, mats.metal, { solid: false });
  const interiorLight = addLight(`${name} interior light`, 0xe6bd83, 0.58, Math.max(width, depth) * 0.95, lampX, 2.76, z);
  interiorLight.userData.baseIntensity = 0.58;

  const at = (localX, localZ) => [x + inward * localX, z + localZ];
  const table = (label, localX, localZ, w = 2.1, d = 1.15) => {
    const [tx, tz] = at(localX, localZ);
    box(`${name} ${label} tabletop`, tx, 0.88, tz, w, 0.15, d, mats.wood);
    for (const sx of [-1, 1]) for (const sz of [-1, 1]) box(`${name} ${label} leg`, tx + sx * (w / 2 - 0.12), 0.43, tz + sz * (d / 2 - 0.12), 0.12, 0.78, 0.12, mats.metal);
  };
  const shelf = (label, localX, localZ, w = 2.7, levels = 3) => {
    const [sx, sz] = at(localX, localZ);
    box(`${name} ${label} frame`, sx, 1.25, sz, w, 2.5, 0.42, mats.metal);
    for (let level = 0; level < levels; level++) {
      const y = 0.42 + level * (1.72 / Math.max(1, levels - 1));
      box(`${name} ${label} shelf ${level + 1}`, sx, y, sz - 0.12, w + 0.12, 0.08, 0.64, mats.wood, { solid: false });
      for (let item = 0; item < Math.max(2, Math.floor(w / 0.52)); item++) {
        const itemX = sx - w * 0.39 + item * (w * 0.78 / Math.max(1, Math.floor(w / 0.52) - 1));
        const height = 0.2 + ((item + level * 2) % 4) * 0.075;
        box(`${name} ${label} stock ${level + 1}-${item + 1}`, itemX, y + 0.04 + height / 2, sz - 0.19, 0.22, height, 0.3, [mats.dirtyWhite, mats.red, mats.paper, mats.rust][(item + level) % 4], { solid: false });
      }
    }
  };
  const counter = (label, localX, localZ, w = 3.4) => {
    const [cx, cz] = at(localX, localZ);
    box(`${name} ${label} counter base`, cx, 0.56, cz, w, 1.05, 0.9, mats.wood);
    box(`${name} ${label} counter top`, cx, 1.12, cz, w + 0.16, 0.12, 1.02, mats.metal);
    box(`${name} ${label} register`, cx + w * 0.27, 1.34, cz - 0.12, 0.48, 0.34, 0.34, mats.concreteDark);
    box(`${name} ${label} register display`, cx + w * 0.27, 1.53, cz - 0.3, 0.34, 0.1, 0.025, mats.screen, { solid: false });
  };
  const chair = (label, localX, localZ) => {
    const [cx, cz] = at(localX, localZ);
    box(`${name} ${label} seat`, cx, 0.52, cz, 0.55, 0.12, 0.55, mats.fabric);
    box(`${name} ${label} back`, cx, 0.87, cz + 0.23, 0.55, 0.66, 0.1, mats.fabric);
    for (const dx of [-0.2, 0.2]) for (const dz of [-0.2, 0.2]) box(`${name} ${label} leg`, cx + dx, 0.25, cz + dz, 0.07, 0.48, 0.07, mats.metal);
  };

  if (/diner|cafe|tavern/i.test(name)) {
    counter('service', width * 0.27, -depth * 0.1, width * 0.4);
    for (const [lx, lz] of [[-width * 0.22, -depth * 0.25], [-width * 0.22, depth * 0.05], [-width * 0.22, depth * 0.32]]) { table('booth table', lx, lz, 1.55, 1.0); chair('booth chair', lx + 0.5, lz + 0.68); }
    shelf('back-bar bottles', width * 0.27, -depth * 0.34, width * 0.34, 2);
  } else if (/market|grocery|pharmacy|hardware|books|stationer|pawn|laundromat/i.test(name)) {
    counter('checkout', width * 0.28, -depth * 0.25, width * 0.34);
    shelf('stock aisle A', -width * 0.22, -depth * 0.2, width * 0.4, 4);
    shelf('stock aisle B', -width * 0.22, depth * 0.19, width * 0.4, 4);
    if (/laundromat/i.test(name)) for (const [lx, lz] of [[-width * 0.25, -depth * 0.3], [-width * 0.25, -depth * 0.04], [-width * 0.25, depth * 0.22]]) {
      const [mx, mz] = at(lx, lz);
      box(`${name} washer body`, mx, 0.76, mz, 1.1, 1.45, 0.9, mats.dirtyWhite);
      cylinder(`${name} washer drum`, mx + towardRoad * 0.56, 0.77, mz, 0.35, 0.35, 0.1, mats.metal, 16);
      cylinder(`${name} washer glass`, mx + towardRoad * 0.62, 0.77, mz, 0.24, 0.24, 0.035, mats.glass, 16);
    }
  } else if (/hospital|medical/i.test(name)) {
    for (const [lx, lz] of [[-width * 0.24, -depth * 0.24], [-width * 0.24, depth * 0.22]]) {
      const [bx, bz] = at(lx, lz);
      box(`${name} examination bed`, bx, 0.62, bz, 1.1, 0.25, 2.4, mats.dirtyWhite);
      box(`${name} pillow`, bx, 0.8, bz + 0.78, 0.82, 0.18, 0.48, mats.paper, { solid: false });
      box(`${name} bed frame`, bx, 0.32, bz, 0.09, 0.55, 2.25, mats.metal);
      box(`${name} monitor`, bx + inward * 1.2, 1.52, bz - 0.72, 0.62, 0.9, 0.12, mats.concreteDark);
      box(`${name} monitor display`, bx + inward * 1.2, 1.55, bz - 0.65, 0.5, 0.62, 0.03, mats.screen, { solid: false });
    }
    counter('nurses station', width * 0.27, 0, width * 0.3);
  } else if (/hotel|motel|apartments/i.test(name)) {
    for (const [lx, lz] of [[-width * 0.22, -depth * 0.22], [-width * 0.22, depth * 0.24]]) {
      const [bx, bz] = at(lx, lz);
      box(`${name} bed frame`, bx, 0.38, bz, 2.2, 0.5, 3.2, mats.wood);
      box(`${name} mattress`, bx, 0.69, bz, 2.12, 0.22, 3.08, mats.fabric, { solid: false });
      box(`${name} pillow`, bx, 0.84, bz + 1.02, 1.0, 0.18, 0.62, mats.paper, { solid: false });
      box(`${name} nightstand`, bx + towardRoad * 1.5, 0.57, bz + 0.75, 0.78, 1.08, 0.72, mats.wood);
    }
    counter('reception', width * 0.27, -depth * 0.22, width * 0.32);
  } else if (/cinema/i.test(name)) {
    counter('ticket booth', width * 0.28, -depth * 0.26, width * 0.3);
    for (let row = 0; row < 3; row++) for (let seat = 0; seat < 4; seat++) {
      const [sx, sz] = at(-width * 0.22 + row * 1.45, -depth * 0.12 + seat * 1.2);
      box(`${name} cinema seat cushion`, sx, 0.58, sz, 0.88, 0.28, 0.92, mats.red);
      box(`${name} cinema seat back`, sx, 1.04, sz + 0.34, 0.88, 0.85, 0.18, mats.red);
    }
    box(`${name} projection screen`, x + inward * (width * 0.42), 1.9, z, 0.12, 2.6, depth * 0.65, mats.dirtyWhite, { solid: false });
  } else if (/school|library|records|municipal|hall|police|office|exchange|water department|fire station|chapel/i.test(name)) {
    for (const [lx, lz] of [[-width * 0.22, -depth * 0.23], [-width * 0.22, depth * 0.2]]) { table('work table', lx, lz, 2.4, 1.25); chair('work chair', lx + 0.85, lz + 0.9); }
    shelf(/library|records/i.test(name) ? 'archive books' : 'files', width * 0.27, -depth * 0.2, width * 0.28, 4);
    counter('front desk', width * 0.28, depth * 0.28, width * 0.32);
  } else {
    table('workbench', -width * 0.2, -depth * 0.17, 2.8, 1.2);
    counter('service counter', width * 0.26, -depth * 0.16, width * 0.32);
    shelf('equipment rack', -width * 0.2, depth * 0.22, width * 0.34, 3);
  }
  if (building.damaged) {
    const [dx, dz] = at(-width * 0.12, depth * 0.36);
    box(`${name} interior debris`, dx, 0.22, dz, 1.5, 0.44, 1.1, mats.rust, { solid: false });
    for (let shard = 0; shard < 4; shard++) box(`${name} broken plaster fragment ${shard + 1}`, dx - 0.7 + shard * 0.42, 0.05 + shard * 0.012, dz + 0.72, 0.3, 0.09, 0.22, mats.dirtyWhite, { solid: false });
  }
}
function cityBuilding({ name, x, z, width, depth, height, material, floors, signText, damaged = false }) {
  const towardRoad = x < 0 ? 1 : -1;
  const innerRoomHeight = 3.35;
  const wallThickness = 0.38;
  const outerX = x + towardRoad * (width / 2 - wallThickness / 2);
  const innerX = x - towardRoad * (width / 2 - wallThickness / 2);
  // Upper storeys remain as a skyline shell; the street-level storey is a real,
  // collision-bounded room with a walk-through entrance in the road-facing wall.
  const upperHeight = Math.max(0.3, height - innerRoomHeight);
  box(`${name} upper storey shell`, x, innerRoomHeight + upperHeight / 2, z, width, upperHeight, depth, material, { solid: false, cast: false });
  box(`${name} interior floor slab`, x, -0.1, z, width - wallThickness, 0.2, depth - wallThickness, mats.concreteDark, { solid: false });
  const entranceZ = z + depth * 0.28;
  const entryWidth = Math.min(1.8, depth * 0.14);
  const northPierLength = entranceZ - entryWidth / 2 - (z - depth / 2);
  const southPierLength = z + depth / 2 - (entranceZ + entryWidth / 2);
  const northGlassLength = Math.max(0.5, northPierLength - 1.3);
  const southGlassLength = Math.max(0.5, southPierLength - 0.8);
  for (const [part, segmentZ, segmentLength] of [
    ['north', z - depth / 2 + northPierLength / 2, northPierLength],
    ['south', entranceZ + entryWidth / 2 + southPierLength / 2, southPierLength],
  ]) {
    box(`${name} ${part} storefront sill`, outerX, 0.3, segmentZ, wallThickness, 0.6, segmentLength, material);
    box(`${name} ${part} storefront lintel`, outerX, 2.82, segmentZ, wallThickness, 1.06, segmentLength, material);
    for (const edge of [-1, 1]) box(`${name} ${part} storefront pier ${edge}`, outerX, 1.55, segmentZ + edge * (segmentLength / 2 - 0.12), wallThickness, 2.5, 0.24, material);
  }
  box(`${name} front wall lintel`, outerX, innerRoomHeight - 0.34, entranceZ, wallThickness, 0.68, entryWidth, material);
  for (const [sideName, sideX] of [['inner', innerX], ['outer', outerX]]) {
    box(`${name} ${sideName} wall`, sideX, innerRoomHeight / 2, z, wallThickness, innerRoomHeight, depth, material);
  }
  for (const sideZ of [z - depth / 2 + wallThickness / 2, z + depth / 2 - wallThickness / 2]) box(`${name} end wall`, x, innerRoomHeight / 2, sideZ, width, innerRoomHeight, wallThickness, material);
  box(`${name} doorway threshold`, outerX - towardRoad * 0.3, 0.04, entranceZ, 0.75, 0.08, entryWidth, mats.metal, { solid: false });
  furnishCityInterior({ name, x, z, width, depth, damaged }, towardRoad);
  const frontX = x + towardRoad * (width / 2 + 0.035);
  const windowColumns = Math.max(2, Math.floor(depth / 3.4));
  const windowRows = Math.max(2, floors);
  const darkWindows = [], litWindows = [], sills = [], dividers = [];
  for (let row = 0; row < windowRows; row++) {
    const y = innerRoomHeight + 1.15 + row * Math.max(0.6, (height - innerRoomHeight - 2.9) / Math.max(1, windowRows - 1));
    for (let col = 0; col < windowColumns; col++) {
      const zz = z - depth / 2 + 1.7 + col * ((depth - 3.4) / Math.max(1, windowColumns - 1));
      const lit = ((row * 7 + col * 3 + Math.round(Math.abs(x) + z)) % 9) === 2;
      (lit ? litWindows : darkWindows).push([frontX, y, zz]);
      for (const yFrame of [y - 0.74, y + 0.74]) sills.push([frontX + towardRoad * 0.055, yFrame, zz]);
      dividers.push([frontX + towardRoad * 0.06, y, zz]);
    }
  }
  addInstancedBoxes(`${name} dark windowpanes`, [0.075, 1.35, 1.08], mats.cityGlass, darkWindows);
  addInstancedBoxes(`${name} lit windowpanes`, [0.075, 1.35, 1.08], mats.litWindow, litWindows);
  addInstancedBoxes(`${name} window sills`, [0.16, 0.055, 1.2], mats.metal, sills);
  addInstancedBoxes(`${name} window dividers`, [0.15, 1.32, 0.055], mats.metal, dividers);
  for (const side of [-1, 1]) {
    box(`${name} facade corner pilaster ${side}`, frontX + towardRoad * 0.11, height / 2, z + side * (depth / 2 - 0.22), 0.2, height, 0.24, damaged ? mats.rust : mats.concreteDark, { solid: false });
  }
  for (let level = 0; level < windowRows; level++) {
    const bandY = innerRoomHeight + 0.55 + level * Math.max(0.6, (height - innerRoomHeight - 1.1) / Math.max(1, windowRows));
    if (bandY < height - 0.25) box(`${name} facade floor belt ${level + 1}`, frontX + towardRoad * 0.09, bandY, z, 0.14, 0.12, depth, mats.metal, { solid: false });
    if (/hotel|apartments|tower/i.test(name) && !/water tower/i.test(name) && level > 0 && level < windowRows - 1) {
      const balconyY = innerRoomHeight + 1.5 + level * Math.max(0.6, (height - innerRoomHeight - 3) / Math.max(1, windowRows - 1));
      box(`${name} balcony slab ${level}`, frontX + towardRoad * 0.62, balconyY - 0.55, z, 0.72, 0.14, Math.min(3.2, depth * 0.42), mats.concreteDark, { solid: false });
      box(`${name} balcony rail top ${level}`, frontX + towardRoad * 0.92, balconyY + 0.02, z, 0.08, 0.08, Math.min(3.2, depth * 0.42), mats.metal, { solid: false });
      for (let rail = -1; rail <= 1; rail++) box(`${name} balcony baluster ${level}-${rail + 2}`, frontX + towardRoad * 0.92, balconyY - 0.26, z + rail * 0.82, 0.055, 0.55, 0.055, mats.metal, { solid: false });
    }
  }
  // Ground-floor glass panels flank the real opening; the entrance stays clear.
  for (const [side, glassZ, glassLength] of [
    [-1, z - depth / 2 + northPierLength / 2, northGlassLength],
    [1, entranceZ + entryWidth / 2 + southPierLength / 2, southGlassLength],
  ]) {
    const paneLength = Math.max(0.45, glassLength - 0.28);
    const pane = box(`${name} storefront glazing ${side}`, frontX + towardRoad * 0.065, 1.52, glassZ, 0.055, 1.84, paneLength, mats.cityGlass, { solid: false, cast: false });
    solids.push({ minX: pane.position.x - 0.055, maxX: pane.position.x + 0.055, minZ: glassZ - paneLength / 2, maxZ: glassZ + paneLength / 2, minY: 0.6, maxY: 2.45, mesh: pane });
    box(`${name} shopfront mullion ${side}`, frontX + towardRoad * 0.11, 1.52, glassZ, 0.08, 1.92, 0.08, mats.metal, { solid: false });
  }
  box(`${name} awning`, frontX + towardRoad * 0.34, 2.45, z, 0.62, 0.16, depth * 0.62, damaged ? mats.rust : mats.red, { solid: false });
  sign(signText || name.toUpperCase(), frontX + towardRoad * 0.23, Math.min(height - 0.9, 3.4), z, towardRoad > 0 ? Math.PI / 2 : -Math.PI / 2);
  // Rooftop plant and one fixed exhaust stack give each skyline silhouette a distinct top.
  box(`${name} rooftop plant`, x - width * 0.23, height + 0.42, z + depth * 0.22, width * 0.27, 0.82, 1.1, mats.metal, { solid: false });
  cylinder(`${name} roof vent`, x + width * 0.27, height + 0.72, z - depth * 0.22, 0.24, 0.32, 1.4, mats.rust, 8);
  if (damaged) {
    box(`${name} boarded window`, frontX + towardRoad * 0.09, 1.2, z - depth * 0.32, 0.13, 0.52, 1.2, mats.bark, { solid: false });
    box(`${name} facade damage`, frontX + towardRoad * 0.08, height * 0.58, z + depth * 0.36, 0.12, 0.08, depth * 0.21, mats.rust, { solid: false });
  }
}
const cityBuildings = [
  { name: 'Cascade Municipal Hall', x: -20, z: 42, width: 15, depth: 18, height: 17, material: mats.sandstone, floors: 5, signText: 'MUNICIPAL HALL' },
  { name: 'Rainier Pharmacy', x: 20, z: 42, width: 13, depth: 17, height: 10, material: mats.plaster, floors: 3, signText: 'RAINIER PHARMACY', damaged: true },
  { name: 'Cascade Hotel', x: -39, z: 42, width: 16, depth: 18, height: 29, material: mats.brick, floors: 9, signText: 'CASCADE HOTEL' },
  { name: 'Northline Books', x: 39, z: 42, width: 14, depth: 16, height: 12, material: mats.brick, floors: 4, signText: 'NORTHLINE BOOKS' },
  { name: 'Residential Tower West', x: -60, z: 42, width: 17, depth: 18, height: 36, material: mats.concreteDark, floors: 12, signText: 'NORTH CASCADE' },
  { name: 'Old Cinema', x: 60, z: 42, width: 18, depth: 19, height: 14, material: mats.rust, floors: 4, signText: 'CINEMA 6', damaged: true },
  { name: 'Corner Grocery', x: -20, z: 68, width: 14, depth: 18, height: 10, material: mats.plaster, floors: 3, signText: 'CORNER GROCERY' },
  { name: 'Cascade Police Annex', x: 20, z: 68, width: 15, depth: 18, height: 14, material: mats.concrete, floors: 4, signText: 'POLICE ANNEX' },
  { name: 'Riverside Apartments', x: -39, z: 68, width: 17, depth: 18, height: 25, material: mats.brick, floors: 8, signText: 'RIVERSIDE APTS', damaged: true },
  { name: 'Cascade Credit Union', x: 39, z: 68, width: 15, depth: 17, height: 16, material: mats.sandstone, floors: 5, signText: 'CREDIT UNION' },
  { name: 'The Lantern Diner', x: -60, z: 68, width: 17, depth: 18, height: 10, material: mats.rust, floors: 3, signText: 'THE LANTERN DINER' },
  { name: 'Medical Offices', x: 60, z: 68, width: 16, depth: 18, height: 22, material: mats.plaster, floors: 7, signText: 'MEDICAL OFFICES' },
  { name: 'Cascade General Hospital', x: -20, z: 94, width: 17, depth: 19, height: 26, material: mats.dirtyWhite, floors: 8, signText: 'CASCADE HOSPITAL' },
  { name: 'Pawn and Repair', x: 20, z: 94, width: 14, depth: 17, height: 11, material: mats.brick, floors: 3, signText: 'PAWN / REPAIR', damaged: true },
  { name: 'Marlow Apartments', x: -39, z: 94, width: 16, depth: 18, height: 20, material: mats.sandstone, floors: 6, signText: 'MARLOW HOUSE' },
  { name: 'Municipal Records', x: 39, z: 94, width: 16, depth: 18, height: 18, material: mats.concrete, floors: 6, signText: 'CITY RECORDS' },
  { name: 'Westbound Bus Depot', x: -60, z: 94, width: 18, depth: 19, height: 13, material: mats.concreteDark, floors: 3, signText: 'BUS DEPOT' },
  { name: 'Stationer and Cafe', x: 60, z: 94, width: 16, depth: 17, height: 11, material: mats.rust, floors: 3, signText: 'STATIONER / CAFE' },
  { name: 'North Cascade School', x: -20, z: 120, width: 18, depth: 20, height: 15, material: mats.brick, floors: 4, signText: 'NORTH CASCADE SCHOOL' },
  { name: 'Telephone Exchange', x: 20, z: 120, width: 14, depth: 18, height: 19, material: mats.concreteDark, floors: 6, signText: 'TELEPHONE EXCHANGE' },
  { name: 'Juniper Apartments', x: -39, z: 120, width: 17, depth: 19, height: 31, material: mats.plaster, floors: 10, signText: 'JUNIPER HOUSE' },
  { name: 'North Cascade Library', x: 39, z: 120, width: 17, depth: 18, height: 20, material: mats.sandstone, floors: 6, signText: 'PUBLIC LIBRARY' },
  { name: 'Railyard Warehouse', x: -60, z: 120, width: 19, depth: 20, height: 14, material: mats.rust, floors: 3, signText: 'RAIL YARD 04', damaged: true },
  { name: 'Northgate Market', x: 60, z: 120, width: 18, depth: 20, height: 12, material: mats.plaster, floors: 3, signText: 'NORTHGATE MARKET' },
  { name: 'Motel North', x: -20, z: 146, width: 15, depth: 18, height: 12, material: mats.rust, floors: 3, signText: 'MOTEL NORTH', damaged: true },
  { name: 'Water Department', x: 20, z: 146, width: 16, depth: 18, height: 14, material: mats.concrete, floors: 4, signText: 'WATER DEPT' },
  { name: 'St Agnes Chapel', x: -39, z: 146, width: 17, depth: 19, height: 21, material: mats.sandstone, floors: 4, signText: 'ST AGNES' },
  { name: 'Hardware Store', x: 39, z: 146, width: 16, depth: 18, height: 11, material: mats.brick, floors: 3, signText: 'HARDWARE' },
  { name: 'Laundromat', x: -60, z: 146, width: 17, depth: 18, height: 10, material: mats.plaster, floors: 3, signText: 'CLEAN SPIN' },
  { name: 'Eastline Apartments', x: 60, z: 146, width: 17, depth: 18, height: 27, material: mats.concreteDark, floors: 9, signText: 'EASTLINE' },
  { name: 'Water Tower Base', x: -20, z: 172, width: 17, depth: 18, height: 15, material: mats.concreteDark, floors: 4, signText: 'WATERWORKS' },
  { name: 'Fire Station 2', x: 20, z: 172, width: 17, depth: 18, height: 13, material: mats.brick, floors: 3, signText: 'FIRE STATION 2' },
  { name: 'North Ridge Tower', x: -39, z: 172, width: 18, depth: 19, height: 34, material: mats.concrete, floors: 11, signText: 'NORTH RIDGE' },
  { name: 'Freight Terminal', x: 39, z: 172, width: 18, depth: 19, height: 16, material: mats.rust, floors: 4, signText: 'FREIGHT TERMINAL' },
  { name: 'Cold Storage', x: -60, z: 172, width: 18, depth: 19, height: 13, material: mats.plaster, floors: 3, signText: 'COLD STORAGE' },
  { name: 'West End Tavern', x: 60, z: 172, width: 17, depth: 18, height: 11, material: mats.brick, floors: 3, signText: 'WEST END TAVERN', damaged: true },
];
for (const building of cityBuildings) cityBuilding(building);
const waterTowerLegs = [[-21.4, 172.8], [-18.6, 172.8], [-21.4, 175.2], [-18.6, 175.2]];
for (const [x, z] of waterTowerLegs) cylinder('Water tower steel leg', x, 22.1, z, 0.18, 0.25, 14.2, mats.metal, 8);
cylinder('Water tower tank', -20, 29.4, 174, 3.8, 3.9, 5.0, mats.rust, 18);
const tankRoof = new THREE.Mesh(new THREE.SphereGeometry(3.78, 16, 8, 0, Math.PI * 2, 0, Math.PI / 2), mats.rust);
tankRoof.position.set(-20, 31.9, 174); scene.add(tankRoof);
box('Water tower lettering plate', -20, 29.5, 170.06, 2.4, 1.15, 0.08, mats.dirtyWhite, { solid: false });
sign('NORTH CASCADE', -20, 29.6, 169.98);

function addCar(name, x, z, color, rotation = 0, van = false) {
  const root = new THREE.Group(); root.name = name; root.position.set(x, 0, z); root.rotation.y = rotation; scene.add(root);
  const length = van ? 3.8 : 3.3, width = van ? 1.72 : 1.8, bodyY = van ? 0.76 : 0.62;
  box(`${name} chassis`, 0, bodyY, 0, width, van ? 1.18 : 0.86, length, mat(`${name}-paint`, color, 0.58, 0.34), { solid: false, parent: root });
  solids.push({ minX: x - width / 2, maxX: x + width / 2, minZ: z - length / 2, maxZ: z + length / 2, minY: 0, maxY: bodyY + 0.75, mesh: null });
  box(`${name} windshield`, 0, bodyY + (van ? 0.57 : 0.55), -0.3, width * 0.82, van ? 0.62 : 0.52, length * 0.36, mats.glass, { solid: false, parent: root });
  box(`${name} hood`, 0, bodyY + 0.36, -length * 0.32, width * 0.9, 0.16, length * 0.32, mats.metal, { solid: false, parent: root });
  for (const side of [-1, 1]) for (const axle of [-1, 1]) {
    const wheel = cylinder(`${name} wheel`, side * width * 0.51, 0.38, axle * length * 0.31, 0.36, 0.36, 0.22, mats.tire, 10, root);
    wheel.rotation.z = Math.PI / 2;
    cylinder(`${name} hub`, side * (width * 0.51 + 0.02), 0.38, axle * length * 0.31, 0.15, 0.15, 0.23, mats.metal, 8, root).rotation.z = Math.PI / 2;
  }
  for (const side of [-1, 1]) box(`${name} headlamp`, side * 0.58, bodyY + 0.09, -length / 2 - 0.015, 0.32, 0.17, 0.05, mats.litWindow, { solid: false, parent: root });
  return root;
}
addCar('Abandoned blue sedan', -4.75, 53, 0x34474b, 0.12);
addCar('Derelict delivery van', 4.45, 78, 0x51483d, -0.08, true);
addCar('Flooded taxi', -4.8, 109, 0x78643d, 0.04);
addCar('Unmarked patrol car', 4.8, 137, 0x343c40, -0.06);
for (const [x, z] of [[-14, 46], [14, 72], [-14, 98], [14, 124], [-14, 150], [14, 176]]) {
  box('City utility cabinet', x, 0.78, z, 0.72, 1.56, 0.68, mats.metal);
  box('Utility hazard plate', x + (x < 0 ? 0.37 : -0.37), 0.84, z, 0.025, 0.62, 0.48, mats.red, { solid: false });
}
for (const [x, z, label] of [[-11.5, 55, 'NORTH CASCADE'], [11.5, 107, 'HOSPITAL / DOWNTOWN'], [-11.5, 159, 'RIVER DISTRICT'], [11.5, 185, 'NORTH RIDGE']]) {
  cylinder('Street sign post', x, 1.6, z, 0.045, 0.055, 3.2, mats.metal, 7);
  sign(label, x, 3.15, z, x < 0 ? Math.PI / 2 : -Math.PI / 2);
}
// Forest and city edges are bounded so the walkable district has a clear footprint.
box('City boundary west', -85, 5, 108, 1, 10, 168, mats.bark);
box('City boundary east', 85, 5, 108, 1, 10, 168, mats.bark);
box('City boundary north', 0, 5, 190, 170, 10, 1, mats.bark);
box('World boundary south', 0, 5, -48, 186, 10, 1, mats.bark);
box('World boundary west', -93, 5, -2, 1, 10, 92, mats.bark);
box('World boundary east', 93, 5, -2, 1, 10, 92, mats.bark);

// Manually authored interior footprint; wall breaks are explicit door openings.
roomShell('Entry checkpoint', 0, -5.4, 9, 13.2, [{ side: 'north', width: 2.5 }, { side: 'south', width: 2.5 }, { side: 'east', width: 1.8 }]);
roomShell('Main corridor', 0, -20.4, 7, 16.8, [{ side: 'north', width: 2.5 }, { side: 'south', width: 2.4 }, { side: 'west', width: 1.7, z: -18.1 }, { side: 'east', width: 1.8, z: -18.1 }]);
roomShell('Administration office', 8.1, -5.4, 9.2, 9.2, [{ side: 'west', width: 1.8 }]);
roomShell('Generator service bay', -7.4, -18.1, 7.4, 9.2, [{ side: 'east', width: 1.7 }]);
roomShell('Research laboratory', 8.1, -18.0, 9.2, 9.6, [{ side: 'west', width: 1.8 }, { side: 'north', width: 1.8 }]);
roomShell('Lower lab antechamber', 8.1, -28.6, 9.2, 8, [{ side: 'south', width: 1.8 }]);
roomShell('Service exit', 0, -30.0, 7, 4.8, [{ side: 'north', width: 2.4 }, { side: 'south', width: 2.4 }]);

// Surface dressing: seams, ceiling ribs, cables, workstations, lockers and warning lights.
for (const z of [-12, -15.5, -19, -22.5, -26]) {
  box('Corridor ceiling rib', 0, 3.3, z, 6.7, 0.16, 0.12, mats.metal, { solid: false });
  box('Ceiling fluorescent housing', 0, 3.08, z, 1.7, 0.1, 0.36, mats.dirtyWhite, { solid: false });
  const lamp = addLight('Faulty corridor fluorescent', 0xa3c4c1, 0.82, 7.5, 0, 2.83, z);
  lamp.userData.baseIntensity = 0.82;
}
sign('AUTHORIZED PERSONNEL ONLY', 0, 2.55, -12.5);
sign('ADMINISTRATION', 8.1, 2.45, -0.82);
sign('GENERATOR BAY / 01', -7.4, 2.45, -22.72, Math.PI);
sign('BIORESEARCH / LEVEL B', 8.1, 2.45, -22.84, Math.PI);
sign('EXIT  →', 0, 2.43, -28.43);
// Admin desks and paper stacks.
box('Reception desk top', 8.0, 0.86, -4.1, 3.0, 0.16, 1.25, mats.rust);
box('Reception desk pedestal', 8.0, 0.4, -4.1, 2.35, 0.76, 0.9, mats.metal);
box('Desk terminal housing', 8.0, 1.3, -4.22, 0.76, 0.64, 0.18, mats.metal);
box('Desk terminal screen', 8.0, 1.34, -4.105, 0.62, 0.42, 0.035, mats.screen, { solid: false });
for (const [x, z] of [[10.8, -7.9], [10.8, -5.8], [5.3, -7.8]]) {
  box('Filing cabinet', x, 1.02, z, 0.8, 2.04, 0.72, mats.metal);
  for (const y of [0.5, 1.0, 1.5]) box('Cabinet drawer', x, y, z - 0.38, 0.66, 0.42, 0.035, mats.concreteDark, { solid: false });
}
// Research tables, specimen tubes and the locker used as a hiding place.
for (const [x, z] of [[6.2, -16.1], [10.4, -16.1], [6.2, -19.4]]) {
  box('Steel lab bench', x, 0.91, z, 2.8, 0.14, 1.1, mats.metal);
  box('Bench leg L', x - 1.15, 0.45, z, 0.12, 0.82, 0.12, mats.rust);
  box('Bench leg R', x + 1.15, 0.45, z, 0.12, 0.82, 0.12, mats.rust);
  cylinder('Specimen canister', x - 0.42, 1.19, z, 0.14, 0.14, 0.4, mats.glass, 12);
  cylinder('Specimen cap', x - 0.42, 1.41, z, 0.15, 0.15, 0.06, mats.rust, 12);
  box('Stained tray', x + 0.4, 1.02, z - 0.12, 0.82, 0.035, 0.55, mats.concreteDark, { solid: false });
}
box('Emergency locker', 10.9, 1.1, -9.1, 0.9, 2.2, 0.8, mats.rust);
box('Locker door seam', 10.42, 1.1, -9.1, 0.035, 1.95, 0.66, mats.metal, { solid: false });
box('Generator chassis', -8.4, 0.92, -18.2, 2.0, 1.55, 1.55, mats.rust);
box('Generator control panel', -7.35, 1.44, -17.82, 0.6, 0.58, 0.09, mats.metal, { solid: false });
box('Generator indicator', -7.35, 1.52, -17.75, 0.16, 0.1, 0.04, mats.red, { solid: false });
for (const x of [-9.1, -8.4, -7.7]) cylinder('Generator exhaust', x, 1.82, -18.2, 0.09, 0.12, 0.34, mats.metal, 8);
box('Generator fuel can', -9.6, 0.38, -15.1, 0.58, 0.72, 0.44, mats.red);
// Power conduit visually runs along the corridor's west wall toward the generator room.
box('Power conduit', -3.34, 2.7, -18.0, 0.14, 0.16, 16.2, mats.rust, { solid: false });
for (const [x, z] of [[-2.7, -12.3], [2.7, -12.3], [-2.7, -22.7], [2.7, -22.7]]) {
  const emergency = addLight('Emergency red beacon', 0xd74b31, 0.24, 3.2, x, 2.63, z);
  emergency.userData.baseIntensity = 0.24;
}

function createDoor(id, name, x, y, z, width, height, rotation, requirement = null) {
  const pivot = new THREE.Group();
  if (Math.abs(rotation) > 0.7) pivot.position.set(x, y, z + Math.sign(rotation) * width / 2);
  else pivot.position.set(x - width / 2, y, z);
  pivot.rotation.y = rotation; scene.add(pivot);
  const panel = new THREE.Mesh(new THREE.BoxGeometry(width, height, 0.18), mats.metal);
  panel.position.set(width / 2, height / 2, 0); panel.castShadow = true; panel.receiveShadow = true; panel.name = name; pivot.add(panel);
  const stripe = new THREE.Mesh(new THREE.BoxGeometry(width * 0.76, 0.1, 0.192), mats.red); stripe.position.set(width / 2, height * 0.22, 0); pivot.add(stripe);
  const entry = { id, name, x, y, z, width, height, rotation, requirement, pivot, open: false };
  entry.collider = Math.abs(rotation) > 0.7
    ? { minX: x - 0.18, maxX: x + 0.18, minZ: z - width / 2, maxZ: z + width / 2, minY: 0, maxY: height, mesh: panel }
    : { minX: x - width / 2, maxX: x + width / 2, minZ: z - 0.18, maxZ: z + 0.18, minY: 0, maxY: height, mesh: panel };
  solids.push(entry.collider); doors.set(id, entry);
  interactables.push({ id: `door:${id}`, kind: 'door', name, label: `E — ${name}`, position: new THREE.Vector3(x, 1.1, z), target: entry });
  return entry;
}
const accessDoor = createDoor('service', 'Service access door', 0, 0, -12.0, 2.35, 2.65, 0, 'keycard');
const adminDoor = createDoor('administration', 'Administration office door', 3.5, 0, -5.4, 1.8, 2.5, Math.PI / 2);
const genDoor = createDoor('generator', 'Generator bay door', -3.5, 0, -18.1, 1.65, 2.5, Math.PI / 2);
const labDoor = createDoor('lab', 'Research laboratory door', 3.5, 0, -18.1, 1.75, 2.5, -Math.PI / 2);
const lowerDoor = createDoor('lower-lab', 'Lower laboratory door', 8.1, 0, -24.6, 1.72, 2.5, 0, 'power');
const exitDoor = createDoor('exit', 'Emergency exit', 0, 0, -32.35, 2.3, 2.6, 0, 'power');

function propInteract(id, kind, name, x, y, z, color = 0xbac9a5, radius = 0.18) {
  const mesh = new THREE.Mesh(new THREE.IcosahedronGeometry(radius, 1), mat(`glow-${id}`, color, 0.38, 0.12, { emissive: color, emissiveIntensity: 0.36 }));
  mesh.position.set(x, y, z); mesh.castShadow = true; mesh.name = name; scene.add(mesh);
  const glow = new THREE.PointLight(color, 0.12, 1.6); glow.position.copy(mesh.position); scene.add(glow);
  const item = { id, kind, name, label: `E — ${name}`, position: mesh.position.clone(), mesh, glow, taken: false };
  interactables.push(item); return item;
}
const keycard = propInteract('keycard', 'pickup', 'Staff access card', -1.25, 1.02, -3.3, 0x6fa8a1, 0.13);
const firstBattery = propInteract('battery-a', 'battery', 'Flashlight battery', 2.1, 0.6, -5.3, 0xb8ca72, 0.12);
const adminNote = propInteract('note-admin', 'note', 'Duty roster', 8.0, 1.02, -4.1, 0xc2b581, 0.12);
const genNote = propInteract('note-generator', 'note', 'Maintenance report', -9.6, 0.84, -15.1, 0xc2b581, 0.12);
const labNote = propInteract('note-lab', 'note', 'Research log 04', 6.0, 1.25, -16.1, 0xc2b581, 0.12);
const medkit = propInteract('medkit', 'medkit', 'Emergency medkit', 10.3, 0.42, -19.3, 0xc97b68, 0.15);
const spareBattery = propInteract('battery-b', 'battery', 'Spare flashlight cell', 5.4, 0.42, -19.2, 0xb8ca72, 0.12);
const terminal = { id: 'terminal', kind: 'terminal', name: 'Research terminal', label: 'E — Inspect terminal', position: new THREE.Vector3(8.0, 1.4, -4.1), used: false };
interactables.push(terminal);
const generator = { id: 'generator-switch', kind: 'generator', name: 'Auxiliary generator', label: 'E — Restore auxiliary power', position: new THREE.Vector3(-7.35, 1.2, -17.8), used: false };
interactables.push(generator);
const hiding = { id: 'locker', kind: 'hide', name: 'Storage locker', label: 'E — Hide inside locker', position: new THREE.Vector3(10.4, 1.0, -9.1) };
interactables.push(hiding);
const checkpoint = { id: 'checkpoint', kind: 'checkpoint', name: 'Service checkpoint', label: 'E — Save at checkpoint', position: new THREE.Vector3(-5.3, 0.8, -19.6) };
interactables.push(checkpoint);
for (const [id, x, z] of [['checkpoint-marker', -5.3, -19.6], ['exit-marker', 0, -28.5]]) {
  const light = addLight(id, 0x9cad87, 0.18, 2.5, x, 1.9, z); light.userData.baseIntensity = 0.18;
}

// The Stalker is a hand-built, intentionally uncanny silhouette with animated joints.
const stalker = new THREE.Group(); stalker.name = 'The Stalker';
const torso = new THREE.Mesh(new THREE.CapsuleGeometry(0.42, 1.16, 5, 8), mats.creature);
torso.position.y = 1.2; torso.scale.set(0.82, 1.0, 0.72); torso.castShadow = true; stalker.add(torso);
const head = new THREE.Mesh(new THREE.SphereGeometry(0.31, 12, 10), mats.creature);
head.position.set(0, 2.12, -0.08); head.scale.set(0.82, 1.25, 0.88); head.castShadow = true; stalker.add(head);
for (const side of [-1, 1]) {
  const eye = new THREE.Mesh(new THREE.SphereGeometry(0.045, 8, 8), mats.eye);
  eye.position.set(side * 0.105, 2.2, -0.345); stalker.add(eye);
  const arm = cylinder('Stalker arm', side * 0.47, 0.98, 0.02, 0.095, 0.14, 1.2, mats.creature, 7, stalker);
  arm.rotation.z = side * -0.16; arm.userData.swing = side;
  const hand = new THREE.Mesh(new THREE.SphereGeometry(0.105, 7, 6), mats.creature);
  hand.position.set(side * 0.56, 0.36, -0.04); stalker.add(hand);
  for (let claw = 0; claw < 3; claw++) {
    const talon = cylinder('Stalker talon', side * 0.56 + (claw - 1) * 0.075, 0.18, -0.04, 0.018, 0.035, 0.28, mats.creature, 5, stalker);
    talon.rotation.z = 0.08;
  }
  const leg = cylinder('Stalker leg', side * 0.19, 0.29, 0.02, 0.1, 0.15, 0.64, mats.creature, 7, stalker);
  leg.userData.swing = -side;
}
for (const [x, y, z, length, rot] of [[-0.38, 2.18, -0.03, 0.66, -0.82], [0.39, 2.16, 0.02, 0.75, 0.75]]) {
  const horn = cylinder('Stalker crown spur', x, y, z, 0.012, 0.08, length, mats.creature, 6, stalker); horn.rotation.z = rot;
}
stalker.position.set(0.4, 0, -21.5); stalker.visible = false; scene.add(stalker);
const enemy = { state: 'dormant', patrolIndex: 0, path: [new THREE.Vector3(0, 0, -20.5), new THREE.Vector3(-2.5, 0, -24), new THREE.Vector3(1.5, 0, -26.2), new THREE.Vector3(0, 0, -18.8)], lastKnown: new THREE.Vector3(), attackCooldown: 0, alert: 0 };

const player = { position: new THREE.Vector3(0, 0, 116), yaw: 0, pitch: 0, health: 100, battery: 100, hasKey: false, hasNote: false, hasPower: false, objective: 'Follow the emergency signal toward the research facility', crouching: false, running: false, hidden: false, alive: true, flashlightOn: true, inventory: [], discovered: false, cityCleared: false };
const flashlight = new THREE.SpotLight(0xd7e4df, 38, 22, Math.PI / 7, 0.52, 1.4);
flashlight.position.set(0, 1.62, 0); flashlight.target.position.set(0, 1.4, -3); scene.add(flashlight, flashlight.target);
const clock = new THREE.Clock();
const raycaster = new THREE.Raycaster();
const forward = new THREE.Vector3();
const moveInput = { x: 0, y: 0, run: false, crouch: false };
let gameState = 'menu', currentTarget = null, toastTimer = 0, interactionCooldown = 0, flashTimer = 12, lightningTimer = 8, lightningDuration = 0, attackFlash = 0;
let noteReturnState = 'playing';
let audioContext = null, masterGain = null;
let sensitivity = 0.75;

const noteCopy = {
  'note-admin': ['Duty roster — 17 October', '01:42 — Perimeter camera 3 went dark again.\n02:03 — Security has sealed the service entry. Temporary staff badge left at the east reception desk.\n\nIf you hear movement in the ventilation, stay in a lit room. Do not respond to voices on the intercom.'],
  'note-generator': ['Maintenance report 04', 'Auxiliary power can be restored from the manual switch on the generator control panel.\n\nThe main breaker tripped during the evacuation. Once the service bay is secured, reset the panel and route power to the lower laboratory and the emergency exit.\n\nThe noise draws it closer.'],
  'note-lab': ['Research log 04 — Dr. Voss', 'Subject no longer reacts to light. It tracks vibrations through the floor and follows abrupt sounds.\n\nWe lost the west observation team at 01:58. The lower lab door is still on the backup circuit. If power returns, use the north stair and leave the outer exit unlocked.\n\nDo not attempt containment again.'],
};

function setObjective(text) { player.objective = text; ui.objective.textContent = text; }
function toast(message, duration = 2.6) { ui.toast.textContent = message; ui.toast.classList.add('visible'); toastTimer = duration; }
function setScreen(screen) { for (const item of [ui.start, ui.pause, ui.settings, ui.note, ui.ending]) item.classList.add('hidden'); if (screen) screen.classList.remove('hidden'); }
function loadSettings() {
  try {
    const saved = JSON.parse(localStorage.getItem('black-rain-settings') || '{}');
    sensitivity = Number(saved.sensitivity) || 0.75;
    $('sensitivity').value = String(sensitivity);
    $('volume').value = String(saved.volume ?? 0.65);
    $('quality').value = saved.quality || 'medium'; $('rain-quality').value = saved.rain || 'medium';
    applyQuality(saved.quality || 'medium'); applyRain(saved.rain || 'medium'); setVolume(Number(saved.volume ?? 0.65));
  } catch { applyQuality('medium'); applyRain('medium'); }
}
function saveSettings() {
  const value = { sensitivity: Number($('sensitivity').value), volume: Number($('volume').value), quality: $('quality').value, rain: $('rain-quality').value };
  try { localStorage.setItem('black-rain-settings', JSON.stringify(value)); } catch { /* Private browsing can disable storage. */ }
  sensitivity = value.sensitivity;
}
function applyQuality(level) {
  const high = level === 'high', low = level === 'low';
  renderer.setPixelRatio(Math.min(devicePixelRatio || 1, high ? 1.65 : low ? 0.85 : 1.2));
  renderer.shadowMap.enabled = !low;
  scene.fog.density = low ? 0.034 : high ? 0.022 : 0.027;
  moon.intensity = low ? 0.5 : 0.7;
  renderer.setSize(innerWidth, innerHeight);
}
function applyRain(level) {
  const count = rainCount[level] || rainCount.medium;
  rain.geometry.setDrawRange(0, count);
  rain.material.opacity = level === 'low' ? 0.35 : level === 'high' ? 0.58 : 0.48;
}
function ensureAudio() {
  if (audioContext) { if (audioContext.state === 'suspended') audioContext.resume(); return; }
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (!Audio) return;
  audioContext = new Audio(); masterGain = audioContext.createGain(); masterGain.gain.value = Number($('volume').value); masterGain.connect(audioContext.destination);
  const buffer = audioContext.createBuffer(1, audioContext.sampleRate * 2, audioContext.sampleRate);
  const channel = buffer.getChannelData(0);
  for (let i = 0; i < channel.length; i++) channel[i] = (Math.random() * 2 - 1) * 0.16;
  const noise = audioContext.createBufferSource(); noise.buffer = buffer; noise.loop = true;
  const filter = audioContext.createBiquadFilter(); filter.type = 'lowpass'; filter.frequency.value = 420;
  const level = audioContext.createGain(); level.gain.value = 0.13; noise.connect(filter).connect(level).connect(masterGain); noise.start();
  const hum = audioContext.createOscillator(); hum.type = 'sine'; hum.frequency.value = 47;
  const humGain = audioContext.createGain(); humGain.gain.value = 0.026; hum.connect(humGain).connect(masterGain); hum.start();
}
function setVolume(amount) { if (masterGain) masterGain.gain.setTargetAtTime(amount, audioContext.currentTime, 0.05); }
function playTone(frequency, duration = 0.2, type = 'sine', volume = 0.07) {
  if (!audioContext || !masterGain) return;
  const osc = audioContext.createOscillator(), gain = audioContext.createGain();
  osc.type = type; osc.frequency.setValueAtTime(frequency, audioContext.currentTime);
  gain.gain.setValueAtTime(volume, audioContext.currentTime); gain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + duration);
  osc.connect(gain).connect(masterGain); osc.start(); osc.stop(audioContext.currentTime + duration);
}
function playThunder() { playTone(42, 1.8, 'sawtooth', 0.13); playTone(59, 1.2, 'triangle', 0.06); }

function savedState() {
  return { version: 1, position: player.position.toArray(), yaw: player.yaw, health: player.health, battery: player.battery, hasKey: player.hasKey, hasNote: player.hasNote, hasPower: player.hasPower, objective: player.objective, inventory: player.inventory, cityCleared: player.cityCleared, doors: [...doors].filter(([, d]) => d.open).map(([id]) => id), pickups: interactables.filter((i) => i.taken).map((i) => i.id), enemyState: enemy.state };
}
function saveGame(showToast = true) {
  try { localStorage.setItem('black-rain-save', JSON.stringify(savedState())); if (showToast) toast('Checkpoint saved. Progress secured.'); return true; }
  catch { if (showToast) toast('Browser storage is unavailable; progress may not persist.'); return false; }
}
function loadGame() {
  let data;
  try { data = JSON.parse(localStorage.getItem('black-rain-save') || 'null'); } catch { data = null; }
  if (!data || data.version !== 1 || !Array.isArray(data.position) || data.position.length !== 3) return false;
  player.position.fromArray(data.position); player.yaw = Number(data.yaw) || 0;
  player.health = THREE.MathUtils.clamp(Number(data.health) || 100, 1, 100);
  player.battery = THREE.MathUtils.clamp(Number(data.battery) || 0, 0, 100);
  player.hasKey = !!data.hasKey; player.hasNote = !!data.hasNote; player.hasPower = !!data.hasPower;
  player.inventory = Array.isArray(data.inventory) ? data.inventory.filter((v) => typeof v === 'string') : [];
  player.cityCleared = !!data.cityCleared;
  const taken = new Set(Array.isArray(data.pickups) ? data.pickups : []);
  for (const item of interactables) if (taken.has(item.id)) { item.taken = true; if (item.mesh) item.mesh.visible = false; if (item.glow) item.glow.visible = false; }
  for (const id of Array.isArray(data.doors) ? data.doors : []) openDoor(doors.get(id), false);
  if (player.hasPower) restorePower(false);
  setObjective(data.objective || 'Find a way inside');
  return true;
}
function newGame() {
  try { localStorage.removeItem('black-rain-save'); } catch { /* Storage is optional. */ }
  for (const item of interactables) { item.taken = false; if (item.mesh) item.mesh.visible = true; if (item.glow) item.glow.visible = true; item.used = false; }
  for (const door of doors.values()) { door.open = false; door.pivot.rotation.y = door.rotation; if (!solids.includes(door.collider)) solids.push(door.collider); }
  player.position.set(0, 0, 116); player.yaw = 0; player.pitch = 0; player.health = 100; player.battery = 100;
  player.hasKey = false; player.hasNote = false; player.hasPower = false; player.inventory = []; player.hidden = false; player.alive = true; player.flashlightOn = true; player.discovered = false;
  player.cityCleared = false;
  enemy.state = 'dormant'; enemy.alert = 0; enemy.attackCooldown = 0; stalker.position.set(0.4, 0, -21.5); stalker.visible = false;
  setObjective('Follow the emergency signal toward the research facility'); updateHud();
}
function updateHud() {
  $('health-value').textContent = String(Math.ceil(player.health)); $('health-meter').style.width = `${player.health}%`;
  $('battery-value').textContent = `${Math.ceil(player.battery)}%`; $('battery-meter').style.width = `${player.battery}%`;
}
function openDoor(door, animate = true) {
  if (!door || door.open) return;
  door.open = true; door.pivot.rotation.y = door.rotation + (door.rotation === 0 ? -1.35 : 1.35);
  const idx = solids.indexOf(door.collider); if (idx >= 0) solids.splice(idx, 1);
  if (animate) { toast(`${door.name} unlocked.`); playTone(128, 0.4, 'square', 0.08); saveGame(false); }
}
function restorePower(save = true) {
  player.hasPower = true;
  for (const lamp of lamps) lamp.userData.baseIntensity = Math.max(lamp.userData.baseIntensity || 0.3, 0.96);
  const indicator = scene.getObjectByName('Generator indicator'); if (indicator) indicator.material = mat('generatorGreen', 0x76c98c, 0.35, 0, { emissive: 0x28643a, emissiveIntensity: 1.5 });
  setObjective('Reach the emergency service exit');
  if (save) { toast('Auxiliary power restored. Exit circuit online.'); playTone(660, 0.2, 'sine', 0.08); saveGame(false); }
}
function startGame(continueGame = false) {
  ensureAudio();
  void requestLandscapeMode();
  if (!continueGame || !loadGame()) newGame();
  ui.start.classList.add('hidden'); ui.settings.classList.add('hidden'); ui.pause.classList.add('hidden'); ui.hud.classList.remove('hidden');
  gameState = 'playing'; player.alive = true;
  if (!isTouchDevice()) $('world').requestPointerLock?.();
}
function showPause() { if (gameState !== 'playing') return; gameState = 'paused'; setScreen(ui.pause); document.exitPointerLock?.(); }
function resumeGame() { if (gameState !== 'paused') return; setScreen(null); gameState = 'playing'; if (!isTouchDevice()) $('world').requestPointerLock?.(); }
function isTouchDevice() { return matchMedia('(pointer: coarse)').matches || navigator.maxTouchPoints > 0; }
async function requestLandscapeMode() {
  if (!isTouchDevice()) return;
  try {
    if (!document.fullscreenElement && document.documentElement.requestFullscreen) await document.documentElement.requestFullscreen();
  } catch { /* Fullscreen is optional; the responsive layout still supports manual rotation. */ }
  try { await screen.orientation?.lock?.('landscape'); } catch { /* iOS and some browsers only allow manual rotation. */ }
}
function takeDamage(amount) {
  if (!player.alive || player.hidden) return;
  player.health = Math.max(0, player.health - amount); updateHud(); attackFlash = 0.28; playTone(72, 0.35, 'sawtooth', 0.14);
  if (player.health <= 0) { player.alive = false; setObjective('The signal has gone quiet'); toast('You were lost in the facility. Reload from the checkpoint.', 6); setTimeout(() => { if (gameState === 'playing') showPause(); }, 900); }
}
function enterNote(item) {
  const copy = noteCopy[item.id]; if (!copy) return;
  $('note-title').textContent = copy[0]; $('note-body').textContent = copy[1];
  noteReturnState = gameState; gameState = 'note'; ui.note.classList.remove('hidden'); document.exitPointerLock?.();
  if (item.id === 'note-admin') { player.hasNote = true; if (!player.hasKey) setObjective('Find the staff access card at reception'); else setObjective('Find the west generator bay'); }
  if (item.id === 'note-generator') setObjective('Restore auxiliary power in the service bay');
  if (item.id === 'note-lab') setObjective('Reach the emergency service exit');
  saveGame(false);
}
function closeNote() { if (gameState !== 'note') return; ui.note.classList.add('hidden'); gameState = noteReturnState; if (gameState === 'playing' && !isTouchDevice()) $('world').requestPointerLock?.(); }
function interact(item) {
  if (!item || gameState !== 'playing') return;
  if (item.kind === 'door') {
    const door = item.target;
    if (door.open) { toast(`${door.name} is already open.`); return; }
    if (door.requirement === 'keycard' && !player.hasKey) { toast('Access denied. A staff card is required.'); playTone(86, 0.24, 'square'); return; }
    if (door.requirement === 'power' && !player.hasPower) { toast('No power. Restore the auxiliary generator first.'); return; }
    openDoor(door); if (door.id === 'service' && !player.hasKey) setObjective('Find the staff access card');
    if (door.id === 'exit' && player.hasPower) { gameState = 'ending'; setScreen(ui.ending); saveGame(false); }
    return;
  }
  if (item.kind === 'pickup' || item.kind === 'battery' || item.kind === 'medkit') {
    if (item.kind === 'pickup') { player.hasKey = true; player.inventory.push('Staff access card'); setObjective(player.hasNote ? 'Find the generator bay and restore power' : 'Search the administration office'); toast('Staff access card added to inventory.'); }
    if (item.kind === 'battery') { player.battery = Math.min(100, player.battery + 38); toast('Flashlight cell collected. Battery recharged.'); }
    if (item.kind === 'medkit') { player.health = Math.min(100, player.health + 45); toast('Medical kit used. Health restored.'); }
    item.taken = true; item.mesh.visible = false; item.glow.visible = false; updateHud(); saveGame(false); return;
  }
  if (item.kind === 'note') { enterNote(item); return; }
  if (item.kind === 'terminal') {
    if (!item.used) { item.used = true; player.discovered = true; toast('Terminal unlocked the facility map. Main breaker is in the west service bay.'); setObjective('Find the west generator bay'); saveGame(false); }
    return;
  }
  if (item.kind === 'generator') {
    if (item.used) { toast('Auxiliary power is already online.'); return; }
    item.used = true; restorePower(); enemy.state = 'investigate'; enemy.alert = 6; enemy.lastKnown.copy(player.position); stalker.visible = true;
    openDoor(lowerDoor); toast('Generator vibration echoes through the facility. Something heard it.'); return;
  }
  if (item.kind === 'hide') {
    player.hidden = !player.hidden; player.position.set(item.position.x + (player.hidden ? 0 : -1.25), 0, item.position.z + 0.4);
    player.flashlightOn = !player.hidden; flashlight.visible = player.flashlightOn;
    toast(player.hidden ? 'You hold your breath inside the locker.' : 'You leave the locker.');
    if (!player.hidden && enemy.state === 'chase') enemy.state = 'search'; return;
  }
  if (item.kind === 'checkpoint') { saveGame(); return; }
}

function nearestInteractable() {
  camera.getWorldDirection(forward);
  raycaster.set(camera.position, forward); raycaster.far = 2.55;
  const candidates = interactables.filter((item) => !item.taken && (!item.target || !item.target.open) && (item.kind !== 'generator' || !item.used));
  let best = null, bestScore = Infinity;
  for (const item of candidates) {
    const to = item.position.clone().sub(camera.position); const distance = to.length();
    if (distance > 2.55) continue;
    const angle = forward.angleTo(to.normalize());
    if (angle > 0.42) continue;
    const score = distance + angle * 2;
    if (score < bestScore) { best = item; bestScore = score; }
  }
  return best;
}
function updatePrompt() {
  currentTarget = nearestInteractable();
  ui.prompt.textContent = currentTarget?.label || '';
  ui.prompt.classList.toggle('visible', !!currentTarget && gameState === 'playing');
}
function collides(x, z, radius = 0.32) {
  for (const wall of solids) {
    if (wall.minY > 1.6 || wall.maxY < 0.1) continue;
    const cx = THREE.MathUtils.clamp(x, wall.minX, wall.maxX), cz = THREE.MathUtils.clamp(z, wall.minZ, wall.maxZ);
    const dx = x - cx, dz = z - cz;
    if (dx * dx + dz * dz < radius * radius) return true;
  }
  return false;
}
function updatePlayer(dt) {
  if (player.hidden || !player.alive) return;
  const key = (code) => keys.has(code);
  const forwardAxis = (key('KeyW') || key('ArrowUp') ? 1 : 0) - (key('KeyS') || key('ArrowDown') ? 1 : 0) + moveInput.y;
  const sideAxis = (key('KeyD') || key('ArrowRight') ? 1 : 0) - (key('KeyA') || key('ArrowLeft') ? 1 : 0) + moveInput.x;
  player.running = (key('ShiftLeft') || key('ShiftRight') || moveInput.run) && !player.crouching && Math.abs(forwardAxis) + Math.abs(sideAxis) > 0.1;
  player.crouching = key('ControlLeft') || key('ControlRight') || moveInput.crouch;
  const speed = player.crouching ? 1.55 : player.running ? 5.4 : 3.15;
  const length = Math.hypot(forwardAxis, sideAxis) || 1;
  const f = forwardAxis / length, s = sideAxis / length;
  const dx = (Math.sin(player.yaw) * f + Math.cos(player.yaw) * s) * speed * dt;
  const dz = (-Math.cos(player.yaw) * f + Math.sin(player.yaw) * s) * speed * dt;
  if (!collides(player.position.x + dx, player.position.z, 0.34)) player.position.x += dx;
  if (!collides(player.position.x, player.position.z + dz, 0.34)) player.position.z += dz;
  const moving = Math.abs(forwardAxis) + Math.abs(sideAxis) > 0.15;
  if (moving && (player.running || !player.crouching)) {
    enemy.alert = Math.max(enemy.alert, player.running ? 5.2 : 1.6);
    if (enemy.state === 'dormant' && player.position.z < -13.5) { enemy.state = 'patrol'; stalker.visible = true; toast('A distant shape moves behind the observation glass.', 4); }
  }
  if (player.position.z < 28 && !player.cityCleared) {
    player.cityCleared = true;
    setObjective('Follow the forest road to the research facility gate');
    toast('The downtown grid falls behind. Follow the signal through the forest.');
    saveGame(false);
  }
  const eyeHeight = player.crouching ? 1.05 : 1.62;
  const bob = moving ? Math.sin(performance.now() * (player.running ? 0.016 : 0.011)) * (player.running ? 0.055 : 0.025) : 0;
  camera.position.set(player.position.x, eyeHeight + bob, player.position.z);
  camera.rotation.set(player.pitch, player.yaw, 0, 'YXZ');
  flashlight.position.copy(camera.position);
  camera.getWorldDirection(forward); flashlight.target.position.copy(camera.position).addScaledVector(forward, 4);
  flashlight.visible = player.flashlightOn && player.battery > 0;
  if (flashlight.visible) { player.battery = Math.max(0, player.battery - dt * 0.2); if (player.battery === 0) toast('Flashlight battery depleted.'); }
  if (player.battery < 100 && !flashlight.visible) player.battery = Math.min(100, player.battery + dt * 0.018);
  updateHud();
}
const keys = new Set();
window.addEventListener('keydown', (event) => {
  keys.add(event.code);
  if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.code)) event.preventDefault();
  if (event.repeat) return;
  if (event.code === 'Escape') { if (gameState === 'playing') showPause(); else if (gameState === 'paused') resumeGame(); }
  if (event.code === 'KeyE' && gameState === 'playing') { if (player.hidden) interact(hiding); else interact(currentTarget); }
  if (event.code === 'KeyF' && gameState === 'playing' && !player.hidden) { player.flashlightOn = !player.flashlightOn && player.battery > 0; playTone(player.flashlightOn ? 340 : 210, 0.06, 'square', 0.025); }
  if (event.code === 'KeyM' && gameState === 'playing' && player.discovered) toast(`MAP — YOU ARE ${player.position.z > -12 ? 'AT THE ENTRY' : player.position.z > -24 ? 'IN THE FACILITY' : 'NEAR THE EXIT'}.`);
  if (event.code === 'KeyI' && gameState === 'playing') toast(player.inventory.length ? `CARRIED: ${player.inventory.join(' · ')}` : 'INVENTORY EMPTY');
});
window.addEventListener('keyup', (event) => keys.delete(event.code));
window.addEventListener('blur', () => keys.clear());
document.addEventListener('mousemove', (event) => {
  if (gameState !== 'playing' || isTouchDevice() || document.pointerLockElement !== $('world')) return;
  player.yaw -= event.movementX * 0.0024 * sensitivity;
  player.pitch = THREE.MathUtils.clamp(player.pitch - event.movementY * 0.0022 * sensitivity, -1.45, 1.45);
});
document.addEventListener('pointerlockchange', () => {
  if (document.pointerLockElement !== $('world') && gameState === 'playing' && !isTouchDevice()) showPause();
});
$('world').addEventListener('click', () => { if (gameState === 'playing' && !isTouchDevice() && document.pointerLockElement !== $('world')) $('world').requestPointerLock?.(); });

// Mobile stick and camera pad; buttons use pointer events so touch and pen behave alike.
const stick = $('stick'), stickKnob = stick.querySelector('i');
let stickPointer = null, lookPointer = null, lastLook = null;
function setStick(event) {
  const r = stick.getBoundingClientRect(), cx = r.left + r.width / 2, cy = r.top + r.height / 2;
  const dx = event.clientX - cx, dy = event.clientY - cy, max = r.width * 0.34, length = Math.hypot(dx, dy) || 1;
  const scale = Math.min(1, max / length); stickKnob.style.transform = `translate(${dx * scale}px,${dy * scale}px)`;
  moveInput.x = dx * scale / max; moveInput.y = -dy * scale / max;
}
stick.addEventListener('pointerdown', (event) => { stickPointer = event.pointerId; stick.setPointerCapture(event.pointerId); setStick(event); });
stick.addEventListener('pointermove', (event) => { if (event.pointerId === stickPointer) setStick(event); });
function releaseStick(event) { if (event.pointerId !== stickPointer) return; stickPointer = null; moveInput.x = 0; moveInput.y = 0; stickKnob.style.transform = ''; }
stick.addEventListener('pointerup', releaseStick); stick.addEventListener('pointercancel', releaseStick);
const lookPad = $('look-pad');
lookPad.addEventListener('pointerdown', (event) => { lookPointer = event.pointerId; lastLook = [event.clientX, event.clientY]; lookPad.setPointerCapture(event.pointerId); });
lookPad.addEventListener('pointermove', (event) => {
  if (lookPointer !== event.pointerId || !lastLook) return;
  player.yaw -= (event.clientX - lastLook[0]) * 0.006 * sensitivity;
  player.pitch = THREE.MathUtils.clamp(player.pitch - (event.clientY - lastLook[1]) * 0.005 * sensitivity, -1.45, 1.45);
  lastLook = [event.clientX, event.clientY];
});
function releaseLook(event) { if (event.pointerId === lookPointer) { lookPointer = null; lastLook = null; } }
lookPad.addEventListener('pointerup', releaseLook); lookPad.addEventListener('pointercancel', releaseLook);
let canvasLookPointer = null, canvasLookPoint = null;
$('world').addEventListener('pointerdown', (event) => {
  if (gameState !== 'playing' || !isTouchDevice() || event.clientX < innerWidth * 0.38) return;
  canvasLookPointer = event.pointerId; canvasLookPoint = [event.clientX, event.clientY]; $('world').setPointerCapture(event.pointerId);
});
$('world').addEventListener('pointermove', (event) => {
  if (event.pointerId !== canvasLookPointer || !canvasLookPoint) return;
  player.yaw -= (event.clientX - canvasLookPoint[0]) * 0.006 * sensitivity;
  player.pitch = THREE.MathUtils.clamp(player.pitch - (event.clientY - canvasLookPoint[1]) * 0.005 * sensitivity, -1.45, 1.45);
  canvasLookPoint = [event.clientX, event.clientY];
});
const releaseCanvasLook = (event) => { if (event.pointerId === canvasLookPointer) { canvasLookPointer = null; canvasLookPoint = null; } };
$('world').addEventListener('pointerup', releaseCanvasLook); $('world').addEventListener('pointercancel', releaseCanvasLook);
document.querySelectorAll('[data-action]').forEach((button) => {
  const action = button.dataset.action;
  button.addEventListener('pointerdown', (event) => { event.preventDefault(); button.classList.add('active'); if (action === 'run') moveInput.run = true; if (action === 'crouch') moveInput.crouch = true; if (action === 'flashlight') player.flashlightOn = !player.flashlightOn && player.battery > 0; if (action === 'interact') interact(player.hidden ? hiding : currentTarget); });
  const up = () => { button.classList.remove('active'); if (action === 'run') moveInput.run = false; if (action === 'crouch') moveInput.crouch = false; };
  button.addEventListener('pointerup', up); button.addEventListener('pointercancel', up); button.addEventListener('pointerleave', up);
});

function canSeePlayer() {
  if (player.hidden || player.crouching && stalker.position.distanceTo(player.position) > 5.8) return false;
  const toPlayer = new THREE.Vector3(player.position.x - stalker.position.x, 0.9, player.position.z - stalker.position.z);
  const distance = toPlayer.length(); if (distance > 14) return false;
  const facing = new THREE.Vector3(0, 0, -1).applyQuaternion(stalker.quaternion);
  if (facing.angleTo(toPlayer.clone().normalize()) > 1.08 && distance > 3) return false;
  raycaster.set(stalker.position.clone().add(new THREE.Vector3(0, 1.55, 0)), toPlayer.normalize());
  raycaster.far = distance - 0.35;
  const blockers = solids.map((solid) => solid.mesh).filter(Boolean);
  if (raycaster.intersectObjects(blockers, false).length > 0) return false;
  return true;
}
function moveEnemyToward(target, speed, dt) {
  const dx = target.x - stalker.position.x, dz = target.z - stalker.position.z, dist = Math.hypot(dx, dz);
  if (dist < 0.18) return true;
  const step = Math.min(speed * dt, dist);
  const nx = stalker.position.x + dx / dist * step, nz = stalker.position.z + dz / dist * step;
  if (!collides(nx, nz, 0.35)) { stalker.position.x = nx; stalker.position.z = nz; }
  else {
    const alternateX = stalker.position.x + Math.sign(dx) * step;
    const alternateZ = stalker.position.z + Math.sign(dz) * step;
    if (!collides(alternateX, stalker.position.z, 0.35)) stalker.position.x = alternateX;
    else if (!collides(stalker.position.x, alternateZ, 0.35)) stalker.position.z = alternateZ;
  }
  stalker.rotation.y = Math.atan2(-dx, -dz);
  return dist < 0.32;
}
function updateEnemy(dt, time) {
  if (!stalker.visible) return;
  enemy.attackCooldown = Math.max(0, enemy.attackCooldown - dt);
  const distance = stalker.position.distanceTo(player.position);
  if (canSeePlayer()) { enemy.state = 'chase'; enemy.lastKnown.copy(player.position); enemy.alert = 4.5; }
  else if (enemy.alert > 0 && distance < (player.running ? 15 : 7)) { enemy.state = 'investigate'; enemy.lastKnown.copy(player.position); }
  enemy.alert = Math.max(0, enemy.alert - dt);
  if (enemy.state === 'patrol' || enemy.state === 'dormant') {
    const target = enemy.path[enemy.patrolIndex];
    if (moveEnemyToward(target, 0.92, dt)) enemy.patrolIndex = (enemy.patrolIndex + 1) % enemy.path.length;
  } else if (enemy.state === 'investigate' || enemy.state === 'search') {
    const arrived = moveEnemyToward(enemy.lastKnown, enemy.state === 'search' ? 0.86 : 1.12, dt);
    if (arrived) { enemy.state = 'search'; if (enemy.alert <= 0.1) enemy.state = 'patrol'; }
  } else if (enemy.state === 'chase') {
    moveEnemyToward(player.position, 2.7, dt);
    if (distance < 1.28 && enemy.attackCooldown <= 0) { takeDamage(26); enemy.attackCooldown = 1.35; }
    if (distance > 18 || !canSeePlayer() && enemy.alert <= 0) enemy.state = 'search';
  }
  const stride = enemy.state === 'chase' ? 0.019 : 0.011;
  stalker.position.y = Math.abs(Math.sin(time * stride * 55)) * 0.045;
  stalker.children.forEach((child) => { if (child.userData.swing) child.rotation.z = Math.sin(time * stride * 44) * 0.2 * child.userData.swing; });
}
function updateAtmosphere(dt, time) {
  const pos = rain.geometry.attributes.position.array;
  const density = $('rain-quality').value;
  const count = rainCount[density] || rainCount.medium;
  for (let i = 0; i < count; i++) {
    const k = i * 3; pos[k + 1] -= dt * 12.5;
    if (pos[k + 1] < 0) { pos[k + 1] = 13 + ((i * 29) % 90) / 10; pos[k] = player.position.x + ((i * 37) % 300) / 10 - 15; pos[k + 2] = player.position.z + ((i * 53) % 300) / 10 - 15; }
  }
  rain.geometry.attributes.position.needsUpdate = true;
  rain.position.set(0, 0, 0);
  lightningTimer -= dt;
  if (lightningTimer <= 0 && lightningDuration <= 0) { lightningDuration = 0.11; lightningTimer = 13 + Math.random() * 17; moon.intensity = 2.5; playThunder(); }
  if (lightningDuration > 0) { lightningDuration -= dt; if (lightningDuration <= 0) moon.intensity = $('quality').value === 'low' ? 0.5 : 0.7; }
  flashTimer -= dt;
  for (let i = 0; i < lamps.length; i++) {
    const lamp = lamps[i], base = lamp.userData.baseIntensity ?? lamp.intensity;
    const flicker = lamp.name.includes('Faulty') ? 0.78 + 0.22 * Math.max(0, Math.sin(time * 3.2 + i * 5)) : 1;
    lamp.intensity = base * flicker;
  }
  if (attackFlash > 0) attackFlash -= dt;
}
function frame() {
  requestAnimationFrame(frame);
  const dt = Math.min(clock.getDelta(), 0.045), time = clock.elapsedTime;
  if (gameState === 'playing') {
    updatePlayer(dt); updateEnemy(dt, time); updatePrompt(); updateAtmosphere(dt, time);
    interactionCooldown = Math.max(0, interactionCooldown - dt);
    if (toastTimer > 0) { toastTimer -= dt; if (toastTimer <= 0) ui.toast.classList.remove('visible'); }
  } else if (gameState !== 'menu') updateAtmosphere(dt, time);
  if (player.hidden) { camera.position.set(player.position.x, 1.45, player.position.z); camera.rotation.set(player.pitch, player.yaw, 0, 'YXZ'); }
  renderer.render(scene, camera);
}

$('new-game').addEventListener('click', () => startGame(false));
$('continue-game').addEventListener('click', () => startGame(true));
$('open-settings').addEventListener('click', () => { setScreen(ui.settings); gameState = 'settings'; });
$('resume').addEventListener('click', resumeGame);
$('save-exit').addEventListener('click', () => { saveGame(false); gameState = 'menu'; ui.hud.classList.add('hidden'); setScreen(ui.start); });
$('settings-back').addEventListener('click', () => { saveSettings(); setScreen(ui.start); gameState = 'menu'; });
$('close-note').addEventListener('click', closeNote);
$('note-screen').addEventListener('click', (event) => { if (event.target === ui.note) closeNote(); });
$('end-menu').addEventListener('click', () => { gameState = 'menu'; ui.hud.classList.add('hidden'); setScreen(ui.start); });
$('quality').addEventListener('change', () => { applyQuality($('quality').value); saveSettings(); });
$('rain-quality').addEventListener('change', () => { applyRain($('rain-quality').value); saveSettings(); });
$('sensitivity').addEventListener('input', saveSettings);
$('volume').addEventListener('input', () => { setVolume(Number($('volume').value)); saveSettings(); });
window.addEventListener('resize', () => { camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix(); renderer.setSize(innerWidth, innerHeight); applyQuality($('quality').value); });
window.addEventListener('beforeunload', () => { if (gameState === 'playing') saveGame(false); });

loadSettings();
camera.position.copy(player.position).add(new THREE.Vector3(0, 1.62, 0));
camera.rotation.set(0, player.yaw, 0);
updateHud();
requestAnimationFrame(() => ui.loading.classList.add('done'));
setTimeout(() => ui.loading.remove(), 800);
frame();
