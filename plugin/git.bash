# Git

if ! type git > /dev/null 2>&1; then
	return
fi

alias glog='git log --graph --oneline --all'

# Delete local branches whose upstream is gone (e.g. deleted after a merge).
# Uses for-each-ref instead of parsing "git branch -vv", and a read loop
# instead of "xargs -r" (GNU only), so it behaves the same on Linux, macOS
# and Git Bash. The current branch is never touched.
#   gbgone          safe delete (git branch -d), keeps unmerged branches
#   gbgone --force  delete even if unmerged (git branch -D)
gbgone() {
	local flag=-d branch upstream current
	case ${1-} in
	-f | --force) flag=-D ;;
	'') ;;
	*)
		echo "usage: gbgone [-f|--force]" >&2
		return 2
		;;
	esac

	current=$(git symbolic-ref --short -q HEAD)

	while read -r branch upstream; do
		[[ $branch == "$current" ]] && continue
		[[ $upstream == '[gone]' ]] || continue
		git branch "$flag" -- "$branch"
	done < <(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads)
}

# __git_ps1 (branch in the fallback prompt, see prompt.bash) comes from
# git-prompt.sh, which only some systems load by themselves (Git Bash does);
# its location depends on the distribution
if ! declare -F __git_ps1 > /dev/null; then
	for __git_prompt in \
		/usr/lib/git-core/git-sh-prompt \
		/usr/share/git-core/contrib/completion/git-prompt.sh \
		/usr/share/git/completion/git-prompt.sh \
		/mingw64/share/git/completion/git-prompt.sh; do
		if [[ -r $__git_prompt ]]; then
			# shellcheck source=/dev/null
			. "$__git_prompt"
			break
		fi
	done
	unset __git_prompt
fi
