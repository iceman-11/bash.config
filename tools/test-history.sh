#!/usr/bin/env bash
################################################################################
#
# Tests for the history clean-up (__cleanup_history in plugin/history.bash),
# run on sample history files in a temporary directory.
#
# Usage: tools/test-history.sh [path/to/bash]
#
################################################################################

set -uo pipefail

BASH_BIN=${1:-bash}
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
status=0

# shellcheck disable=SC2016
echo "== $("$BASH_BIN" -c 'echo "bash $BASH_VERSION"') on $(uname -s)"

# Run __cleanup_history from the plugin on file $1; extra VAR=value in $2...
run_cleanup() {
	local file=$1
	shift
	# shellcheck disable=SC2016
	env "$@" HISTFILE="$file" REPO="$REPO" "$BASH_BIN" --norc -c '
		eval "$(sed -n "/^__cleanup_history()/,/^}/p" "$REPO/plugin/history.bash")"
		__cleanup_history'
}

# check NAME ACTUAL EXPECTED
check() {
	if diff -u "$3" "$2" > "$work/diff"; then
		echo "ok   $1"
	else
		echo "FAIL $1"
		sed 's/^/     /' "$work/diff"
		status=1
	fi
}

# Duplicates are removed by entry: multi-line commands stay whole ##############

cat > "$work/multi" <<'EOF'
#1001
echo a
#1002
for i in 1
do echo $i
done
#1003
if true
then echo x
fi
#1004
echo a
#1005
for j in 2
do echo $j
done
#1006
if true
then echo x
fi
EOF
cat > "$work/multi.expected" <<'EOF'
#1002
for i in 1
do echo $i
done
#1004
echo a
#1005
for j in 2
do echo $j
done
#1006
if true
then echo x
fi
EOF
run_cleanup "$work/multi"
check "multi-line entries stay whole; newest duplicate kept" "$work/multi" "$work/multi.expected"

# Lines without a timestamp (older history) are one entry each ################

cat > "$work/legacy" <<'EOF'
ls

cd /tmp
ls
git status
#1010
git status
#1011
make
EOF
cat > "$work/legacy.expected" <<'EOF'
cd /tmp
ls
#1010
git status
#1011
make
EOF
run_cleanup "$work/legacy"
check "lines without timestamp; empty lines dropped" "$work/legacy" "$work/legacy.expected"

# Lines appended by another shell during the clean-up are kept ################

# An awk that, once done, appends to the history file like another shell's
# 'history -a' would, before the clean-up writes its result
mkdir "$work/shim"
cat > "$work/shim/awk" <<'EOF'
#!/bin/sh
"$REAL_AWK" "$@"
rc=$?
printf '#1099\nconcurrent command\n' >> "$HISTFILE"
exit $rc
EOF
chmod +x "$work/shim/awk"

printf '#1020\necho a\n#1021\necho a\n' > "$work/concurrent"
printf '#1021\necho a\n#1099\nconcurrent command\n' > "$work/concurrent.expected"
run_cleanup "$work/concurrent" PATH="$work/shim:$PATH" REAL_AWK="$(type -P awk)"
check "lines appended during the clean-up are kept" "$work/concurrent" "$work/concurrent.expected"

# A symbolic link stays a link (e.g. history kept in a synced folder). Git
# Bash only creates a real link when asked to (MSYS=winsymlinks:nativestrict)

printf '#1030\necho b\n#1031\necho b\n' > "$work/real"
printf '#1031\necho b\n' > "$work/real.expected"
if MSYS=winsymlinks:nativestrict ln -s "$work/real" "$work/link" 2> /dev/null && [[ -L $work/link ]]; then
	run_cleanup "$work/link"
	if [[ -L $work/link ]]; then
		check "symbolic link kept, target cleaned" "$work/real" "$work/real.expected"
	else
		echo "FAIL symbolic link replaced by a regular file"
		status=1
	fi
else
	echo "skip symbolic link (ln -s does not create links here)"
fi

(( status == 0 )) && echo "OK"
exit $status
