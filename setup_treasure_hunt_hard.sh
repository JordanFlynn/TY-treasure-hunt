#!/bin/bash

# ============================================================
#  BASH TREASURE HUNT — HARD MODE (Randomised Tree)
#  Harder than v2: deeper tree, wider branching, rarer real treasure
#  Max depth: 6 levels
# ============================================================

BASE="treasure_hunt_hard"
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

# ============================================================
# RECURSIVE BUILDER
# build_dir <path> <current_depth> <max_depth>
# ============================================================
TREASURE_PLACED=0

build_dir() {
  local path="$1"
  local depth="$2"
  local max_depth="$3"

  local place_real=0
  # Harder: real treasure only from depth >= 3, lower odds until max depth
  if [[ $TREASURE_PLACED -eq 0 && $depth -ge 3 ]]; then
    if [[ $depth -eq $max_depth ]]; then
      place_real=1
    elif [[ $((RANDOM % 8)) -eq 0 ]]; then
      place_real=1
    fi
  fi

  if [[ $place_real -eq 1 ]]; then
    echo "You found it! The password is: SH3LL" > "$path/treasure.txt"
    TREASURE_PLACED=1
  else
    fake "$path/treasure.txt"
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

if [[ $TREASURE_PLACED -eq 0 ]]; then
  deepest=""
  max_slashes=-1
  while IFS= read -r f; do
    slashes="${f//[^\/]/}"
    n=${#slashes}
    if (( n > max_slashes )); then
      max_slashes=$n
      deepest=$f
    fi
  done < <(find "$BASE" -name "treasure.txt")
  if [[ -n "$deepest" ]]; then
    echo "You found it! The password is: SH3LL" > "$deepest"
  fi
fi

cat > "$BASE/README.txt" << 'EOF'
🏴‍☠️  BASH TREASURE HUNT — HARD MODE  🏴‍☠️

Your mission: find the ONE treasure.txt that contains the secret phrase.
There are many decoys. The tree is deep and wide.

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
echo "    The winning phrase is: SH3LL"
