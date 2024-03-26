let g:chadtree_settings = {'xdg': v:true}

autocmd VimEnter * CHADopen --nofocus
autocmd bufenter * if (winnr("$") == 1 && &filetype == 'CHADtree') | q | endif 
