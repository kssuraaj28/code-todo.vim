code-todo :heart: vim
=====================
A simple hierarchical todo-list plugin for vim.

Installation
-----
Install using your vim plugin manager of choice.
This plugin has been tested with neovim v0.9.0, and vim v9.0, and does seem to work.

Usage
-----
This plugin provides a single function (called `OpenTodoView()`) along with a single mapping (which is `<space> v` by default) to create a **todo view** from a **todo list backing file**. Any file can work as a backing file, and this plugin assumes that backing files have the following structure: 

```
Task 1
-Subtask 1.1
-Completed Subtask 1.2  ~
-Subtask 1.3
Task 2
-Subtask 2.1
--Subtask 2.1
-Subtask 2.2
```

Executing `<space> v` will open the **todo view** of the file, loaded in a new buffer:
```
1	* Task 1
2	    * Subtask 1.1
4	    * Subtask 1.3
5	* Task 2
6	    * Subtask 2.1
7	        * Subtask 2.1
8	    * Subtask 2.2
```

Todo View Usage
---------------
In the **todo view**, the following mappings are defined:

 * 'dd': Mark a task as completed
 * 'u': Undo previous change
 * '>': Increase depth of a task
 * '<': Decrease depth of a task
 * 'o': Add a new task (write your task description, and press `<Enter>`)
 * 'cc': Change existing task description (write your task description, and press `<Enter>`)
 * 'J/K': Move current task down/up

Moreover, you can use the same map that you use to open the **todo view** (`<space> v` by default) to switch back to the backing file.

Customization
-----
If you would like to use another mapping, add `let g:codetodo_mapenable = 0` to your vimrc, and add `nmap ??? <Plug>(code-todo-viewopen)` (replacing ??? with your keymap).

Finally, external contributions are welcome.
