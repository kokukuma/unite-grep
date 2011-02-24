"=============================================================================
" FILE: grep.vim
" AUTHOR:  Tomohiro Nishimura <tomohiro68@gmail.com>
" Last Modified: 24 Feb 2011.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================
"
" Description:
"   You can grep with unite interactive.
"   And use grep action on file/buffer kind.
"
" Usage:
"   :Unite grep:target:-options -input=pattern
"   (:Unite grep:~/.vim/autoload/unite/sources:-iR -input=file)
"
" Special Target:
"   %         : Current buffer name
"   #         : Alternate buffer name
"   $buffers  : All buffer names
"
" Setting Examples:
"   let g:unite_source_grep_default_opts = '-iRHn'
"
" TODO:
"   * show current target
"   * support ignore pattern
"   * the goal is general unix command source :)
"
" Variables  "{{{
call unite#util#set_default('g:unite_source_grep_command', 'grep')
call unite#util#set_default('g:unite_source_grep_default_opts', '-Hn')
call unite#util#set_default('g:unite_source_grep_max_candidates', 100)
"}}}

" Actions "{{{
let s:action_grep_file = {
  \   'description': 'grep this files',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_file.func(candidates) "{{{
  call unite#start([insert(map(copy(a:candidates), 'v:val.action__path'), 'grep')])
endfunction "}}}

let s:action_grep_directory = {
  \   'description': 'grep this directory',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_directory.func(candidates) "{{{
  call unite#start([insert(map(copy(a:candidates), 'v:val.action__directory'), 'grep')])
endfunction "}}}
if executable(g:unite_source_grep_command)
  call unite#custom_action('file,buffer', 'grep', s:action_grep_file)
  call unite#custom_action('file,buffer', 'grep_directory', s:action_grep_directory)
endif
" }}}

function! unite#sources#grep#define() "{{{
  if !exists('*unite#version') || unite#version() <= 100
    echoerr 'Your unite.vim is too old.'
    echoerr 'Please install unite.vim Ver.1.1 or above.'
    return []
  endif

  return executable('grep') ? s:grep_source : []
endfunction "}}}

let s:grep_source = {
  \   'name': 'grep',
  \   'max_candidates': g:unite_source_grep_max_candidates,
  \   'hooks' : {},
  \ }

function! s:grep_source.hooks.on_init(args, context) "{{{
  let l:target  = get(a:args, 0, '')
  if type(l:target) != type([])
    if l:target =~ '^-'
      let l:target  = get(a:args, 1, '')
    endif

    if l:target == ''
      let l:target = input('Target: ', '', 'file')
    endif

    if l:target == '%' || l:target == '#'
      let l:target = unite#util#escape_file_searching(bufname(l:target))
    elseif l:target ==# '$buffers'
      let l:target = join(map(filter(range(1, bufnr('$')), 'buflisted(v:val)'),
            \ 'unite#util#escape_file_searching(bufname(v:val))'))
    endif

    let a:context.source__target = [l:target]
  else
    let a:context.source__target = l:target
  endif

  let a:context.source__input = input('Pattern: ')

  call unite#print_message('[grep] Target: ' . join(a:context.source__target))
  call unite#print_message('[grep] Pattern: ' . a:context.source__input)
endfunction"}}}

function! s:grep_source.gather_candidates(args, context) "{{{
  if empty(a:context.source__target)
    return []
  endif

  let l:extra_opts = get(a:args, 0, '') =~ '^-' ?
        \ a:args[0] : get(a:args, 1, '')

  let l:candidates = map(filter(split(
    \ unite#util#system(printf(
    \   '%s %s %s %s %s',
    \   g:unite_source_grep_command,
    \   g:unite_source_grep_default_opts,
    \   a:context.source__input,
    \   join(a:context.source__target),
    \   l:extra_opts)),
    \  "\n"), 'v:val =~ "^.\\+:.\\+:.\\+$"'), '[v:val, split(v:val[2:], ":")]')

  return map(l:candidates,
    \ '{
    \   "word": v:val[0],
    \   "source": "grep",
    \   "kind": "jump_list",
    \   "action__path": v:val[0][:1].v:val[1][0],
    \   "action__line": v:val[1][1],
    \   "action__pattern": "^".unite#util#escape_pattern(join(v:val[1][2:], ":"))."$",
    \ }')
endfunction "}}}

" vim: foldmethod=marker
