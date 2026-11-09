cd "$(dirname "$0")"
mkdir -p out dcu
SRC=C:/Progetti/DelphiDoom/Reference/_dati/radix_indagine/src
"/c/Program Files (x86)/Embarcadero/Studio/22.0/bin/dcc32.exe" -GD -DDOOM -B -Q -W- -H+ "-NSVcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;Bde" -Eout -N0dcu "-U$SRC;$SRC/Radix;$SRC/Base;$SRC/Common;$SRC/C_LIB;$SRC/C_LIB/obj;$SRC/C_LIB/src;$SRC/ZLIB;$SRC/JPEGLIB;$SRC/TEXLIB;$SRC/SCRIPT;$SRC/MP3LIB;$SRC/MIKWIN;$SRC/AUDIOLIB;$SRC/FASTMM4;$SRC/FASTCODE;$SRC/OPENGL" "-I$SRC;$SRC/Radix" "-R$SRC" $1 > build.log 2>&1
tail -30 build.log
