if exists('g:loaded_codetodo_vim')
  finish
endif
let g:loaded_codetodo_vim = 1


let s:script_path = resolve(expand('<sfile>:p'))
let s:script_dir = fnamemodify(s:script_path, ':h')
let s:todo_binary = s:script_dir.'/../code-todo.py'


function s:CreateViewMaps() abort
    nnoremap <buffer> dd  <Cmd>call <SID>MarkComplete()<CR>
    nnoremap <buffer> u  <Cmd>call <SID>UndoChange()<CR>

    nnoremap <buffer> <  <Cmd>call <SID>MakeShallower()<CR>
    nnoremap <buffer> >  <Cmd>call <SID>MakeDeeper()<CR>

    "Use user's same mapping to switch back to BackingFile
    nnoremap <buffer> <Plug>(code-todo-viewopen) :call <SID>OpenBackingFile()<CR>
    
    "TODO: Make this much better
    nnoremap <buffer> o  V:<BS><BS><BS><BS><BS>call <SID>AddTask('')<Left><Left>
    nnoremap <buffer> cc  <Cmd>call <SID>EditTask('')<Left><Left>
endfunction

function s:CreateViewAutocmds() abort
    augroup codetodo
        autocmd!
        autocmd BufEnter <buffer> call <SID>BufferRefreshTodos()
    augroup END
endfunction


" This is like a constructor
function OpenTodoView() abort
    let l:backing_file = resolve(expand('%:p'))

    if l:backing_file ==# ''
        echoerr "No file found"
        return
    endif

    " TODO: Check if current file is a todo file
    " TODO: Todofiletype
    
    let l:todobuff = 'todo://'.l:backing_file
    let l:backing_line = getpos('.')[1]
    exe 'edit '.l:todobuff

    if !exists('b:backing_todo_file')
        let b:backing_todo_file = l:backing_file

        "TODO nofile vs nowrite
        "We wanted to list the buffer, so no nobuflisted
        setl buftype=nofile 
        setl bufhidden=hide 
        setl noswapfile
        setl noma

        call s:CreateViewMaps()
        call s:CreateViewAutocmds()
        call s:BufferRefreshTodos()
    endif

    call search('^'.l:backing_line,'cw')
endfunction

nnoremap <unique> <Plug>(code-todo-viewopen) <Cmd>call OpenTodoView()<CR>
if get(g:, 'codetodo_mapenable', 1)
    nmap <silent> <space>v <Plug>(code-todo-viewopen)
endif

" I am sure we can make things better...
function s:CheckValidity() abort
    if !exists('b:backing_todo_file')
      echoerr 'You shall not call!'
      return 0
    endif
    return 1
endfunction


function s:BufferRefreshTodos() abort
    if !s:CheckValidity()
        return
    endif

    let l:curpos = getpos('.')
    setl ma

    " Clean backing file
    %delete
    silent exe '0read '.b:backing_todo_file
    $delete

    " Make subtasks cleaner
    silent %s/^-*/\=repeat('    ',strlen(submatch(0))).'* '

    " Add line numbers to the file
    silent %s/^/\=line('.')."\t"/

    " Filter out completed tasks
    silent global/^.*\~$/d
    setl noma

    call setpos('.',l:curpos)
endfunction

function s:BackingFileCommand(...) abort
    if !s:CheckValidity()
       return
    endif
    let l:task_no = s:ExtractTaskNumber()
    let l:curpos = getpos('.')
    let l:me = bufname()
    exe 'edit '.b:backing_todo_file
    exe l:task_no

    for cmd_string in a:000
        exe cmd_string
    endfor

    silent write
    exe 'edit '.l:me
    call setpos('.',l:curpos)
endfunction

function s:UndoChange()
    call s:BackingFileCommand('undo')
endfunction


function s:EditTask(taskstring)
    call s:BackingFileCommand(
                \ 'let l:hyphens = repeat("-",s:ExtractTaskDepthBacking())',
                \ 'normal! 0wD"="'.taskstring.'"<CR>p'
                \)
endfunction

function s:MarkComplete()
    call s:BackingFileCommand(
                \ 'normal! A ~'
                \)
endfunction

function s:AddTask(taskstring)
    call s:BackingFileCommand(
                \ 'let l:hyphens = repeat("-",s:ExtractTaskDepthBacking())',
                \ 'let l:taskadded = l:hyphens."'.a:taskstring.'"',
                \ 'put =l:taskadded'
                \)
    normal! j
endfunction

function s:MakeDeeper()
    call s:BackingFileCommand(
                \ 'normal! 0i-',
                \)
endfunction


"TODO: Can we add some if condition here
function s:MakeShallower()
    call s:BackingFileCommand(
                \ 'silent s/^-//'
                \)
endfunction

function s:ExtractTaskDepthBacking()
    let l:line = getline(".")
    return len(matchstr(l:line,"^\-*"))
endfunction

function s:ExtractTaskNumber()
    if !s:CheckValidity()
       return
    endif
    let l:curpos = getpos('.')
    normal 0
    let l:taskno = expand('<cword>')
    call setpos('.',l:curpos)
    return l:taskno
endfunction

function s:OpenBackingFile()
    if !s:CheckValidity()
       return
    endif
    let l:curr = s:ExtractTaskNumber()
    exe 'edit '.b:backing_todo_file
    exe l:curr
endfunction

