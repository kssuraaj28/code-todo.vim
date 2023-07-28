if exists('g:loaded_codetodo_vim')
  finish
endif
let g:loaded_codetodo_vim = 1

let s:spaceunit = '	'

let s:script_path = resolve(expand('<sfile>:p'))
let s:script_dir = fnamemodify(s:script_path, ':h')
let s:todo_binary = s:script_dir.'/../code-todo.py'

function s:CreateViewMaps() abort
    noremap <buffer><silent> dd  <Cmd>call <SID>MarkComplete()<CR>
    noremap <buffer><silent> u  <Cmd>call <SID>UndoChange()<CR>
    noremap <buffer><silent> <C-r>  <Cmd>call <SID>RedoChange()<CR>

    "Works for both normal and visual mode
    noremap <buffer><silent> <  <Cmd>call <SID>MakeShallower()<CR>
    noremap <buffer><silent> >  <Cmd>call <SID>MakeDeeper()<CR>

    noremap <buffer><silent> J  :call <SID>MoveRange(v:false)<CR>
    noremap <buffer><silent> K  :call <SID>MoveRange(v:true)<CR>

    "Use user's same mapping to switch back to BackingFile
    noremap <buffer><silent> <Plug>(code-todo-viewopen) :call <SID>OpenBackingFile()<CR>
    
    noremap <buffer><silent> o
                \ V<Cmd>call <SID>AddTask(
                \ input(<SID>GenerateTaskCreationPrompt(<SID>ExtractTaskNumber()+1))
                \ )<CR>
    
    noremap <buffer><silent> cc
                \ V<Cmd>call <SID>EditTask(
                \ input(<SID>GenerateTaskCreationPrompt(<SID>ExtractTaskNumber()))
                \ )<CR>

     " No silent here because the ExtractTaskString() default string will not
     " appear
    noremap <buffer> A
                \ V<Cmd>call <SID>EditTask(
                \ input(<SID>GenerateTaskCreationPrompt(<SID>ExtractTaskNumber()))
                \ )<CR><C-r>=<SID>ExtractTaskString()<CR>
    
endfunction

function s:GenerateTaskCreationPrompt(linenr) abort
    return  {'prompt':'Enter new task['.a:linenr.']: ','cancelreturn': '~'}
endfunction

function s:CreateViewAutocmds() abort
    augroup codetodo
        autocmd!
        autocmd BufEnter <buffer> call <SID>ViewRefreshFromBackingFile()
    augroup END
endfunction

function s:EnsureBackingFilePersist() abort
    if !s:CheckIfViewBuffer()
        return
    endif

    let l:backing_buf = bufname(b:backing_todo_file)
    if getbufvar(l:backing_buf, "&modified")
        echohl WarningMsg 
            echom "Warning: Backing file is not persistent. Saving changes"
        echohl None

        "From https://github.com/vim/vim/issues/9698#issuecomment-1030662727
        call getbufline(l:backing_buf, 1, "$")->writefile(l:backing_buf)
        call setbufvar(l:backing_buf, "&modified", v:false)
    endif
endfunction


" I am sure we can make things better...
function s:CheckIfViewBuffer() abort
    if !exists('b:backing_todo_file')
      echoerr 'You shall not call!'
      return 0
    endif
    return 1
endfunction


function s:ViewRefreshFromBackingFile() abort
    if !s:CheckIfViewBuffer()
        return
    endif

    call s:EnsureBackingFilePersist()

    let l:window_collection = win_findbuf(bufnr())
    let l:winviews = {}
    for l:win_id in win_findbuf(bufnr())
        call win_execute(win_id,
                    \'let l:winviews[l:win_id] = winsaveview()')
    endfor

    setl ma

    " Clean backing file
    %delete
    silent exe '0read '.b:backing_todo_file
    $delete

    " Make subtasks cleaner
    silent %s/^-*/\=repeat(s:spaceunit,strlen(submatch(0))).'* '

    " Add line numbers to the file
    silent %s/^/\=line('.').s:spaceunit/

    " Filter out completed tasks
    silent global/^.*\~$/d
    setl noma

    for l:win_id in l:window_collection
        call win_execute(win_id, 
                    \'call winrestview(l:winviews[l:win_id])')
    endfor
endfunction

function s:BackingFileCommand(...) abort
    if !s:CheckIfViewBuffer()
       return
    endif
    let l:curview = winsaveview()
    let l:me = bufname()
    
    call s:OpenBackingFile()

    for cmd_string in a:000
        exe cmd_string
    endfor

    silent write
    exe 'edit '.l:me
    call winrestview(l:curview)
endfunction

function s:UndoChange() abort
    call s:BackingFileCommand('undo')
endfunction

function s:RedoChange() abort
    call s:BackingFileCommand('redo')
endfunction


function s:EditTask(taskstring) abort range
    let l:trimmed = trim(a:taskstring)
    if l:trimmed ==# '~'
        return
    endif
    call s:BackingFileCommand(
                \ 'let l:hyphens = repeat("-",s:ExtractTaskDepthBacking())',
                \ 'let l:message = l:hyphens."'.l:trimmed.'"',
                \ 'put =l:message',
                \ 'normal! kdd',
                \)
endfunction

"TODO: Range
function s:MarkComplete() abort 
    call s:BackingFileCommand(
                \ 'normal! A ~'
                \)
endfunction


function s:AddTask(taskstring) abort
    let l:trimmed = trim(a:taskstring)
    if l:trimmed ==# '~'
        return
    endif
    call s:BackingFileCommand(
                \ 'let l:hyphens = repeat("-",s:ExtractTaskDepthBacking())',
                \ 'let l:taskadded = l:hyphens."'.l:trimmed.'"',
                \ 'put =l:taskadded'
                \)
    normal! j
endfunction

function s:MakeDeeper() abort
    call s:BackingFileCommand(
                \ 'normal! 0i-',
                \)
endfunction


function s:MakeShallower() abort
    call s:BackingFileCommand(
         \'if s:ExtractTaskDepthBacking() > 0 |'.
         \ 'silent s/^-// |'.
         \' else |'.
         \ 'echoerr "Top level task!" |'.
         \'endif')
endfunction



" This function moves the range, and also visually selects it.
function s:MoveRange(is_up) range abort
    let l:tor = a:firstline   
    let l:bor = a:lastline


    let l:ttask = s:ExtractTaskNumber(l:tor)
    let l:btask = s:ExtractTaskNumber(l:bor)

    if a:is_up
        let l:destination = s:ExtractTaskNumber(l:tor-1)-1
    else
        let l:destination = s:ExtractTaskNumber(l:bor+1)
    endif

    call s:BackingFileCommand(
                \'silent '.l:ttask.','.l:btask.'move '.l:destination)

    if a:is_up
        exe l:tor-1
    else
        exe l:tor+1
    endif

    " Here, we select the text again..
    let l:viewdiff = l:bor - l:tor
    normal! V
    if l:viewdiff>0
        exe 'normal! '.l:viewdiff.'j'
    endif

endfunction

" It takes an optional arguement which in line number. 
" Otherwise, it is the current line
function s:ExtractTaskDepthBacking(...) abort
    if a:0 > 0
        let l:line = getline(a:0)
    else
        let l:line = getline(".")
    endif

    return len(matchstr(l:line,"^\-*"))
endfunction

"TODO: Lambda this
function s:SpaceCount(line) 
    let l:numstrip = substitute(a:line,"^[0-9]*",'','')
    return len(matchstr(l:numstrip,"^.*[*]"))-1
endfunction
" It takes an optional arguement which in line number. 
" Otherwise, it is the current line
function s:ExtractTaskString(...) abort
    if !s:CheckIfViewBuffer()
       return
    endif
    if a:0 > 0
        let l:line = getline(a:0)
    else
        let l:line = getline(".")
    endif
    

    let l:endidx = matchstrpos(l:line,"^.*[*] ")[2]
    let l:task = l:line[l:endidx:]

    return l:task
endfunction

" It takes an optional arguement which in line number. 
" Otherwise, it is the current line
function s:ExtractTaskNumber(...) abort
    if !s:CheckIfViewBuffer()
       return
    endif
    let l:curview = winsaveview()

    if a:0 > 0
        exe a:1
    endif

    normal! 0
    let l:taskno = expand('<cword>')
    call winrestview(l:curview)
    return l:taskno
endfunction

function s:OpenBackingFile() abort
    if !s:CheckIfViewBuffer()
       return
    endif
    let l:curr = s:ExtractTaskNumber()
    exe 'edit '.b:backing_todo_file
    exe l:curr
endfunction


function OpenTodoView() abort
    let l:backing_file = resolve(expand('%:p'))

    if l:backing_file ==# ''
        echoerr "No file found"
        return
    endif

    if !filereadable(l:backing_file)
        echoerr "File not readable"
        return
    endif

    if !filewritable(l:backing_file)
        echoerr "File not writeable"
        return
    endif

    if ! &l:buftype ==# ''
        echoerr "Must be a simple file"
        return
    endif

    if &l:readonly
        echoerr "Must not be readonly"
        return
    endif

    " TODO: Extract this to a function
    let l:todobuff = 'todo://'.l:backing_file
    let l:backing_line = getpos('.')[1]

    exe 'silent edit '.l:todobuff

    if !exists('b:backing_todo_file')
        let b:backing_todo_file = l:backing_file

        "TODO nofile vs nowrite
        "We wanted to list the buffer, so no nobuflisted
        setl buftype=nofile 
        setl bufhidden=hide 
        setl noswapfile
        setl noma
        setl syntax=todoview

        call s:CreateViewMaps()
        call s:CreateViewAutocmds()
        call s:ViewRefreshFromBackingFile()
    endif

    call search('^'.l:backing_line,'cw')
endfunction

nnoremap <unique> <Plug>(code-todo-viewopen) <Cmd>call OpenTodoView()<CR>
if get(g:, 'codetodo_mapenable', 1)
    nmap <silent> <space>v <Plug>(code-todo-viewopen)
endif
