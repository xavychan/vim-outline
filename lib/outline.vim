vim9script

# ========================================================
# Outline functions
#
# export only OutlineToggle(show_private: bool)
#
# ========================================================

# Script variables
var title = ["Go on a line and hit <enter>", "to jump to definition.", ""]

# Script functions
def FindDefinition(line_numbers: list<number>)
    # You should always go on the right spot
    # by construction. See how line_numbers is built.
    echo len(title)
    var idx = max([0, line('.') - len(title) - 1])
    wincmd p
    # win_execute(win_getid(), 'wincmd p')
    cursor(line_numbers[idx], 1)
    # TODO: check if you can replace Ex commands with builin functions
    normal ^
enddef

noremap <unique> <script> <Plug>FindDef :call <SID>FindDefinition(line_numbers)<cr>

def OutlineClose()
    # In 2 steps:
        # 1. Close the window,
        # 2. wipeout the buffer
    var outline_win_id = bufwinid($"^{g:outline_buf_name}$")

    # Close the window
    if OutlineIsOpen() != -1
        win_gotoid(OutlineIsOpen())
        # TODO check if you can replace the Ex command with a builtin function
        exe ":close"
    endif

    # Throw away the old Outline (that was a scratch buffer)
    if bufexists(bufnr($"^{g:outline_buf_name}$"))
       echom "Outline buffer deleted."
       exe "bw " .. bufnr($"^{g:outline_buf_name}$")
    endif
enddef


def OutlineIsOpen(): number
    # Return win_ID if open, -1 otherwise.
    return bufwinid($"^{g:outline_buf_name}$")
enddef

export def OutlineToggle(show_private: bool)
    if OutlineIsOpen() != -1
       OutlineClose()
    else
       OutlineOpen(show_private)
    endif
enddef

def ParseBufferFallback(outline_win_id: number): list<number>
    echo "In the fallback function! :D"
    return []
enddef

def OutlineOpen(show_private: bool = 1): number
    # Return the win ID or -1 if &filetype is not python.
    # TODO Refresh automatically
    # TODO Lock window content. Consider using w:buffer OBS! NERD tree don't have this feature!
    # Close previous Outline view (if any)
    OutlineClose()

    # CREATE EMPTY WIN.
    # Create empty win from current position
    win_execute(win_getid(), 'wincmd n')

    # Set stuff in the newly created window
    var outline_win_nr = winnr('$')
    var outline_win_id = win_getid(outline_win_nr)
    win_execute(outline_win_id, 'wincmd L')
    win_execute(outline_win_id, $'vertical resize {g:outline_win_size}')
    win_execute(outline_win_id, $'file {g:outline_buf_name}')
    win_execute(outline_win_id,
        \    'setlocal buftype=nofile bufhidden=hide
        \ nobuflisted noswapfile nowrap
        \ nonumber equalalways winfixwidth')

    # Parse the buffer and populate the window
    var line_numbers = [0] # It does not like [] initialization
    if exists('b:ParseBuffer')
        line_numbers = b:ParseBuffer(outline_win_id) # This is a reference to a function!
    else
        line_numbers = ParseBufferFallback(outline_win_id)
    endif
    # FINAL TOUCH
    # Set instructions, append after lnum 0
    appendbufline(winbufnr(outline_win_id), 0, title)
    cursor(len(title) + 1, 1)
    # # After write, set it to do non-modifiable
    win_execute(outline_win_id, 'setlocal nomodifiable readonly')
    setwinvar(win_id2win(outline_win_id), "line_numbers", line_numbers)
    # TODO Fix FindDef scope
    win_execute(outline_win_id, 'nnoremap <buffer> <enter> <Plug>FindDef(w:line_numbers)<cr>')
    return outline_win_id
enddef


# augroup Outline_autochange
#     au!
#     autocmd BufWinEnter *.py if outline#PyOutlineIsOpen() != -1
#                 \| outline#PyOutlineOpen(g:show_private) | endif
#     autocmd! BufWinLeave outline#PyOutlineClose()
# augroup END