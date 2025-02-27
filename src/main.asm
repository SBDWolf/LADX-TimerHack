; constants
DEF GAMEPLAY_FILE_SAVE               equ    $06
DEF GAMEPLAY_WORLD                   equ    $0b
DEF GAMEPLAY_WORLD_INTERACTIVE       equ    $07
DEF ROOM_TRANSITION_NONE             equ    $00

; I/O registers
DEF rSelectROMBank                   equ    $2100

; rom
DEF bank0_freeSpace                  equ    $0091 ; $91 to $ff - $100 gets executed as a nop
DEF bank1_freeSpace                  equ    $7f40
DEF bank0_vblankLag_hijack           equ    $0490
DEF bank0_vblankDone                 equ    $0569
DEF bank0_renderLoop_hook            equ    $01de
DEF bank0_SwitchBank                 equ    $080c
DEF bank0_ReloadSavedBank            equ    $081d

; ram
DEF wRoomTransitionState             equ    $c124
DEF wAlternateBackgroundEnabled      equ    $c500
DEF wDrawCommandsSize                equ    $d600 ; https://github.com/zladx/LADX-Disassembly/blob/4cf4654d904ace0b8df5aba1565a7ff227fda700/src/constants/memory/wram.asm#L2943
DEF wGameplayType                    equ    $db95
DEF wGameplaySubtype                 equ    $db96
DEF hRoomMap                         equ    $fff6
DEF hMapId                           equ    $fff7
DEF rSVBK                            equ    $ff70

; new ram
DEF wFrameCounterHigh                equ    $dd00
DEF wFrameCounterLow                 equ    $dd01
DEF wPreviousRoom                    equ    $dd02
DEF wPreviousLagFrames               equ    $dd03


SECTION "renderLoop_hook", ROM0[bank0_renderLoop_hook]
        call roomTimerEntry

SECTION "bank0_vblankLag_hijack", ROM0[bank0_vblankLag_hijack]
        jp nz, handleLagFrames

SECTION "bank0_newCode", ROM0[bank0_freeSpace]
    roomTimerEntry:
        ; switch to rom bank 1
        ld a, 1

        ld [rSelectROMBank], a

        call roomTimer

        ; restore hijacked instructions
        ld a, [wAlternateBackgroundEnabled] 

        ret

    handleLagFrames:
        ; we end up here from within the vblank code during a lag frame
        ld hl, wPreviousLagFrames
        inc [hl]
        ; return to the vblank code
        jp bank0_vblankDone

SECTION "roomTimer", ROMX[bank1_freeSpace], BANK[1]
    roomTimer:
        ; don't run if on title screen
        ld a, [wGameplayType]
        cp GAMEPLAY_FILE_SAVE
        jp c, .exit

        ; don't run if during regular gameplay and during a map transition
        cp GAMEPLAY_WORLD
        jr nz, .continue
        ld a, [wGameplaySubtype]
        cp GAMEPLAY_WORLD_INTERACTIVE
        jp nz, .exit

        ; don't run during a room transition. this fixes a rare crash that sometimes happens due to the game expecting a specific byte at $d601...
        ld a, [wRoomTransitionState]
        cp ROOM_TRANSITION_NONE
        jp nz, .exit
        

    .continue
        ; if the room or map has changed, print the timer on screen and then reset it
        ld a, [hRoomMap]
        ld hl, wPreviousRoom
        cp [hl]
        jr z, .incrementTimer

        ; print room time
        ld a, [wDrawCommandsSize]
        ld e, a
        ld d, $00
        add a, $07
        ld [wDrawCommandsSize], a
        ld hl, $d601
        add hl, de
        ld a, $9c
        ld [hl+], a
        ld a, $09
        ld [hl+], a
        ld a, $03
        ld [hl+], a

        ; first digit
        ld a, [wFrameCounterHigh]
        swap a
        and $0f
        add a, $b0
        ld [hl+], a

        ; second digit
        ld a, [wFrameCounterHigh]
        and $0f
        add a, $b0
        ld [hl+], a

        ; third digit
        ld a, [wFrameCounterLow]
        swap a
        and $0f
        add a, $b0
        ld [hl+], a

        ; fourth digit
        ld a, [wFrameCounterLow]
        and $0f
        add a, $b0
        ld [hl+], a

        ; reset room time
        xor a 

        ; apparently terminating the print command with a $00 is important to avoid corrupted graphics in some places
        ld [hl+], a

        ld [wFrameCounterHigh], a
        ld [wFrameCounterLow], a

    .incrementTimer
        ld hl, wPreviousLagFrames

        ; increment frames, using the daa instruction to store a binary-coded decimal
        ld a, [wFrameCounterLow]
        ld b, a
        ; prepare value of 1 + however many lag frames just occurred
        ld a, [hl]
        add a, 1
        daa
        ; increment timer by value that was just prepared
        ; done in this slightly roundabout way to allow the carry flag to be set when going over 99
        add a, b
        daa
        ld [wFrameCounterLow], a

        jr nc, .end
        
        ; same thing but with the high byte
        ld a, [wFrameCounterHigh]
        ld b, a
        ld a, [hl]
        add a, 1
        daa
        add a, b
        daa
        ld [wFrameCounterHigh], a

        jr nc, .end

        ; cap timer at 9999 frames
        ld a, $99
        ld [wFrameCounterHigh], a
        ld [wFrameCounterLow], a


    .end
        ld a, [hRoomMap]
        ld [wPreviousRoom], a

    .exit
        ; clear lag frames counter
        xor a
        ld [wPreviousLagFrames], a

        ret