#!/bin/bash

# ============================================================
#  BASH TREASURE HUNT v2 — Randomised Tree
#  Each directory gets 1-3 random subdirs, recursively
#  Max depth: 4 levels (keeps it manageable for students)
# ============================================================

BASE="treasure_hunt"
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
)

FOLDER_NAMES=(
  cave cavern cove cliff hollow tunnel grotto lagoon marsh reef
  shipwreck ruins fortress dungeon tower vault cellar attic barn
  jungle swamp tundra canyon plateau ridge crater basin delta
  alley dock warehouse sewer rooftop courtyard chapel library
)

fake() {
  echo "${FAKE_MSGS[$((RANDOM % ${#FAKE_MSGS[@]}))]}" > "$1"
}

# Random folder name; sibling dirs are distinguished by _${i} in the caller
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

  # Always place a treasure.txt in this dir (real or fake)
  # Real one placed exactly once, randomly, at depth >= 2
  local place_real=0
  if [[ $TREASURE_PLACED -eq 0 && $depth -ge 2 ]]; then
    # 1-in-4 chance per eligible dir; guaranteed on last level
    if [[ $depth -eq $max_depth || $((RANDOM % 4)) -eq 0 ]]; then
      place_real=1
    fi
  fi

  if [[ $place_real -eq 1 ]]; then
    echo "You found it! The password is: B4SH" > "$path/treasure.txt"
    TREASURE_PLACED=1
  else
    fake "$path/treasure.txt"
  fi

  # Stop recursing at max depth
  if [[ $depth -ge $max_depth ]]; then
    return
  fi

  # Create 1-3 random subdirs
  local num_dirs=$(( (RANDOM % 3) + 1 ))
  for ((i=0; i<num_dirs; i++)); do
    local subdir_name
    subdir_name=$(pick_name)
    # Append index to avoid sibling collisions
    local subdir_path="$path/${subdir_name}_${i}"
    mkdir -p "$subdir_path"
    build_dir "$subdir_path" $((depth + 1)) "$max_depth"
  done
}

# ============================================================
# ROOT — same 5 themed dirs as before
# ============================================================
ROOT_DIRS=("island" "forest" "ship" "village" "swamp")

for dir in "${ROOT_DIRS[@]}"; do
  mkdir -p "$BASE/$dir"
  build_dir "$BASE/$dir" 1 4
done

# Safety net: if treasure was never placed (rare), overwrite one at max path depth
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
    echo "You found it! The password is: B4SH" > "$deepest"
  fi
fi

# ============================================================
# README at root
# ============================================================
cat > "$BASE/README.txt" << 'EOF'
🏴‍☠️  WELCOME TO THE BASH TREASURE HUNT  🏴‍☠️

Your mission: find the ONE treasure.txt that contains the secret phrase.

COMMANDS YOU'LL NEED:
  ls          — list what's in the current folder
  cd <folder> — move into a folder
  cd ..       — go back up one folder
  cat <file>  — read a file

Start by running:   ls

Good luck, pirate. The treasure is buried deep...
EOF

echo "✅  Treasure hunt created in ./$BASE/"
echo "    The winning phrase is: B4SH"
echo ""
echo "🗺  Tree preview:"
find "$BASE" -name "treasure.txt" | sort
