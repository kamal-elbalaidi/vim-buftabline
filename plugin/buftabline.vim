" Vim global plugin for rendering the buffer list in the tabline
" Licence:     The MIT License (MIT)
" Commit:      $Format:%H$
" {{{ Copyright (c) 2015 Aristotle Pagaltzis <pagaltzis@gmx.de>
" 
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
" 
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
" 
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
" }}}

if v:version < 700
	echoerr printf('Vim 7 is required for buftabline (this is only %d.%d)',v:version/100,v:version%100)
	finish
endif

scriptencoding utf-8

hi default link BufTabLineCurrent         TabLineSel
hi default link BufTabLineActive          PmenuSel
hi default link BufTabLineHidden          TabLine
hi default link BufTabLineFill            TabLineFill
hi default link BufTabLineModifiedCurrent BufTabLineCurrent
hi default link BufTabLineModifiedActive  BufTabLineActive
hi default link BufTabLineModifiedHidden  BufTabLineHidden

let g:buftabline_numbers       = get(g:, 'buftabline_numbers',        0)
let g:buftabline_indicators    = get(g:, 'buftabline_indicators',     1)
let g:buftabline_separators    = get(g:, 'buftabline_separators',     0)
let g:buftabline_show          = get(g:, 'buftabline_show',           3)
let g:buftabline_plug_max      = get(g:, 'buftabline_plug_max',      10)
let g:buftabline_tab_width     = get(g:, 'buftabline_tab_width',     20)
let g:buftabline_separator     = get(g:, 'buftabline_separator',    '|')
let g:buftabline_mark_modified = get(g:, 'buftabline_mark_modified','+')

function! buftabline#user_buffers() " help buffers are always unlisted, but quickfix buffers are not
	return filter(range(1,bufnr('$')),'buflisted(v:val) && "quickfix" !=? getbufvar(v:val, "&buftype")')
endfunction

function! s:switch_buffer(bufnum, clicks, button, mod)
	execute 'buffer' a:bufnum
endfunction

function s:SID()
	return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

let s:dirsep = fnamemodify(getcwd(),':p')[-1:]
let s:centerbuf = winbufnr(0)
let s:tablineat = has('tablineat')
let s:sid = s:SID() | delfunction s:SID
function! s:center_string(str, width)
    let spaces = a:width - strwidth(a:str)
    let left_spaces = spaces / 2
    let right_spaces = spaces - left_spaces
    return repeat(' ', left_spaces) . a:str . repeat(' ', right_spaces)
endfunction

function! buftabline#render()
    let show_num = g:buftabline_numbers == 1
    let show_ord = g:buftabline_numbers == 2
    let show_mod = g:buftabline_indicators
    let tab_width = g:buftabline_tab_width
    let lpad = g:buftabline_separators ? nr2char(0x23B8) : ' '

    let bufnums = buftabline#user_buffers()
    let centerbuf = s:centerbuf
    let currentbuf = winbufnr(0)
    let tabs = []
    let screen_num = 0

    for bufnum in bufnums
        let screen_num = show_num ? bufnum : show_ord ? screen_num + 1 : ''
        let tab = { 'num': bufnum, 'label': '', 'pre': '', 'width': 0 }
        let tab.hilite = currentbuf == bufnum ? 'Current' : bufwinnr(bufnum) > 0 ? 'Active' : 'Hidden'
        
        if currentbuf == bufnum | let [centerbuf, s:centerbuf] = [bufnum, bufnum] | endif
        
        let bufname = bufname(bufnum)
        if strlen(bufname)
            let tab.label = fnamemodify(bufname, ':t')
        elseif -1 < index(['nofile','acwrite'], getbufvar(bufnum, '&buftype'))
            let tab.label = show_mod ? screen_num . ' !' : screen_num ? screen_num . ' !' : '!'
        else
            let tab.label = screen_num ? screen_num : 'No Name'
        endif

        let pre = screen_num
        if getbufvar(bufnum, '&mod')
            let tab.hilite = 'Modified' . tab.hilite
            if show_mod | let pre = g:buftabline_mark_modified . pre | endif
            let tab_width -=strwidth(pre)+1
          endif

        if strlen(pre) | let tab.pre = pre . ' ' | endif

        let available_width = tab_width - 2  " -2 for padding
        if strwidth(tab.label) > available_width
            let tab.label = strpart(tab.label, 0, available_width - 3) . '...'
        endif
        let tab.label = s:center_string(tab.label, available_width)

        let tabs += [tab]
    endfor

    " Center the current buffer
    let lft = { 'lasttab': 0, 'cut': '.', 'indicator': '<', 'width': 0, 'half': &columns / 2 }
    let rgt = { 'lasttab': -1, 'cut': '.$', 'indicator': '>', 'width': 0, 'half': &columns - lft.half }
    
    let currentside = lft
    let lpad_width = strwidth(lpad)
    for tab in tabs
        let tab.width = lpad_width + strwidth(tab.pre) + strwidth(tab.label) + 1
        let tab.label = lpad . tab.pre . substitute(strtrans(tab.label), '%', '%%', 'g') . ' '
        if centerbuf == tab.num
            let halfwidth = tab.width / 2
            let lft.width += halfwidth
            let rgt.width += tab.width - halfwidth
            let currentside = rgt
            continue
        endif
        let currentside.width += tab.width
        let currentside.width += strwidth(g:buftabline_separator)+1
      endfor

    " Trim tabs if they exceed screen width
    if (lft.width + rgt.width) > &columns
        let oversized = lft.width < lft.half ? [ [ rgt, &columns - lft.width ] ] :
                        \ rgt.width < rgt.half ? [ [ lft, &columns - rgt.width ] ] :
                        \ [ [ lft, lft.half ], [ rgt, rgt.half ] ]
        for [side, budget] in oversized
            let delta = side.width - budget
            while delta >= tabs[side.lasttab].width
                let delta -= remove(tabs, side.lasttab).width
            endwhile
            let endtab = tabs[side.lasttab]
            while delta > (endtab.width - strwidth(strtrans(endtab.label)))
                let endtab.label = substitute(endtab.label, side.cut, '', '')
            endwhile
            let endtab.label = substitute(endtab.label, side.cut, side.indicator, '')
        endfor
    endif

    if len(tabs) | let tabs[0].label = substitute(tabs[0].label, lpad, ' ', '') | endif

    let tabline = ''
    let separator = '%#BufTabLineFill#' . g:buftabline_separator

    for tab in tabs
        let tabline .= '%#BufTabLine'  . tab.hilite . '#'
        let tabline .= '%' . tab.num . '@' . s:sid . 'switch_buffer@'
        let tabline .= substitute(tab.label, '%', '%%', 'g')  .separator
    endfor

    let tabline .= '%#BufTabLineFill#%T'
    return tabline
    " return tabline .g:buftabline_separator 
endfunction

function! buftabline#update(zombie)
	set tabline=
	if tabpagenr('$') > 1 | set guioptions+=e showtabline=2 | return | endif
	set guioptions-=e
	if 0 == g:buftabline_show
		set showtabline=1
		return
	elseif 1 == g:buftabline_show
		" account for BufDelete triggering before buffer is actually deleted
		let bufnums = filter(buftabline#user_buffers(), 'v:val != a:zombie')
		let &g:showtabline = 1 + ( len(bufnums) > 1 )
	elseif 2 == g:buftabline_show
		set showtabline=2
	endif
	set tabline=%!buftabline#render()
endfunction

augroup BufTabLine
autocmd!
autocmd VimEnter  * call buftabline#update(0)
autocmd TabEnter  * call buftabline#update(0)
autocmd BufAdd    * call buftabline#update(0)
autocmd FileType qf call buftabline#update(0)
autocmd BufDelete * call buftabline#update(str2nr(expand('<abuf>')))
augroup END

for s:n in range(1, g:buftabline_plug_max) + ( g:buftabline_plug_max > 0 ? [-1] : [] )
	let s:b = s:n == -1 ? -1 : s:n - 1
	execute printf("noremap <silent> <Plug>BufTabLine.Go(%d) :<C-U>exe 'b'.get(buftabline#user_buffers(),%d,'')<cr>", s:n, s:b)
endfor
unlet! s:n s:b

if v:version < 703
	function s:transpile()
		let [ savelist, &list ] = [ &list, 0 ]
		redir => src
			silent function buftabline#render
		redir END
		let &list = savelist
		let src = substitute(src, '\n\zs[0-9 ]*', '', 'g')
		let src = substitute(src, 'strwidth(strtrans(\([^)]\+\)))', 'strlen(substitute(\1, ''\p\|\(.\)'', ''x\1'', ''g''))', 'g')
		return src
	endfunction
	exe "delfunction buftabline#render\n" . s:transpile()
	delfunction s:transpile
endif
