"TODO: If loaded code_todo, load code_todo...
"TODO: Read the plugin tutorial


let s:script_path = resolve(expand('<sfile>:p'))
let s:script_dir = fnamemodify(s:script_path, ':h')
let s:todo_binary = s:script_dir.'/../code-todo.py'

function s:CreateViewMaps() abort
    nnoremap <buffer><silent> dd  :call MarkComplete()<CR>
    nnoremap <buffer><silent> n  :call OpenBackingFile()<CR>
    nnoremap <buffer><silent> u  :call UndoChange()<CR>
    nnoremap <buffer> o  V:<BS><BS><BS><BS><BS>call AddTask('')<Left><Left>
    nnoremap <buffer><silent> <  :call MakeShallower()<CR>
    nnoremap <buffer><silent> >  :call MakeDeeper()<CR>
endfunction

" This is like a constructor
function OpenTodoList() abort
    let l:backing_file = resolve(expand('%:p'))
    if l:backing_file ==# ''
        echoerr "No file found"
        return
    endif
    " TODO: Todofiletype
    " This actually loads things, so that vim can track it...
    exe 'vnew '.l:backing_file 
    let l:todobuff = 'todo://'.l:backing_file
    exe 'edit '.l:todobuff
    if exists('b:backing_todo_file')
        return
    endif

    let b:backing_todo_file = l:backing_file

    "TODO nofile vs nowrite
    setl buftype=nofile bufhidden=hide noswapfile
    setl noma

    call BufferRefreshTodos()
    augroup codetodo
        autocmd!
        autocmd BufEnter todo://* silent call BufferRefreshTodos()
    augroup END
    call s:CreateViewMaps()
endfunction


" I am sure we can make things better...
function s:CheckValidity() abort
    if !exists('b:backing_todo_file')
      echoerr 'You shall not call!'
      return 0
    endif
    return 1
endfunction


function BufferRefreshTodos() abort
    if !s:CheckValidity()
        return
    endif

    let l:curpos = getpos('.')
    setl ma

    " Clean backing file
    %delete
    exe '0read '.b:backing_todo_file
    $delete

    " Make subtasks cleaner
    silent %s/^-*/\=repeat('    ',strlen(submatch(0)))

    " Add line numbers to the file
    silent %s/^/\=line('.')."\t"/

    " Filter out completed tasks
    silent global/^.*\~$/d
    setl noma

    call setpos('.',l:curpos)
    echo "Refresh complete!"
endfunction


function BackingFileCommand(...) abort
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

    write
    exe 'edit '.l:me
    call setpos('.',l:curpos)
endfunction

function UndoChange()
    call BackingFileCommand('undo')
endfunction


function AddTask(taskstring)
    call BackingFileCommand(
                \ 'let l:hyphens = repeat("-",s:ExtractTaskDepthBacking())',
                \ 'let l:taskadded = l:hyphens."'.a:taskstring.'"',
                \ 'put =l:taskadded'
                \)
    normal! j
endfunction

function MakeDeeper()
    call BackingFileCommand(
                \ 'normal! 0i-',
                \)
endfunction


"TODO: Can we add some if condition here
function MakeShallower()
    call BackingFileCommand(
                \ 'silent s/^-//'
                \)
endfunction

function MarkComplete()
    call BackingFileCommand(
                \ 'normal! A ~'
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

" If something bad happens
function OpenBackingFile()
    if !s:CheckValidity()
       return
    endif
    let l:curr = s:ExtractTaskNumber()
    exe 'vnew '.b:backing_todo_file
    exe l:curr+1
endfunction

