vim-indentblank
===============

Going to insert mode in a blank line auto-indents it to the last non-blank line's indentation level.


Options
-------
| Option                      | Description                                                                                   |
| --------------------------- | --------------------------------------------------------------------------------------------- |
| `g:indentBlank#enabled`     | Set to `0` to disable. Any other value enables it.                                            |
| `g:indentBlank#maxFileSize` | Largest file size vim-indentblank will activate for, in bytes (defaults to `8388608`, 8 MiB). |
