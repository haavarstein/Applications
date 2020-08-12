@echo off
cls

Echo Running BISF...
PUSHD "%ProgramFiles(x86)%\Base Image Script Framework (BIS-F)"
CALL "PrepareBaseImage.cmd""
POPD
