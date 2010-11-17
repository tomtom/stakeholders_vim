" stakeholders.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-11-02.
" @Last Change: 2010-11-17.
" @Revision:    727
" GetLatestVimScripts: 3326 0 :AutoInstall: stakeholders.vim


if exists('loaded_stakeholders')
    " finish
endif
let loaded_stakeholders = 1


if !exists('g:stakeholders#def')
    " The placeholder definition. A dictionary with the fields:
    "   rx ....... A |regexp| that matches placeholders.
    let g:stakeholders#def = {'rx': '<+\([[:alpha:]_]\+\)+>'}   "{{{2
endif


if !exists('g:stakeholders#expansion')
    " The type of placeholder expansion. Possible values:
    "   - delayed (see |stakeholders#delayed#Init()|)
    "   - immediate (see |stakeholders#immediate#Init()|)
    let g:stakeholders#expansion = 'immediate'   "{{{2
endif


if !exists('g:stakeholders#exclude_rx')
    let g:stakeholders#exclude_rx = '^\(TODO\|\)$'   "{{{2
endif


augroup stakeholders
    autocmd!
    " autocmd BufWinEnter,WinEnter * call s:Enter()
    " autocmd WinLeave * call s:Leave()
augroup END


" function! stakeholders#Disable() "{{{3
"     augroup stakeholders
"         autocmd! BufEnter *
"     augroup END
" endf


" function! stakeholders#Enable() "{{{3
"     augroup stakeholders
"         autocmd BufNew,BufNewFile * call stakeholders#EnableBuffer()
"     augroup END
" endf


" Enable stakeholders for a range of lines.
function! stakeholders#EnableInRange(line1, line2) "{{{3
    if !exists('b:stakeholders')
        let b:stakeholders_range = [a:line1, a:line2]
        " echom "DBG stakeholders#EnableInRange" string(b:stakeholders_range)
        call stakeholders#EnableBuffer()
    endif
endf


" Enable stakeholders for the current buffer.
function! stakeholders#EnableBuffer() "{{{3
    if !exists('b:stakeholders')
        let b:stakeholders = exists('b:stakeholders_def') ? 
                    \ b:stakeholders_def.rx : g:stakeholders#def.rx
        " echom "DBG stakeholders#EnableBuffer" b:stakeholders
        autocmd stakeholders CursorMoved,CursorMovedI <buffer> call s:CursorMoved(mode())
        " autocmd stakeholders InsertEnter,InsertLeave <buffer> call s:CursorMoved(mode())
        call s:CursorMoved('n')
    endif
endf


" Disable stakeholders for the current buffer.
function! stakeholders#DisableBuffer() "{{{3
    if exists('b:stakeholders')
        unlet! b:stakeholders b:stakeholders_range w:stakeholders
        autocmd! stakeholders CursorMoved,CursorMovedI <buffer>
    endif
endf


function! s:SetContext(pos, mode) "{{{3
    if !exists('b:stakeholders')
        return a:pos
    endif
    let pos = a:pos
    if exists('w:stakeholders.End')
        let pos = w:stakeholders.End(pos)
    endif
    " TLogVAR pos
    let lnum = pos[1]
    if exists('b:stakeholders_range') && (lnum < b:stakeholders_range[0] || lnum > b:stakeholders_range[1])
        call stakeholders#DisableBuffer()
    else
        let w:stakeholders = {
                    \ 'lnum': lnum
                    \ }
        let line = getline(lnum)
        if line !~ b:stakeholders
            let w:stakeholders.line = ''
        else
            let w:stakeholders.line = line
            " TLogVAR a:mode, mode()
            let col = s:Col(pos[2], a:mode)
            call s:SetParts(w:stakeholders, line, col)
        endif
        " TLogVAR w:stakeholders
    endif
    return pos
endf


function! s:SetParts(ph_def, line, col) "{{{3
    " function! stakeholders#SetParts(ph_def, line, col) "{{{3
    " TLogVAR a:col
    let a:ph_def.pre = ''
    let parts = split(a:line, b:stakeholders .'\zs')
    let c = 0
    for i in range(len(parts))
        let part = parts[i]
        let plen = c + len(part)
        " TLogVAR plen
        if plen < a:col
            let a:ph_def.pre .= part
            let c = plen
        else
            let phbeg = match(part, b:stakeholders .'$')
            if phbeg != -1
                let pre = strpart(part, 0, phbeg)
                let prelen = c + len(pre)
                " TLogVAR prelen
                if prelen <= a:col
                    let a:ph_def.pre .= pre
                    let placeholder = strpart(part, phbeg)
                    let a:ph_def.placeholder = placeholder
                    let a:ph_def.post = join(parts[i + 1 : -1], '')
                    " TLogVAR a:ph_def
                    break
                endif
            endif
            " let a:ph_def.pre .= join(parts[i : -1], '')
            " TLogVAR a:ph_def
            break
        endif
    endfor
    return a:ph_def
endf


function! s:Col(col, mode) "{{{3
    " TLogVAR a:col, a:mode
    let col = a:col
    if a:mode == 'n' " && col < len(getline(a:pos[1]))
        let col -= 1
    elseif a:mode =~ '^[sv]' && &selection[0] == 'e'
        let col -= 1
    endif
    " TLogVAR col
    return col
endf


function! s:CursorMoved(mode) "{{{3
    let pos = getpos('.')
    " TLogVAR a:mode, pos
    try
        let lnum = pos[1]
        if exists('w:stakeholders.placeholder') && !empty(w:stakeholders.line) && w:stakeholders.lnum == lnum
            " TLogVAR w:stakeholders.placeholder
            let line = getline(lnum)
            " TLogVAR line
            if line != w:stakeholders.line
                let pre0 = w:stakeholders.pre
                let post0 = w:stakeholders.post
                let init = !has_key(w:stakeholders, 'replacement')
                if !init
                    let pre0 = stakeholders#Replace(w:stakeholders, pre0)
                    let post0 = stakeholders#Replace(w:stakeholders, post0)
                endif
                " TLogVAR pre0, post0
                let lpre = len(pre0)
                let lpost = len(line) - len(post0)
                let cpre = s:Col(lpre, a:mode) + 1
                let cpost = s:Col(lpost, a:mode) + 1
                let col = s:Col(pos[2], a:mode)
                " TLogVAR col, cpre, cpost
                if col >= cpre && col <= cpost
                    let spre = strpart(line, 0, lpre)
                    let spost = line[lpost : -1]
                    " TLogVAR pre0, post0
                    " TLogVAR spre, spost
                    if spre == pre0 && (empty(spost) || spost == post0)
                        let replacement = line[lpre : lpost - 1]
                        let placeholder = replacement[-len(w:stakeholders.placeholder) : -1]
                        " TLogVAR replacement, placeholder, w:stakeholders.placeholder
                        if !init || placeholder != w:stakeholders.placeholder
                            if init
                                call s:Init(w:stakeholders, pos)
                            endif
                            let w:stakeholders.replacement = replacement
                            " TLogVAR w:stakeholders.replacement
                            let pos = w:stakeholders.Update(pos)
                            return
                        endif
                    endif
                endif
            endif
        endif
        let pos = s:SetContext(pos, a:mode)
    finally
        call setpos('.', pos)
    endtry
endf


function! s:Enter() "{{{3
endf


function! s:Leave() "{{{3
endf


function! s:Init(ph_def, pos) "{{{3
    let a:ph_def.lnum = a:pos[1]
    " TLogVAR getline(a:ph_def.lnum)
    let a:ph_def.lines = {}
    let a:ph_def.placeholder_rx = '\V'. escape(a:ph_def.placeholder, '\')
    let pre_fmt = substitute(a:ph_def.pre, '%', '%%', 'g')
    let post_fmt = substitute(a:ph_def.post, '%', '%%', 'g')
    let a:ph_def.prepost_rx_fmt = '\V\^\('
                \ . substitute(pre_fmt, a:ph_def.placeholder_rx, '\\(\\.\\{-}\\)', 'g')
                \ .'\)%s\('
                \ . substitute(post_fmt, a:ph_def.placeholder_rx, '\\(\\.\\{-}\\)', 'g')
                \ .'\)\$'
    " TLogVAR a:ph_def
    try
        exec 'keepjumps g/'. escape(a:ph_def.placeholder_rx, '/') .'/let a:ph_def.lines[line(".")] = getline(".")'
    finally
        keepjumps call setpos('.', a:pos)
    endtry
    call stakeholders#{g:stakeholders#expansion}#Init(a:ph_def)
endf


" :nodoc:
function! stakeholders#Replace(ph_def, text) "{{{3
    return substitute(a:text, a:ph_def.placeholder_rx, escape(a:ph_def.replacement, '\&~'), 'g')
endf


" :nodoc:
function! stakeholders#ReplacePlaceholderInCurrentLine(ph_def, pos, line, rline) "{{{3
    let m = matchlist(a:rline, printf(a:ph_def.prepost_rx_fmt, a:ph_def.replacement))
    " TLogVAR m
    if empty(m)
        let n1 = len(a:ph_def.pre)
        echom "Internal error stakeholders#ReplacePlaceholderInCurrentLine:" a:rline a:ph_def.prepost_rx_fmt
    else
        let n1 = len(m[1])
    endif
    let pre = stakeholders#Replace(a:ph_def, a:ph_def.pre)
    let n2 = len(pre)
    let post = stakeholders#Replace(a:ph_def, a:ph_def.post)
    let line1 = pre . a:ph_def.replacement . post
    " echom "DBG End" n1 n2 pre
    let pos = copy(a:pos)
    if n1 != n2
        let delta = - n1 + n2
        let pos[2] += delta
    endif
    return [pos, line1]
endf


finish

n1: foo <+FOO+> bar
n2: foo <+FOO+> bar bla <+FOO+> bla
<+FOO+> bar bla <+FOO+>
foo <+FOO+> bar bla <+FOO+>

