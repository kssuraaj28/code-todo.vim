"TODO: If loaded code_todo, load code_todo...
"TODO: Properfiletype plugin for 


let s:script_path = resolve(expand('<sfile>:p'))
let s:script_dir = fnamemodify(s:script_path, ':h')
let s:todo_binary = s:script_dir.'/../code-todo.py'


function OpenTodoList(filename)
    vnew 

    let b:backing_todo_file = getcwd() .'/'. a:filename
    let &l:statusline='[Todo List]'
    "TODO delete vs hidden
    "TODO nofile vs nowrite
    setl buftype=nofile bufhidden=delete noswapfile
    setl noma
    call LoadTodoList()
endfunction


" I am sure we can make things better...
function s:CheckValidity()
    if !exists('b:backing_todo_file')
      echoerr 'You shall not call!'
      return 0
    endif
    return 1
endfunction

" This function clears the function and calls
function LoadTodoList()
    if !s:CheckValidity()
        return
    endif

    "TODO Create a function for this also
    let l:command = 'echo print | python3 '.s:todo_binary.' '.b:backing_todo_file

    set ma
    silent %delete
    silent execute 'read !'.l:command 
    set noma

    echo "Load complete!"
endfunction

function TodoCommand(raw_argstr)
    if !s:CheckValidity()
        return
    endif
    
    let l:command = 'echo '. a:raw_argstr .' | python3 '.s:todo_binary.' '.b:backing_todo_file
    silent exe '!'.l:command
    silent call LoadTodoList()
endfunction

call OpenTodoList('example.todo')
