CC=gcc
REV=$(shell sh -c 'git rev-parse --short @{0}')
DEDICATED_CFLAGS=-O2 -g $(CFLAGS) -DVERSION=\"git~$(REV)\"
DLL_CFLAGS=-O0 -s -Wall -g0 -DCNCNET_REV=\"$(REV)\"
CLIENT_CFLAGS=-pedantic -Wall -Os -s -Wall -I. -Ires -DCNCNET_VERSION=\"$(REV)\" -DRELEASE

all: cncnet-dedicated cncnet.dll cncnet.exe

cncnet-dedicated: src/dedicated.c src/net.c src/net.h src/log.c
	$(CC) $(DEDICATED_CFLAGS) -o cncnet-dedicated src/dedicated.c src/net.c src/log.c

cncnet-dedicated.exe: src/dedicated.c src/net.c src/net.h src/log.c
	i686-w64-mingw32-gcc $(DEDICATED_CFLAGS) -o cncnet-dedicated.exe src/dedicated.c src/net.c src/log.c -lws2_32

cncnet.dll: src/dll.c src/net.c res/dll.def
	sed 's/__REV__/$(REV)/g' res/dll.rc.in | sed 's/__FILE__/cncnet/g' | sed 's/__GAME__/CnCNet Internet DLL/g' | i686-w64-mingw32-windres -O coff -o res/dll.o
	i686-w64-mingw32-gcc $(DLL_CFLAGS) -Wl,--enable-stdcall-fixup -shared -s -o cncnet.dll src/dll.c src/net.c res/dll.def res/dll.o -lws2_32

cncnet.dll.xz: cncnet.dll
	xz -C crc32 -9 -c cncnet.dll > cncnet.dll.xz

cncnet.exe: cncnet.dll.xz res/cncnet.rc.in src/client.c src/wait.c src/update.c src/download.c src/connect.c src/settings.c src/test.c src/http.c src/config.c src/net.c
	sed 's/__REV__/$(REV)/g' res/cncnet.rc.in | i686-w64-mingw32-windres -o res/cncnet.rc.o
	i686-w64-mingw32-gcc $(CLIENT_CFLAGS) -mwindows -o cncnet.exe src/client.c src/wait.c src/update.c src/download.c src/connect.c src/settings.c src/test.c src/http.c src/config.c src/net.c xz/xz_crc32.c xz/xz_dec_lzma2.c xz/xz_dec_stream.c res/cncnet.rc.o -Wl,--file-alignment,512 -Wl,--gc-sections -lws2_32 -lwininet -lcomctl32
	echo $(REV) > version.txt

clean:
	rm -f cncnet-dedicated cncnet-dedicated.exe cncnet.dll cncnet.dll.xz cncnet.exe res/*.o
