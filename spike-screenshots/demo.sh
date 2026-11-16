# SPIKE. What the terminal shows: a static prompt, a listing, and the 16 colors.
export PS1='\[\e[34m\]~/Hyaline\[\e[0m\] \[\e[32m\]main\[\e[0m\] $ '
cd /hyaline
clear
printf '%s' "${PS1@P}"; echo 'ls --color'
ls --color=always
printf '%s' "${PS1@P}"; echo 'colors'
for i in 0 1 2 3 4 5 6 7; do printf '\e[4%dm    \e[0m' "$i"; done; echo
for i in 0 1 2 3 4 5 6 7; do printf '\e[10%dm    \e[0m' "$i"; done; echo
printf '\e[31merror\e[0m  \e[32mok\e[0m  \e[33mchanged\e[0m  \e[34minfo\e[0m  \e[35mkeyword\e[0m  \e[36mstring\e[0m\n'
printf '%s' "${PS1@P}"
sleep infinity
