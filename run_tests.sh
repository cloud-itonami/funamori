#!/usr/bin/env bash
# funamori 舫 — run the cljc test suite with one command (babashka).
# Pure-Clojure (.cljc) methods; the repo pytest env is irrelevant here.
set -uo pipefail
cd "$(dirname "$0")"

if ! command -v bb >/dev/null 2>&1; then
  echo "babashka (bb) not found — install: brew install borkdude/brew/babashka"; exit 127
fi

# west keeps actor repositories as flat siblings.  The hikari repository owns
# the shared kuni-umi robotics substrate required by stack_robotics.
HIKARI_ROOT="${FUNAMORI_HIKARI_ROOT:-../com-etzhayyim-hikari}"
if [ ! -f "$HIKARI_ROOT/methods/substrate.cljc" ]; then
  echo "com-etzhayyim-hikari sibling not found (set FUNAMORI_HIKARI_ROOT)"; exit 2
fi

# hikari predates the src/ convention. Build a temporary classpath alias without
# copying or vendoring its source into this actor repository.
FUNAMORI_CP="$(mktemp -d)"
trap 'rm -rf "$FUNAMORI_CP"' EXIT
ln -s "$HIKARI_ROOT" "$FUNAMORI_CP/hikari"
bb -cp "src:test:$FUNAMORI_CP" -e "(require '[clojure.test :as t]
                       'funamori.methods.test-salinity-gradient
                       'funamori.methods.test-stack-robotics
                       'funamori.methods.test-plant
                       'funamori.cells.test-cells)
              (let [r (t/run-tests 'funamori.methods.test-salinity-gradient
                                   'funamori.methods.test-stack-robotics
                                   'funamori.methods.test-plant
                                   'funamori.cells.test-cells)]
                (when (or (pos? (:fail r)) (pos? (:error r))) (System/exit 1)))"

if [ $? -eq 0 ]; then
  echo "── funamori: ALL cljc suites green ──"
else
  echo "── funamori: FAILURES above ──"; exit 1
fi
