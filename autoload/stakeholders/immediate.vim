" immediate.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-11-05.
" @Last Change: 2010-11-13.
" @Revision:    33



let s:prototype = {} "{{{2

" Expand placeholders as the user types.
function! stakeholders#immediate#Init(ph_def) "{{{3
    call extend(a:ph_def, s:prototype)
    return a:ph_def
endf


" :nodoc:
function! s:prototype.Update(pos) dict "{{{3
    if a:pos[1] == line('.')
        let pos = a:pos
        for [lnum, line] in items(self.lines)
            if lnum == self.lnum
                let [pos, line1] = stakeholders#ReplacePlaceholderInCurrentLine(self, pos, self.line, getline('.'))
            else
                let line1 = stakeholders#Replace(self, line)
            endif
            keepjumps call setline(lnum, line1)
        endfor
    endif
    return pos
endf


" :nodoc:
function! s:prototype.End(pos) dict "{{{3
    unlet self.placeholder
    return a:pos
endf


" :nodoc:
function! s:prototype.ReplacePlaceholderInPart(text) dict "{{{3
    return stakeholders#Replace(self, a:text)
endf


function! s:ReplacePlaceholderInCurrentLine(ph_def, text, pos) "{{{3
    let parts = split(a:text, a:ph_def.placeholder_rx, 1)
    let line = join(parts, a:ph_def.replacement)
    let pos = a:pos
    if len(parts) > 2
        let delta = a:ph_def.replacement - len(a:ph_def.placeholder)
        echom "DBG ReplacePlaceholderInCurrentLine 0" string(pos) delta
        let col = 1
        let max = pos[2] + len(a:ph_def.replacement)
        for i in range(len(parts))
            let part = parts[i]
            let col += len(part)
            echom "DBG ReplacePlaceholderInCurrentLine 1" a:ph_def.col col string(pos)
            if col >= a:ph_def.col || col > max
                break
            endif
            if i > 0
                let pos[2] += delta
                let a:ph_def.col += delta
            endif
        endfor
        echom "DBG ReplacePlaceholderInCurrentLine 2" string(pos)
        " let line = substitute(a:text, a:ph_def.placeholder_rx, escape(a:ph_def.replacement, '\&~'), 'g')
    endif
    return [pos, line]
endf

