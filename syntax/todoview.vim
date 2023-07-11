":set syntax=todoview
"echo  exists('g:syntax_on')
"set syntax
"Usually invoked by an autocommand that can infer filetypes

syntax match tasknumber '^[0-9][0-9]*'
highlight def link tasknumber Number

syntax match taskbullet '\*'
highlight def link taskbullet MoreMsg
