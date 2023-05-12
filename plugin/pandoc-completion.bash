# This script enables bash autocompletion for pandoc.  To enable
# bash completion, add this to your .bashrc:
# eval "$(pandoc --bash-completion)"

_pandoc()
{
    local cur prev opts lastc informats outformats datadir
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # These should be filled in by pandoc:
    opts="-f -r --from --read -t -w --to --write -o --output --data-dir -R --parse-raw -S --smart --old-dashes --base-header-level --indented-code-classes -F --filter --normalize -p --preserve-tabs --tab-stop --track-changes --file-scope --extract-media -s --standalone --template -M --metadata -V --variable -D --print-default-template --print-default-data-file --dpi --no-wrap --wrap --columns --toc --table-of-contents --toc-depth --no-highlight --highlight-style -H --include-in-header -B --include-before-body -A --include-after-body --self-contained --html-q-tags --ascii --reference-links --reference-location --atx-headers --chapters --top-level-division -N --number-sections --number-offset --no-tex-ligatures --listings -i --incremental --slide-level --section-divs --default-image-extension --email-obfuscation --id-prefix -T --title-prefix -c --css --reference-odt --reference-docx --epub-stylesheet --epub-cover-image --epub-metadata --epub-embed-font --epub-chapter-level --latex-engine --latex-engine-opt --bibliography --csl --citation-abbreviations --natbib --biblatex -m --latexmathml --asciimathml --mathml --mimetex --webtex --jsmath --mathjax --katex --katex-stylesheet --gladtex --trace --dump-args --ignore-args --verbose --bash-completion --list-input-formats --list-output-formats --list-extensions --list-highlight-languages --list-highlight-styles -v --version -h --help"
    informats="native json markdown markdown_strict markdown_phpextra markdown_github markdown_mmd commonmark rst mediawiki docbook opml org textile html latex haddock twiki docx odt t2t epub"
    outformats="native json docx odt epub epub3 fb2 html html5 icml s5 slidy slideous dzslides revealjs docbook docbook5 opml opendocument latex beamer context texinfo man markdown markdown_strict markdown_phpextra markdown_github markdown_mmd plain rst mediawiki dokuwiki zimwiki textile rtf org asciidoc haddock commonmark tei"
    highlight_styles="pygments tango espresso zenburn kate monochrome breezedark haddock"
    datadir="/usr/share/pandoc"

    case "${prev}" in
         --from|-f|--read|-r)
             COMPREPLY=( $(compgen -W "${informats}" -- ${cur}) )
             return 0
             ;;
         --to|-t|--write|-w|-D|--print-default-template)
             COMPREPLY=( $(compgen -W "${outformats}" -- ${cur}) )
             return 0
             ;;
         --email-obfuscation)
             COMPREPLY=( $(compgen -W "references javascript none" -- ${cur}) )
             return 0
             ;;
         --latex-engine)
             COMPREPLY=( $(compgen -W "pdflatex lualatex xelatex" -- ${cur}) )
             return 0
             ;;
         --print-default-data-file)
             COMPREPLY=( $(compgen -W "reference.odt reference.docx $(find ${datadir} | sed -e 's/.*\/data\///')" -- ${cur}) )
             return 0
             ;;
         --wrap)
             COMPREPLY=( $(compgen -W "auto none preserve" -- ${cur}) )
             return 0
             ;;
         --track-changes)
             COMPREPLY=( $(compgen -W "accept reject all" -- ${cur}) )
             return 0
             ;;
         --reference-location)
             COMPREPLY=( $(compgen -W "block section document" -- ${cur}) )
             return 0
             ;;
         --top-level-division)
             COMPREPLY=( $(compgen -W "section chapter part" -- ${cur}) )
             return 0
             ;;
         --highlight-style)
             COMPREPLY=( $(compgen -W "${highlight_styles}" -- ${cur}) )
             return 0
             ;;
         *)
             ;;
    esac

    case "${cur}" in
         -*)
             COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
             return 0
             ;;
         *)
             local IFS=$'\n'
             COMPREPLY=( $(compgen -X '' -f "${cur}") )
             return 0
             ;;
    esac

}

complete -o filenames -o bashdefault -F _pandoc pandoc

