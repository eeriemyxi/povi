#!/bin/sh

mkdir -p bin/windows
mkdir -p bin/windows/dlls
mkdir -p bin/linux

nimble c -d:ssl -d:release --opt:size --cpu:amd64 \
    -o:bin/linux/povi-amd64-linux.bin src/povi
nimble c -d:ssl -d:mingw -d:release --opt:size --cpu:amd64 \
    -o:bin/windows/povi-amd64-windows.exe src/povi

cd bin/windows
wget https://nim-lang.org/download/dlls.zip
unzip dlls.zip -d dlls

zip -j povi-amd64-windows.zip \
    povi-amd64-windows.exe \
    dlls/cacert.pem \
    dlls/libcrypto-1_1-x64.dll \
    dlls/libssl-1_1-x64.dll \
    dlls/pcre64.dll
