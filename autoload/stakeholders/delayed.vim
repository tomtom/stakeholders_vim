" delayed.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-11-05.
" @Last Change: 2010-11-05.
" @Revision:    53



let s:prototype = {} "{{{2
function! stakeholders#delayed#Init(ph_def) "{{{3
    call extend(a:ph_def, s:prototype)
    return a:ph_def
endf


function! s:prototype.Update(pos) dict "{{{3
    return a:pos
endf


function! s:prototype.End(pos) dict "{{{3
    echom "DBG delayed.End" self.placeholder
    let pos = a:pos
    for [lnum, line] in items(self.lines)
        if lnum == self.lnum
            let [pos, line1] = stakeholders#ReplacePlaceholderInCurrentLine(self, pos, line, getline('.'))
        else
            let line1 = stakeholders#Replace(self, line)
        endif
        keepjumps call setline(lnum, line1)
    endfor
    return pos
endf


function! s:prototype.ReplacePlaceholderInPart(text) dict "{{{3
    return a:text
endf


