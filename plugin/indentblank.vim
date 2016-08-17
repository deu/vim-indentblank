" Functions to auto-indent to the last non-blank line's indentation level:
function! indentblank#indent()
    let l:current = line(".")
    let l:prevNonBlank = prevnonblank(l:current)
    if (l:prevNonBlank > 0 && getline(".") == "")
        let l:prevNonBlankContents = getline(l:prevNonBlank)
        let l:prevNonBlankIndentation = indent(l:prevNonBlank)
        let l:lineToWrite = ""
        " If we're writing python code, if the last non-blank line is the
        " beginning of a compound statement, increment the indentation level:
        if (&filetype == "python" && (
            \    match(l:prevNonBlankContents, "^[ \t]*[^#]*:[ \t]*$")   >= 0
            \ || match(l:prevNonBlankContents, "^[ \t]*[^#]*:[ \t]*#.*") >= 0))
        " Note: match() doesn't support extended regular expressions, so this
        " ugly syntax was necessary. Otherwise use: ^\s*[^#]*:\s*\v([^#]+)@!.*$
            let l:lineToWrite .= (&expandtab == 1) ?
                \ repeat(" ", &shiftwidth) : "\t"
        endif
        let l:lineToWrite .= (&expandtab == 1) ?
            \ repeat(" ", l:prevNonBlankIndentation) :
                \   repeat("\t", l:prevNonBlankIndentation / &shiftwidth)
                \ . repeat(" ",  l:prevNonBlankIndentation % &shiftwidth)
        if l:lineToWrite != ""
            " Save the state of the buffer before adding the indentation:
            call indentblank#saveState('beforeIndent')
            " Reproduce the last non-blank line's indentation:
            call feedkeys(l:lineToWrite)
            let b:indentedBlank = l:current
        endif
    endif
endfunction
function! indentblank#deIndent()
    " If the current line has been indented by IndentBlank()
    " but nothing has been written in it, it's time to dance:
    if (b:indentedBlank == line(".") && match(getline("."), "^[ \t]*$") >= 0)
        let l:cursor = getcurpos()
        " Set the current empty line to "":
        undojoin
        call setline(b:indentedBlank, "")
        " Save the current state of the buffer:
        call indentblank#saveState('afterSetToBlank')
        " If the buffer hasn't changed between the user entering insert mode
        " and the emptying of the line, we can go ahead and undo instead to
        " keep the history clean:
        if (indentblank#compareStates('beforeIndent', 'afterSetToBlank') == 0)
            silent undo
            " Save the state of the file after undoing:
            call indentblank#saveState('afterUndo')
            " If the buffer has changed between the user entering insert mode
            " and this undo, it probably means it was changed implicitly (e.g.
            " by entering insert mode with "o"), so we actually need to
            " explicitly empty the line:
            if (indentblank#compareStates('beforeIndent', 'afterUndo') != 0)
                silent redo
                call setpos(".", l:cursor)
                undojoin
                call setline(b:indentedBlank, "")
            endif
        endif
        " Delete all temporary buffer state files:
        call indentblank#clearStates()
    endif
    let b:indentedBlank = -1
endfunction

" Functions for managing buffer states:
function! indentblank#init()
    let b:indentedBlank = -1
    if !exists('b:states')
        let b:states = {}
    endif
endfunction
function! indentblank#saveState(name)
    let l:state = get(b:states, a:name)
    if (l:state)
        call delete(l:state)
        call remove(b:states, a:name)
    endif
    let b:states[a:name] = tempname()
    call writefile(getbufline("%", "^", "$"), b:states[a:name])
endfunction
function! indentblank#compareStates(name1, name2)
    call system("cmp " . b:states[a:name1] . " " . b:states[a:name2])
    return v:shell_error
endfunction
function! indentblank#clearStates()
    for [name, file] in items(b:states)
        call delete(file)
        call remove(b:states, name)
    endfor
endfunction

" Autocommands:
if exists("#InsertBlank")
    " If the autocommands already exist (e.g.: sourcing this multiple times
    " for testing) delete them first:
    autocmd! InsertBlank BufEnter,BufLeave,InsertEnter,InsertLeave *
endif
augroup InsertBlank
    autocmd BufEnter    * call indentblank#init()
    autocmd BufLeave    * call indentblank#clearStates()
    autocmd InsertEnter * call indentblank#indent()
    autocmd InsertLeave * call indentblank#deIndent()
augroup END
