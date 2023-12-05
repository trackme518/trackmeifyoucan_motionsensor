REM https://forum.espruino.com/conversations/316240/

@echo off
set scriptpath=%~dp0
set filename=moduleWifiSerial

set /p pport=Enter a Serial port name: 
echo %pport%
pause

REM "%scriptpath%esptool.exe" --port %pport% --baud 115200 --no-stub chip_id
REM "%scriptpath%esptool.exe" --port %pport% --baud 115200 --no-stub read_mac
REM "%scriptpath%esptool.exe" --port %pport% --baud 115200 --no-stub flash_id
REM pause

"%scriptpath%esptool.exe" --chip esp32s2 --port "%pport%" --baud 921600 write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 "%scriptpath%build\%filename%.ino.bootloader.bin" 0x8000 "%scriptpath%build\%filename%.ino.partitions.bin" 0xe000 "%scriptpath%boot_app0.bin" 0x10000 "%scriptpath%build\%filename%.ino.bin"

@pause
