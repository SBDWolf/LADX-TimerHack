IF NOT EXIST output_rom mkdir output_rom
del /q output_rom
copy source_rom\source.gbc output_rom\output.gbc
rgbds-0.9.1\rgbasm.exe -o output_rom\ladx.o src\main.asm
rgbds-0.9.1\rgblink -O source_rom\source.gbc -o output_rom\ladx_j1.0_timerhack_v1.0.gbc output_rom\ladx.o
del output_rom\ladx.o