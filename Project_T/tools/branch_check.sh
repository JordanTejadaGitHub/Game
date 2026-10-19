#!/bin/bash
# The branch check (Balancing Discussion, owner 2026-10-18): every regular branch of the four starting families, as the
# first pick with --spend-all, on the opening test's maps, to the end of drift 25; then the report (tools/branch_check.gd).
# On demand only (not a suite test). Runs in a detached worktree of a fixed commit so other chats' edits on main can't
# change it mid-batch; user:// stays on D: (APPDATA). PARALLEL runs at once (2: the owner may be playing).
# Usage: bash tools/branch_check.sh [commit, default HEAD]
# Output: D:/Projects/logs/balancing/branch_check/<date>/ (a log per run) and D:/Projects/logs/balancing/branch_check_<date>.md
set -u
COMMIT=${1:-HEAD}
PARALLEL=${PARALLEL:-2}
G="D:/Program Files/Git/cmd/git.exe"
GD="D:/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe"
export APPDATA='D:/Projects/logs/balancing/userdata'
DATE=$(date +%Y-%m-%d)
OUT="D:/Projects/logs/balancing/branch_check/$DATE"
W="D:/Projects/worktrees/bal_branch_check"
mkdir -p "$OUT"
HASH=$("$G" -C D:/Projects/Game rev-parse --short "$COMMIT")
[ -d "$W" ] && "$G" -C D:/Projects/Game worktree remove --force "$W"  # A fresh checkout of this commit every time
"$G" -C D:/Projects/Game worktree add -q --detach "$W" "$HASH" || { echo "worktree failed"; exit 1; }
timeout 1800 "$GD" --headless --path "$W/Project_T" --import > "$OUT/import.log" 2>&1
echo "commit $HASH" > "$OUT/build.txt"
timeout 600 "$GD" --headless --path "$W/Project_T" --script res://tools/branch_check.gd -- --list 2>/dev/null | grep '^BRANCH ' > "$OUT/branches.txt"
[ -s "$OUT/branches.txt" ] || { echo "no branches listed (import incomplete?)"; exit 1; }
> "$OUT/jobs.txt"
while read -r _ family branch; do
	for seed in 1207 4242 90210; do
		echo "$family $branch $seed" >> "$OUT/jobs.txt"
	done
done < "$OUT/branches.txt"
run_one() {
	local family=$1 branch=$2 seed=$3
	local log="$OUT/${family}_${branch}_${seed}.log"
	[ -f "$log" ] && grep -q '^RUN ' "$log" && return 0  # Done already (a rerun only fills gaps)
	timeout 2400 "$GD" --headless --path "$W/Project_T" --script res://tools/balance_sim.gd --fixed-fps 60 -- \
		--seed=$seed --profile=fresh --style=balanced --last=25 --families=$family --branch=$branch --spend-all \
		--out="$OUT/csv_${family}_${branch}" > "$log" 2>&1
}
export -f run_one
export OUT W GD
xargs -P "$PARALLEL" -L 1 bash -c 'run_one $0 $1 $2' < "$OUT/jobs.txt"
"$GD" --headless --path "$W/Project_T" --script res://tools/branch_check.gd -- --report="$OUT" \
	--md="D:/Projects/logs/balancing/branch_check_$DATE.md" > "$OUT/report.log" 2>&1
"$G" -C D:/Projects/Game worktree remove --force "$W"
echo DONE > "$OUT/done.txt"
