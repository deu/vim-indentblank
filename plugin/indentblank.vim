" Functions to auto-indent to the last non-blank line's indentation level:
let g:indentedBlank = 0
function! IndentBlank()
    let l:prevNonBlank = prevnonblank(line("."))
    if (l:prevNonBlank > 0 && getline(".") == "")
        let l:prevNonBlankContents = getline(l:prevNonBlank)
        let l:prevNonBlankIndentation = indent(l:prevNonBlank)
        let l:lineToWrite = ""
        " If we're writing python code, if the last non-blank line is the beginning
        " of a compound statement, increment the indentation level:
        if (&filetype == "python" && (match(l:prevNonBlankContents, "^[ \t]*[^#]*:[ \t]*$") >= 0 || match(l:prevNonBlankContents, "^[ \t]*[^#]*:[ \t]*#.*") >= 0))
        " Note: match() doesn't support extended regular expressions, so this ugly syntax was necessary. Otherwise use: ^\s*[^#]*:\s*\v([^#]+)@!.*$
            if (&expandtab == 1)
                for i in range(1, &shiftwidth)
                    let l:lineToWrite .= " "
                endfor
            else
                let l:lineToWrite .= "\t"
            endif
        endif
        " Reproduce the last non-blank line's indentation:
        if (&expandtab == 1)
            for i in range(1, l:prevNonBlankIndentation)
                let l:lineToWrite .= " "
            endfor
        else
            for i in range(1, l:prevNonBlankIndentation / &shiftwidth)
                let l:lineToWrite .= "\t"
            endfor
            for i in range(1, l:prevNonBlankIndentation % &shiftwidth)
                let l:lineToWrite .= " "
            endfor
        endif
        call setline(line("."), l:lineToWrite)
        let g:indentedBlank = 1
        " Start insert mode at EOL:
        startinsert!
    endif
endfunction
function! DeIndentBlank()
    " If the current line has been indented by IndentBlank()
    " but nothing has been written in it, empty it:
    if (g:indentedBlank == 1 && match(getline("."), "^[ \t]*$") >= 0)
        call setline(line("."), "")
    endif
    let g:indentedBlank = 0
endfunction
" Execute them every time we enter/leave insert mode:
autocmd InsertEnter * call IndentBlank()
autocmd InsertLeave * call DeIndentBlank()
