" Functions to auto-indent to the last non-blank line's indentation level:
let g:indentedBlank = -1
function! IndentBlank()
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
            " Reproduce the last non-blank line's indentation:
            call feedkeys(l:lineToWrite)
            let g:indentedBlank = l:current
        endif
    endif
endfunction
function! DeIndentBlank()
    " If the current line has been indented by IndentBlank()
    " but nothing has been written in it, undo:
    if (g:indentedBlank == line(".") && match(getline("."), "^[ \t]*$") >= 0)
        let l:lines = line("$")
        undo
        " If the previously indented empty line is not empty after the undo,
        " empty is manually.
        " Also be sure that the number of lines before and after the undo is
        " the same, or having started insert mode with "o" would cause
        " the next line to be emptied instead.
        if (getline(g:indentedBlank) != "" && l:lines == line("$"))
            call setline(g:indentedBlank, "")
        endif
    endif
    let g:indentedBlank = -1
endfunction
" Execute them every time we enter/leave insert mode:
if exists("#InsertBlank")
    " If the autocommands already exist (e.g.: sourcing this multiple times
    " for testing) delete them first:
    autocmd! InsertBlank InsertEnter,InsertLeave *
endif
augroup InsertBlank
    autocmd InsertEnter * call IndentBlank()
    autocmd InsertLeave * call DeIndentBlank()
augroup END
