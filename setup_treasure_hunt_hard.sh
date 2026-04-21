#!/bin/bash

# ============================================================
#  BASH TREASURE HUNT — HARD MODE (Randomised Tree)
#  Harder than v2: deeper tree, wider branching, rarer real treasure
#  Max depth: 6 levels
# ============================================================

BASE="treasure_hunt_hard"
# Real passphrase split: treasure_part1.txt and treasure_part2.txt in two different directories.
TREASURE_FILE_DECOY="treasure.txt"
TREASURE_FILE_PART1="treasure_part1.txt"
TREASURE_FILE_PART2="treasure_part2.txt"
TREASURE_PART1="R3D"
TREASURE_PART2="H4T"
# Chance each directory gets a decoy treasure.txt (6/10 = 60%).
DECOY_TREASURE_P=6

rm -rf "$BASE"
mkdir -p "$BASE"

FAKE_MSGS=(
  "Nope, keep looking!"
  "So close... or are you?"
  "This is not the treasure."
  "Nice try, pirate."
  "Wrong chest, matey!"
  "The treasure is elsewhere..."
  "You found nothing but dust."
  "A dead end. Turn back!"
  "Almost! (not really)"
  "This ain't it chief."
  "Cold... very cold."
  "The real treasure was the friends we made along the way. (It wasn't.)"
  "Still searching? Good."
  "Empty. Like your hopes."
  "Not here. Never was."
  "Try another branch."
  "The map lied."
  "X does not mark this spot."
  "Keep drilling."
  "Another fake. Surprise!"
  "Your cat would find this faster."
  "Legend says the treasure is real. This file says otherwise."
)

FOLDER_NAMES=(
  cave cavern cove cliff hollow tunnel grotto lagoon marsh reef
  shipwreck ruins fortress dungeon tower vault cellar attic barn
  jungle swamp tundra canyon plateau ridge crater basin delta
  alley dock warehouse sewer rooftop courtyard chapel library
  catacomb crypt ossuary sepulcher mausoleum bunker silo shaft
  grotto_lower grotto_upper passage antechamber annex wing
  cellar_old cellar_new pier jetty breakwater lighthouse beacon
  thicket glade fen moor heath barrow mound tumulus
)

fake() {
  echo "${FAKE_MSGS[$((RANDOM % ${#FAKE_MSGS[@]}))]}" > "$1"
}

pick_name() {
  echo "${FOLDER_NAMES[$((RANDOM % ${#FOLDER_NAMES[@]}))]}"
}

# First path segment under BASE, e.g. treasure_hunt_hard/island/a -> island
top_region() {
  local rel="${1#${BASE}/}"
  rel="${rel%%/*}"
  echo "$rel"
}

# ============================================================
# RECURSIVE BUILDER
# build_dir <path> <current_depth> <max_depth>
# Part 1 only here; part 2 is placed afterward in a different top-level region.
# ============================================================
PART1_PLACED=0
TREASURE_PART1_PATH=""

build_dir() {
  local path="$1"
  local depth="$2"
  local max_depth="$3"

  local place_real=0
  # Real part 1 only from depth >= 3 (part 2 placed later, far from part 1)
  if [[ $PART1_PLACED -eq 0 && $depth -ge 3 ]]; then
    if [[ $depth -eq $max_depth ]]; then
      place_real=1
    elif [[ $((RANDOM % 8)) -eq 0 ]]; then
      place_real=1
    fi
  fi

  if [[ $place_real -eq 1 ]]; then
    echo "$TREASURE_PART1" > "$path/$TREASURE_FILE_PART1"
    PART1_PLACED=1
    TREASURE_PART1_PATH="$path"
  fi

  if [[ $((RANDOM % 10)) -lt $DECOY_TREASURE_P ]]; then
    fake "$path/$TREASURE_FILE_DECOY"
  fi

  if [[ $depth -ge $max_depth ]]; then
    return
  fi

  # Harder: 2–5 subdirs per level (wider tree)
  local num_dirs=$(( (RANDOM % 4) + 2 ))
  for ((i=0; i<num_dirs; i++)); do
    local subdir_name
    subdir_name=$(pick_name)
    local subdir_path="$path/${subdir_name}_${i}"
    mkdir -p "$subdir_path"
    build_dir "$subdir_path" $((depth + 1)) "$max_depth"
  done
}

# ============================================================
# ROOT — more entry points than v2
# ============================================================
ROOT_DIRS=("island" "forest" "ship" "village" "swamp" "mountain" "desert" "reef")

for dir in "${ROOT_DIRS[@]}"; do
  mkdir -p "$BASE/$dir"
  build_dir "$BASE/$dir" 1 6
done

# Place part 2 in a random directory that is not under the same top-level region as part 1
# (island / forest / ship / …) so the two halves are geographically separated.
place_part2_separated() {
  [[ -z "$TREASURE_PART1_PATH" ]] && return 1
  local r1
  r1=$(top_region "$TREASURE_PART1_PATH")
  local candidates=()
  local d
  while IFS= read -r d; do
    [[ "$d" == "$TREASURE_PART1_PATH" ]] && continue
    [[ $(top_region "$d") != "$r1" ]] || continue
    candidates+=("$d")
  done < <(find "$BASE" -mindepth 4 -type d)

  if [[ ${#candidates[@]} -eq 0 ]]; then
    while IFS= read -r d; do
      [[ "$d" == "$TREASURE_PART1_PATH" ]] && continue
      candidates+=("$d")
    done < <(find "$BASE" -mindepth 4 -type d)
  fi

  [[ ${#candidates[@]} -eq 0 ]] && return 1
  d="${candidates[$((RANDOM % ${#candidates[@]}))]}"
  echo "$TREASURE_PART2" > "$d/$TREASURE_FILE_PART2"
}

if [[ $PART1_PLACED -eq 0 ]]; then
  deepest=""
  max_slashes=-1
  while IFS= read -r f; do
    slashes="${f//[^\/]/}"
    n=${#slashes}
    if (( n > max_slashes )); then
      max_slashes=$n
      deepest=$f
    fi
  done < <(find "$BASE" -name "$TREASURE_FILE_DECOY" -type f)
  if [[ -n "$deepest" ]]; then
    win_dir=$(dirname "$deepest")
    echo "$TREASURE_PART1" > "$win_dir/$TREASURE_FILE_PART1"
    PART1_PLACED=1
    TREASURE_PART1_PATH="$win_dir"
  fi
fi

place_part2_separated

cat > "$BASE/README.txt" << 'EOF'
🏴‍☠️  BASH TREASURE HUNT — HARD MODE  🏴‍☠️

Your mission: find the two folders that hold the real passphrase. One folder
contains treasure_part1.txt (first half); a different folder contains
treasure_part2.txt (second half)—they are not in the same top-level area
(island, forest, ship, …). Many folders have treasure.txt as a decoy,
but not all (~60%). There are many decoys. The tree is deep and wide.

COMMANDS YOU'LL NEED:
  ls          — list what's in the current folder
  cd <folder> — move into a folder
  cd ..       — go back up one folder
  cat <file>  — read a file

Tips: find and grep are fair game if you know them.

Start by running:   ls

Good luck. You will need it.
EOF

echo "✅  Hard treasure hunt created in ./$BASE/"