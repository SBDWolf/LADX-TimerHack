; md5 ??????

; ROMBANKS 64
; ROM "Zelda no Densetsu - Yume o Miru Shima DX (Japan) (SGB Enhanced).gbc"


; config
DEF is_cgb EQU 1
DEF current_rom_bank EQU $dbaf
DEF game_uses_save_ram EQU 1
DEF uses_mbc5 EQU 1


; joypad
DEF joypad EQU $ffcb
DEF joypad_2 EQU $ffcc
DEF swap_joypad EQU 1

SECTION "relocated read from joypad", ROM0[$0006]  ; note: manually changed to skip rom debug tool bytes at $0003-$0005 ; length: $003a
    INCLUDE "includes/relocated_read_from_joypad.asm"
ENDSECTION

SECTION "joypad read", ROM0[$2887] ; length: 4
    call relocated_read_from_joypad
    nop
ENDSECTION


; save/load state
SECTION "save/load state", ROMX[$7CF5], BANK[$0002] ; length: $0295
    DB "--- Save Patch ---"
    INCLUDE "includes/save_state_includes.asm"
ENDSECTION


; Generated with patch-builder.py
