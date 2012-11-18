# http://vim.wikia.com/wiki/Using_VimBall_with_make
PLUGIN = yavimim

SOURCE = plugin/yavimim.vim
SOURCE += autoload/Powerline/Segments/yavimim.vim
SOURCE += autoload/Powerline/Functions/yavimim.vim
SOURCE += autoload/yavimim.vim
SOURCE += autoload/yavimim/backend.vim
SOURCE += autoload/yavimim/cmdline.vim
SOURCE += autoload/yavimim/highlight.vim
SOURCE += autoload/yavimim/insert.vim
SOURCE += autoload/yavimim/powerline.vim
SOURCE += autoload/yavimim/punctuation.vim
SOURCE += autoload/yavimim/util.vim
SOURCE += autoload/yavimim/data/gbks2t.tab
SOURCE += autoload/yavimim/wubi/qq.txt
SOURCE += autoload/yavimim/wubi/qq_cht.txt
SOURCE += autoload/yavimim/wubi/wbpy.txt

all: ${PLUGIN}.vmb

archive: ${SOURCE}
	@tar Jcvf ${PLUGIN}.tar.xz ${SOURCE}

${PLUGIN}.vmb: ${SOURCE}
	@vim --cmd 'let g:plugin_name="${PLUGIN}"' -S build.vim -cq!
	@cp ${PLUGIN}.{vmb,vba}

.PHONY : clean
clean:
	-rm -f ${PLUGIN}.{vmb,vba,tar.xz}
