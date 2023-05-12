################################################################################
#
# PROGRAMMABLE COMPLETION - ONLY SINCE BASH-2.04
# (Most are taken from the bash 2.05 documentation)
# You will in fact need bash-2.05 for some features
#
################################################################################

if [ "${BASH_VERSION%.*}" \< "2.05" ]; then
	echo "You will need to upgrade to version 2.05 for programmable completion"
	return
fi

shopt -s extglob        # necessary
set +o nounset		# otherwise some completions will fail

complete -A hostname   rsh rcp telnet rlogin r ftp ping disk
complete -A command    nohup exec eval trace gdb
complete -A command    command type which
complete -A export     printenv
complete -A variable   export local readonly unset
complete -A enabled    builtin
complete -A alias      alias unalias
complete -A function   function
complete -A user       su mail finger

complete -A helptopic  help     # currently same as builtins
complete -A shopt      shopt
complete -A stopped -P '%' bg
complete -A job -P '%'     fg jobs disown

complete -A directory  mkdir rmdir
complete -A directory   -o default cd

complete -f -d -X '*.gz'  gzip
complete -f -d -X '*.bz2' bzip2
complete -f -o default -X '!*.gz'  gunzip
complete -f -o default -X '!*.bz2' bunzip2
complete -f -o default -X '!*.pl'  perl perl5
complete -f -o default -X '!*.ps'  gs ghostview ps2pdf ps2ascii
complete -f -o default -X '!*.dvi' dvips dvipdf xdvi dviselect dvitype
complete -f -o default -X '!*.pdf' acroread pdf2ps
complete -f -o default -X '!*.+(pdf|ps)' gv
complete -f -o default -X '!*.texi*' makeinfo texi2dvi texi2html texi2pdf
complete -f -o default -X '!*.tex' tex latex slitex
complete -f -o default -X '!*.lyx' lyx
complete -f -o default -X '!*.+(jpg|gif|xpm|png|bmp)' xv gimp
complete -f -o default -X '!*.mp3' mpg123
complete -f -o default -X '!*.ogg' ogg123


# This is a 'universal' completion function - it works when commands have
# a so-called 'long options' mode , ie: 'ls --all' instead of 'ls -a'
_universal_func ()
{
	case "$2" in
	-*)	;;
	*)	return ;;
	esac

	case "$1" in
	\~*)	eval cmd=$1 ;;
	*)	cmd="$1" ;;
	esac
	COMPREPLY=( $("$cmd" --help | sed  -e '/--/!d' -e 's/.*--\([^ ]*\).*/--\1/'| \
grep ^"$2" |sort -u) )
}
complete  -o default -F _universal_func ldd wget bash id info


_make_targets ()
{
	local mdef makef gcmd cur prev i

	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}

	# if prev argument is -f, return possible filename completions.
	# we could be a little smarter here and return matches against
	# `makefile Makefile *.mk', whatever exists
	case "$prev" in
		-*f)    COMPREPLY=( $(compgen -f $cur ) ); return 0;;
	esac

	# if we want an option, return the possible posix options
	case "$cur" in
		-)      COMPREPLY=(-e -f -i -k -n -p -q -r -S -s -t); return 0;;
	esac

	# make reads `makefile' before `Makefile'
	if [ -f makefile ]; then
		mdef=makefile
	elif [ -f Makefile ]; then
		mdef=Makefile
	else
		mdef=*.mk               # local convention
	fi

	# before we scan for targets, see if a makefile name was specified
	# with -f
	for (( i=0; i < ${#COMP_WORDS[@]}; i++ )); do
		if [[ ${COMP_WORDS[i]} == -*f ]]; then
			eval makef=${COMP_WORDS[i+1]}       # eval for tilde expansion
			break
		fi
	done

		[ -z "$makef" ] && makef=$mdef

	# if we have a partial word to complete, restrict completions to
	# matches of that word
	if [ -n "$2" ]; then gcmd='grep "^$2"' ; else gcmd=cat ; fi

	# if we don't want to use *.mk, we can take out the cat and use
	# test -f $makef and input redirection
	COMPREPLY=( $(cat $makef 2>/dev/null | awk 'BEGIN {FS=":"} /^[^.#   ][^=]*:/ {print $1}' | tr -s ' ' '\012' | sort -u | eval $gcmd ) )
}

complete -F _make_targets -X '+($*|*.[cho])' make gmake pmake

_configure_func ()
{
	case "$2" in
		-*)     ;;
		*)      return ;;
	esac

	case "$1" in
		\~*)    eval cmd=$1 ;;
		*)      cmd="$1" ;;
	esac

	COMPREPLY=( $("$cmd" --help | awk '{if ($1 ~ /--.*/) print $1}' | grep ^"$2" | sort -u) )
}

complete -F _configure_func configure

# cvs(1) completion
_cvs ()
{
	local cur prev
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}

	if [ $COMP_CWORD -eq 1 ] || [ "${prev:0:1}" = "-" ]; then
	COMPREPLY=( $( compgen -W 'add admin annotate checkout commit diff \
	export history import log rdiff release remove rtag status \
	tag update' $cur ))
	else
	COMPREPLY=( $( compgen -f $cur ))
	fi
	return 0
}
complete -F _cvs cvs


_killall ()
{
	local cur prev
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}

	# get a list of processes (the first sed evaluation
	# takes care of swapped out processes, the second
	# takes care of getting the basename of the process)
	COMPREPLY=( $( /usr/bin/ps -u $USER -o comm  | \
		sed -e '1,1d' -e 's#[]\[]##g' -e 's#^.*/##'| \
		awk '{if ($0 ~ /^'$cur'/) print $0}' ))

	return 0
}

complete -F _killall killall killps

################################################################################
