// AnotherBars mockups: the approved action button (mockup 4, variant A, skin
// border; proc glow 1, gold pulse), taken unchanged from 4-buttons.html so
// the new pages draw exactly the approved look. Added: o.rad (CSS
// border-radius override, for buttons that sit in a row at padding 0).
/* eslint-disable */
const { C, css, sc, mix } = K;
const EDGES = { thin: [0.2, 1], bevel: [0.2, 1.7, 1, 1, 0.2], gilded: [0.2, 1.7, 0.2, 0.2, 1.7, 0.2] };
function edgeList(skin, mode) {
  if (mode === 'slim') return [0.2, 1];
  const b = K.SKINS[skin].border;
  return b === 'round' ? [0.35, 1, 1] : EDGES[b];
}
const ICONS = [
  [28, 'circle at 45% 40%'], [200, 'circle at 50% 30%'], [0, 'circle at 40% 45%'], [280, 'circle at 55% 40%'],
  [120, 'circle at 45% 55%'], [45, 'circle at 50% 50%'], [180, 'circle at 35% 35%'], [330, 'circle at 60% 45%'],
];
function iconBg(i) {
  const [h, at] = ICONS[i % ICONS.length];
  return `radial-gradient(${at}, hsl(${h},90%,85%) 0 8%, hsl(${h},80%,55%) 30%, hsl(${h + 20},70%,28%) 65%, hsl(${h + 30},60%,10%) 100%)`;
}
// One button. o: {i, key, count, macro, state: normal|range|mana|unusable|cd|hover|pressed|active|empty, cd, glow}
function button(skin, x, y, s, o, mode = 'skin') {
  const sk = K.SKINS[skin];
  const list = edgeList(skin, mode);
  const e = list.length;
  const hover = o.state === 'hover';
  const ec = hover ? C.goldLine : C.border;
  const r = sk.border === 'round' && mode === 'skin' ? 4 : 0;
  let shadow = list.map((k, i) => `inset 0 0 0 ${i + 1}px ${css(sc(ec, k))}`).join(', ');
  let html = '';
  // icon
  const ins = e;
  let filter = '', tint = '';
  if (o.state === 'range') tint = 'rgba(204,26,26,.62)';
  if (o.state === 'mana') tint = 'rgba(80,80,255,.5)';
  if (o.state === 'unusable') filter = 'filter:grayscale(1) brightness(.55);';
  if (o.state === 'pressed') filter = 'filter:brightness(.7);';
  if (o.state !== 'empty') {
    html += `<i class="icon" style="left:${ins}px;top:${ins}px;width:${s - 2 * ins}px;height:${s - 2 * ins}px;background:${iconBg(o.i)};${filter}"></i>`;
    if (tint) html += `<i class="abs" style="left:${ins}px;top:${ins}px;width:${s - 2 * ins}px;height:${s - 2 * ins}px;background:${tint};mix-blend-mode:multiply"></i>`;
  } else {
    html += `<i class="abs" style="left:${ins}px;top:${ins}px;width:${s - 2 * ins}px;height:${s - 2 * ins}px;background:${css(C.panel, .75)};box-shadow:inset 0 0 6px rgba(0,0,0,.8)"></i>`;
  }
  if (o.state === 'cd') {
    const deg = Math.round((o.cdv || 0.6) * 360);
    html += `<i class="abs" style="left:${ins}px;top:${ins}px;width:${s - 2 * ins}px;height:${s - 2 * ins}px;background:conic-gradient(rgba(0,0,0,.72) 0 ${deg}deg, transparent ${deg}deg)"></i>`;
    html += `<span class="txt" style="left:${s / 2}px;top:${s / 2 - 9}px;transform:translateX(-50%);font-size:15px;color:${css(C.gold)}">${o.cd}</span>`;
  }
  // the button style's inner shading (Buttons pick)
  const inner = `${ins}px`;
  if (sk.buttons === 'raised') {
    html += `<i class="abs" style="left:${inner};top:${inner};right:${inner};bottom:${inner};box-shadow:inset 1px 1px 0 ${css(sc(C.border, 1.9), .8)}, inset -1px -1px 0 ${css(sc(C.border, 0.25), .9)}"></i>`;
  } else if (sk.buttons === 'bronze') {
    html += `<i class="abs" style="left:${inner};top:${inner};right:${inner};bottom:${inner};box-shadow:inset 0 0 0 1px ${css(sc(C.border, 0.3), .85)}, inset 0 8px 8px -6px rgba(255,220,160,.18)"></i>`;
  }
  if (o.state === 'active') {
    html += `<i class="abs" style="left:${inner};top:${inner};right:${inner};bottom:${inner};box-shadow:inset 0 0 0 2px ${css(C.gold)}, inset 0 0 6px 1px ${css(C.gold, .6)}"></i>`;
  }
  if (hover) html += `<i class="abs" style="left:${inner};top:${inner};right:${inner};bottom:${inner};background:rgba(255,230,150,.16)"></i>`;
  // texts
  const keyCol = o.state === 'range' ? 'color:#ff3a2a;' : '';
  if (o.key) html += `<span class="txt" style="right:${ins + 1}px;top:${ins}px;font-size:10px;${keyCol}">${o.key}</span>`;
  if (o.count) html += `<span class="txt" style="right:${ins + 1}px;bottom:${ins - 1}px;font-size:12px">${o.count}</span>`;
  if (o.macro) html += `<span class="txt" style="left:${ins}px;right:${ins}px;bottom:${ins}px;text-align:center;font-size:9px;color:${css([0.93, 0.87, 0.72])};overflow:hidden">${o.macro}</span>`;
  const frame = `<div class="abs" style="left:0;top:0;width:${s}px;height:${s}px;border-radius:${o.rad != null ? o.rad : r + 'px'};background:${css(C.panel)};box-shadow:${shadow}, 0 1px 2px rgba(0,0,0,.6)"></div>`;
  const glow = o.glow ? procGlow(o.glow, s, r) : '';
  let studs = '';
  if (sk.border === 'gilded' && mode === 'skin' && o.studs) studs = K.stud(1, 1, 7) + K.stud(s - 1, 1, 7) + K.stud(1, s - 1, 7) + K.stud(s - 1, s - 1, 7);
  return `<div class="unit" style="left:${x}px;top:${y}px;width:${s}px;height:${s}px">${glow}${frame}<div class="abs" style="left:0;top:0;width:${s}px;height:${s}px;overflow:hidden;border-radius:${o.rad != null ? o.rad : r + 'px'}">${html}</div>${studs}${o.glow === 'flare' ? flareCorners(s) : ''}</div>`;
}
// Proc glow variants (all in AnotherLedger gold).
function procGlow(kind, s, r) {
  const g = C.goldLine;
  if (kind === 'pulse') {
    return `<i class="abs pulse" style="left:-5px;top:-5px;width:${s + 10}px;height:${s + 10}px;border-radius:${r + 5}px;box-shadow:0 0 0 2px ${css(g)}, 0 0 10px 4px ${css(g, .75)}, inset 0 0 8px 2px ${css(g, .6)}"></i>`;
  }
  if (kind === 'ants') {
    return `<div class="abs ants" style="left:-3px;top:-3px;width:${s + 6}px;height:${s + 6}px;border-radius:${r + 3}px;box-shadow:0 0 8px 2px ${css(g, .55)}"><i style="background:repeating-conic-gradient(${css(g)} 0 12deg, rgba(120,70,0,.9) 12deg 24deg)"></i><b class="abs" style="left:3px;top:3px;right:3px;bottom:3px;background:#000;border-radius:${r}px"></b></div>`;
  }
  return `<i class="abs flare" style="left:-2px;top:-2px;width:${s + 4}px;height:${s + 4}px;border-radius:${r + 2}px;box-shadow:0 0 12px 3px ${css(g, .55)}"></i>`;
}
function flareCorners(s) {
  const g = css(C.gold), L = 12;
  const c = (x, y, bx, by) => `<i class="abs flare" style="left:${x}px;top:${y}px;width:${L}px;height:${L}px;border-${by}:3px solid ${g};border-${bx}:3px solid ${g};filter:drop-shadow(0 0 3px ${css(C.goldLine)})"></i>`;
  return c(-3, -3, 'left', 'top') + c(s - L + 3, -3, 'right', 'top') + c(-3, s - L + 3, 'left', 'bottom') + c(s - L + 3, s - L + 3, 'right', 'bottom');
}
