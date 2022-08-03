#
# ~/.bashrc
#

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Functions

# Show git branch name
git_branch() {
   local BRANCH=$(git symbolic-ref HEAD --short 2> /dev/null)
   if [[ ! -z "$BRANCH" ]]; then
     echo "($BRANCH)"
   fi
}

# Automatically add completion for all aliases to commands having completion functions
alias_completion() {
    local namespace="alias_completion"
    local compl_regex='complete( +[^ ]+)* -F ([^ ]+) ("[^"]+"|[^ ]+)'
    local alias_regex="alias ([^=]+)='(\"[^\"]+\"|[^ ]+)(( +[^ ]+)*)'"
    eval "local completions=($(complete -p | sed -Ene "/$compl_regex/s//'\3'/p"))"
    (( ${#completions[@]} == 0 )) && return 0

    rm -f "/tmp/${namespace}-*.tmp" # preliminary cleanup
    local tmp_file; tmp_file="$(mktemp "/tmp/${namespace}-${RANDOM}XXX.tmp")" || return 1
    local completion_loader; completion_loader="$(complete -p -D 2>/dev/null | sed -Ene 's/.* -F ([^ ]*).*/\1/p')"

    local line; while read line; do
        eval "local alias_tokens; alias_tokens=($line)" 2>/dev/null || continue
        local alias_name="${alias_tokens[0]}" alias_cmd="${alias_tokens[1]}" alias_args="${alias_tokens[2]# }"
        eval "local alias_arg_words; alias_arg_words=($alias_args)" 2>/dev/null || continue
        read -a alias_arg_words <<< "$alias_args"

        if [[ ! " ${completions[*]} " =~ " $alias_cmd " ]]; then
            if [[ -n "$completion_loader" ]]; then

                eval "$completion_loader $alias_cmd"
                [[ $? -eq 124 ]] || continue
                completions+=($alias_cmd)
            else
                continue
            fi
        fi
        local new_completion="$(complete -p "$alias_cmd")"

        if [[ -n $alias_args ]]; then
            local compl_func="${new_completion/#* -F /}"; compl_func="${compl_func%% *}"

            if [[ "${compl_func#_$namespace::}" == $compl_func ]]; then
                local compl_wrapper="_${namespace}::${alias_name}"
                    echo "function $compl_wrapper {
                        (( COMP_CWORD += ${#alias_arg_words[@]} ))
                        COMP_WORDS=($alias_cmd $alias_args \${COMP_WORDS[@]:1})
                        (( COMP_POINT -= \${#COMP_LINE} ))
                        COMP_LINE=\${COMP_LINE/$alias_name/$alias_cmd $alias_args}
                        (( COMP_POINT += \${#COMP_LINE} ))
                        $compl_func
                    }" >> "$tmp_file"
                    new_completion="${new_completion/ -F $compl_func / -F $compl_wrapper }"
            fi
        fi

        new_completion="${new_completion% *} $alias_name"
        echo "$new_completion" >> "$tmp_file"
    done < <(alias -p | sed -Ene "s/$alias_regex/\1 '\2' '\3'/p")
    source "$tmp_file" && rm -f "$tmp_file"
}

# Start alias completion
alias_completion


# Prompt

PS1=\
"\
\[\e[1;37m\]┌ \
\[\e[1;33m\]\t \
\[\e[1;37m\]─ \
\[\e[1;31m\]$? \
\[\e[1;37m\]─ \
\[\e[1;32m\]\u \
\[\e[1;37m\]@ \
\[\e[1;32m\]\h \
\[\e[1;37m\]─ \
\[\e[1;37m\]\$ \
\[\e[1;95m\]\[\$(git_branch)\]\
\[\e[1;37m\]\n│ \
\[\e[1;36m\]\w\n\
\[\e[1;37m\]└ \
\[\e[1;37m\]\[\$(tput sgr0)\]\
"

PS2="└ "
