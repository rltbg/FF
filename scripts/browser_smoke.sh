#!/usr/bin/env bash
# Test de fumée de la tête NAVIGATEUR (WebAssembly) dans le Chromium de Playwright (rendu WebGL logiciel SwiftShader) :
# la page se charge, un <canvas> est créé, aucune erreur de page ; un clic sur « + » change l'image (le modèle F* a réagi).
# Pas d'oracle sur l'état du modèle (le journal MVU_TRACE n'existe pas dans un navigateur) : le test est plus faible que ui_smoke.sh.
# prérequis : scripts/platforms.sh browser ; node + paquet playwright (préinstallés dans cet environnement) ; sauté sinon (code 3).
set -uo pipefail
source "$(dirname "$0")/env.sh"
W="$ROOT/out/platforms/browser/wwwroot"; S="$ROOT/shots/browser"; mkdir -p "$S"
[ -f "$W/index.html" ] || { echo "SAUTÉ : lancer scripts/platforms.sh browser"; exit 3; }
command -v node >/dev/null && NODE_PATH=$(npm root -g 2>/dev/null) node -e "require('playwright')" 2>/dev/null || { echo "SAUTÉ : node + playwright absents"; exit 3; }
PORT=$((20000 + RANDOM % 10000))
python3 -m http.server $PORT --directory "$W" > "$S/http.log" 2>&1 & H=$!
trap 'kill $H 2>/dev/null' EXIT
cat > "$S/smoke.js" <<JS
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const p = await b.newPage({ viewport: { width: 520, height: 600 } });
  const errs = [];
  p.on('pageerror', e => errs.push(e.message));
  p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await p.goto('http://localhost:$PORT/index.html');
  await p.waitForSelector('canvas', { timeout: 60000 });
  await p.waitForTimeout(8000);
  const a = await p.screenshot({ path: '$S/0_init.png' });
  await p.mouse.click(64, 127); await p.waitForTimeout(500); await p.mouse.click(64, 127); await p.waitForTimeout(1000);
  const c = await p.screenshot({ path: '$S/1_apres_clics.png' });
  const fs = require('fs'); const crypto = require('crypto');
  const h = x => crypto.createHash('sha1').update(x).digest('hex');
  console.log('canvas=1 erreurs=' + errs.length + (errs.length ? ' : ' + errs.slice(0, 3).join(' | ') : ''));
  console.log(h(a) !== h(c) ? 'image modifiée par les clics : OK' : 'image IDENTIQUE après les clics : KO');
  await b.close();
  process.exit(errs.length === 0 && h(a) !== h(c) ? 0 : 1);
})();
JS
cd "$S" && NODE_PATH=$(npm root -g) timeout 180 node smoke.js; rc=$?
[ $rc -eq 0 ] && echo "BROWSER SMOKE OK" || echo "BROWSER SMOKE KO (code $rc)"; exit $rc
