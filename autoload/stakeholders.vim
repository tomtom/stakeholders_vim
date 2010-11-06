" stakeholders.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-11-02.
" @Last Change: 2010-11-06.
" @Revision:    422


if exists('loaded_stakeholders')
    " finish
endif
let loaded_stakeholders = 1


if !exists('g:stakeholders#rx')
    let g:stakeholders#rx = '<+\([[:uppper:]_]\+\)+>'   "{{{2
endif


if !exists('g:stakeholders#expansion')
    let g:stakeholders#expansion = 'delayed'   "{{{2
endif


augroup stakeholders
    autocmd!
    " autocmd BufWinEnter,WinEnter * call s:Enter()
    " autocmd WinLeave * call s:Leave()
augroup END


function! stakeholders#Disable() "{{{3
    augroup stakeholders
        autocmd! stakeholders BufEnter *
    augroup END
endf


" function! stakeholders#Enable() "{{{3
"     augroup stakeholders
"         autocmd BufNew,BufNewFile * call stakeholders#EnableBuffer()
"     augroup END
" endf


function! stakeholders#EnableInRange(line1, line2) "{{{3
    if !exists('b:stakeholders')
        let b:stakeholders_range = [a:line1, a:line2]
        call stakeholders#EnableBuffer()
    endif
endf


function! stakeholders#EnableBuffer() "{{{3
    if !exists('b:stakeholders')
        let b:stakeholders = exists('b:stakeholders_rx') ? 
                    \ b:stakeholders_rx : g:stakeholders#rx
        autocmd stakeholders CursorMoved <buffer> call s:CursorMoved('n')
        autocmd stakeholders CursorMovedI <buffer> call s:CursorMoved('i')
        call s:CursorMoved('n')
    endif
endf


function! stakeholders#DisableBuffer() "{{{3
    if exists('b:stakeholders')
        unlet! b:stakeholders b:stakeholders_range
        autocmd! stakeholders CursorMoved,CursorMovedI <buffer>
    endif
endf


function! s:SetContext(pos) "{{{3
    if !exists('b:stakeholders')
        return a:pos
    endif
    let pos = a:pos
    if exists('w:stakeholders.End')
        let pos = w:stakeholders.End(pos)
    endif
    if exists('b:stakeholders_range') && (pos[1] < b:stakeholders_range[0] || pos[1] > b:stakeholders_range[1])
        call stakeholders#DisableBuffer()
    else
        let w:stakeholders = {
                    \ 'lnum': line('.')
                    \ }
        let line = getline('.')
        if line !~ b:stakeholders
            let line = ''
        endif
        let w:stakeholders.line = line
        let w:stakeholders.parts = s:GetParts(line)
        " TLogVAR w:stakeholders
    endif
    return pos
endf


function! s:GetParts(line) "{{{3
    return split(a:line, b:stakeholders .'\zs')
endf


function! s:CursorMoved(mode) "{{{3
    " TLogVAR line('.')
    let pos = getpos('.')
    try
        let lnum = line('.')
        if !exists('w:stakeholders') || w:stakeholders.lnum != lnum
            let pos = s:SetContext(pos)
        elseif !empty(w:stakeholders.line)
            let line = getline('.')
            if line != w:stakeholders.line
                let ph_rx = b:stakeholders .'$'
                " n1: foo <+TODO+> bar
                " n2: foo <+TODO+> bar bla <+TODO+> bla
                " obs:  foo <+TODO+> bar bla <+TODO+> bla
                " ign:  oo <+TODO+> bar bla <+TODO+> bla
                " ign:  oo aaaassadlkjsdkjalks bar bla aaaassadlkjsdkjalks bla
                " TODO: check only the part where the cursor is
                let set_context = 1
                let pcol = 1
                let ccol = col('.')
                let prefix = ''
                if has_key(w:stakeholders, 'replacement')
                    let pre = w:stakeholders.ReplacePlaceholderInPart(w:stakeholders.pre)
                    let post = w:stakeholders.ReplacePlaceholderInPart(w:stakeholders.post)
                    let line = getline('.')
                    if ccol > len(pre) && ccol <= len(line) - len(post) + 1
                        let w:stakeholders.pre_rx = escape(pre, '\')
                        let w:stakeholders.post_rx = escape(post, '\')
                        let repl_rx = '\V\^'. w:stakeholders.pre_rx .'\zs\(\.\{-}\)\ze'. w:stakeholders.post_rx .'\$'
                        let w:stakeholders.replacement = matchstr(line, repl_rx)
                        " echom "DBG w:stakeholders" string(w:stakeholders)
                        let pos = w:stakeholders.Update(pos)
                        " echom "DBG w:stakeholders" string(w:stakeholders.replacement)
                        let set_context = 0
                    endif
                else
                    let parts = s:GetParts(line)
                    " TLogVAR parts
                    let top = len(parts)
                    " TLogVAR ccol
                    for i in range(top)
                        let pa = get(w:stakeholders.parts, i, '')
                        let pb = parts[i]
                        " TLogVAR pa, pb
                        if pa != pb && pa =~ ph_rx
                            let ph = matchstr(pa, ph_rx)
                            let ph_pb = pb[-len(ph) - 1 : -1]
                            let rest = w:stakeholders.parts[i + 1 : -1]
                            " TLogVAR ph, ph_pb
                            if ph_pb != ph || parts[i + 1 : -1] != rest
                                let pre = pa[0 : -len(ph) - 1]
                                let pre = prefix . pre
                                let pre_rx = escape(pre, '\')
                                let post = join(rest, '')
                                let post_rx = escape(post, '\')
                                let repl_rx = '\V\^'. pre_rx .'\zs\(\.\{-}\)\ze'. post_rx .'\$'
                                let w:stakeholders.replacement = matchstr(line, repl_rx)
                                let w:stakeholders.pre = pre
                                let w:stakeholders.pre_rx = pre_rx
                                let w:stakeholders.post = post
                                let w:stakeholders.post_rx = post_rx
                                call s:Init(w:stakeholders, ph)
                                let pos = w:stakeholders.Update(pos)
                                " echom "DBG w:stakeholders" string(w:stakeholders)
                                let set_context = 0
                                break
                            endif
                        endif
                        let prefix .= pb
                        let pcol += len(pb)
                        if pcol > ccol
                            break
                        endif
                    endfor
                endif

                " TLogVAR set_context
                if set_context
                    let pos = s:SetContext(pos)
                endif
            endif
        endif
    finally
        call setpos('.', pos)
    endtry
endf


function! s:Enter() "{{{3
    " if exists('b:stakeholders')
    "     call s:SetContext(getpos('.'))
    " endif
endf


function! s:Leave() "{{{3
endf


function! s:Init(ph_def, placeholder) "{{{3
    let a:ph_def.placeholder = a:placeholder
    let a:ph_def.lnum = line('.')
    let a:ph_def.lines = {}
    let a:ph_def.col = len(a:ph_def.pre)
    let a:ph_def.placeholder_rx = '\V'. escape(a:ph_def.placeholder, '\')
    let a:ph_def.prepost_rx_fmt = '\V\^\('
                \ . substitute(a:ph_def.pre, a:ph_def.placeholder_rx, '\\(\\.\\{-}\\)', 'g')
                \ .'\)%s\('
                \ . substitute(a:ph_def.post, a:ph_def.placeholder_rx, '\\(\\.\\{-}\\)', 'g')
                \ .'\)\$'
    let pos = getpos('.')
    try
        exec 'keepjumps g/'. escape(a:ph_def.placeholder_rx, '/') .'/let a:ph_def.lines[line(".")] = getline(".")'
    finally
        keepjumps call setpos('.', pos)
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
    if empty(m)
        let n1 = len(a:ph_def.pre)
        echom "Internal error" a:rline a:ph_def.prepost_rx_fmt
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

