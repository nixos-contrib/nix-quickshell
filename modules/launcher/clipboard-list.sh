#!/bin/sh
# The clipboard history for the launcher, from the store of clipmenud: a folder in the runtime directory (memory, it goes with the
# session) with `line_cache`, a line for each copy as "<time in ns> <first line>", and a file with what was copied, named by the
# checksum of that first line. It prints, newest first and once for each first line, the folder, the time, the file and the first
# line, separated by tabs. The text is not read here, only when a copy is chosen. Nothing is printed without clipmenud
tab="$(printf '\t')"
for d in "${XDG_RUNTIME_DIR:-/tmp}"/clipmenu.*."$USER"; do
	[ -f "$d/line_cache" ] || continue
	tail -n 300 "$d/line_cache" | tac | while IFS= read -r l; do
		t="${l%% *}"
		f="${l#* }"
		printf '%s\t%s\t%s\t%s\n' "$d" "$t" "$(printf '%s\n' "$f" | cksum | cut -d' ' -f1,2)" "$f"
	done | awk -F"$tab" '!seen[$4]++' | head -n 100
	break
done
