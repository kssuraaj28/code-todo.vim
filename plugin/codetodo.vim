"TODO: If loaded code_todo, load code_todo...
"TODO: Properfiletype plugin for 

"TODO: Proper undo support


let s:script_path = resolve(expand('<sfile>:p'))
let s:script_dir = fnamemodify(s:script_path, ':h')
let s:todo_binary = s:script_dir.'/../code-todo.py'


function OpenTodoList(filename)
    let l:backing_file = getcwd() .'/'. a:filename

    " This actually loads things, so that vim can track it...
    exe 'vnew '.l:backing_file 
    enew
    let b:backing_todo_file = l:backing_file
    "TODO: Look at fugitive
    nnoremap <buffer><silent> dd  :call MarkComplete()<CR>

    let &l:statusline='[Todo List]'
    "TODO delete vs hidden
    "TODO nofile vs nowrite
    setl buftype=nofile bufhidden=delete noswapfile
    setl noma
    call BufferRefreshTodos()
endfunction


" I am sure we can make things better...
function s:CheckValidity()
    if !exists('b:backing_todo_file')
      echoerr 'You shall not call!'
      return 0
    endif
    return 1
endfunction


function s:CreateCmdLine(raw_argstr)
    let l:command = 'echo '. a:raw_argstr .' | python3 '.s:todo_binary.' '.b:backing_todo_file
    return l:command
endfunction

" This function 'refreshes the buffer'
function BufferRefreshTodos()
    if !s:CheckValidity()
        return
    endif

    let l:curpos = getpos('.')
    setl ma
    silent %delete
    silent execute '0read !'. s:CreateCmdLine('print')
    setl noma
    call setpos('.',l:curpos)
    echo "Refresh complete!"
endfunction

function TodoCommand(raw_argstr)
    if !s:CheckValidity()
       return
    endif
    let l:command = s:CreateCmdLine(a:raw_argstr)
    silent exe '!'.l:command
    silent call BufferRefreshTodos()
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
    exe l:curr

endfunction

function MarkComplete()
    if !s:CheckValidity()
       return
    endif
    silent call TodoCommand('done ' . s:ExtractTaskNumber())
endfunction

call OpenTodoList('example.todo')
