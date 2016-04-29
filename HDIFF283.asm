.binarymode TI83
.unsquish
.TIVariableType $05

#include "ti83asm.inc"

.org userMem

Main:
Main_BeginTest1p1:
 ld b,4
Main_Loop_T1p1:
 call ResetFlags
 call Test1
 call AFtoRAM
 call AppendUndocFlags
 call UpdateTestingValue
 djnz Main_Loop_T1p1
Main_BeginTest1p2:
 ld a,(HLStorage)
 ld (NumberStorage+1),a
 ld b,4
Main_Loop_T1p2:
 call ResetFlagsHigh
 call Test1
 call AFtoRAM
 call AppendUndocFlags
 call UpdateTestingValue
 djnz Main_Loop_T1p2
Main_BeginTest2p1:
 ld a,(HLStorage)
 ld (NumberStorage),a
 ld b,4
Main_Loop_T2p1:
 call ResetFlags
 call Test2
 call AppendUndocFlags
 call UpdateTestingValue
 djnz Main_Loop_T2p1
Main_BeginTest2p2:
 ld a,(HLStorage)
 ld (NumberStorage+3),a
 ld b,4
Main_Loop_T2p2:
 call ResetFlagsHigh
 call Test2
 call AppendUndocFlags
 call UpdateTestingValue
 djnz Main_Loop_T2p2
Main_BeginTest3p1:
 ld a,(HLStorage)
 ld (NumberStorage+2),a
 ld b,4
Main_Loop_T3p1:
 call ResetFlags
 call Test2
 call AppendUndocFlags
 call UpdateTestingValue
 djnz Main_Loop_T3p1
Main_BeginTest3p2:
 ld a,(HLStorage)
 ld (NumberStorage+5),a
 ld b,4
Main_Loop_T3p2:
 call ResetFlagsHigh
 call Test2
 call AppendUndocFlags
 call UpdateTestingValue
 djnz Main_Loop_T3p2
Main_Loop_EndTests:
 ld a,(HLStorage)
 ld (NumberStorage+4),a
PrintResults:
 ld hl,NumberStorage
 ld b,3
PrintResults_Loop:
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 push hl
 ex de,hl
 call _DispHL
 call _NewLine
 pop hl
 djnz PrintResults_Loop
 ;detect Z180, this is the final test
DetectZ180:
 ld hl,$0202  ; values to multiply in each register
 .db $ed, $6c ; 2 * 2 = 4 will be in l if mult is present
 ld a,4       ; expected result
 cp l
 ret nz
 ld hl,Z180String
 call _puts
 ret
 
 ; I hope this code makes life easier
 
AFtoRAM:
 push hl
 push af
 pop hl
 ld (AFStorage),hl
 pop hl
 ret

AppendUndocFlags:
; so to use this, you put af into AFStorage, and hl into HLStorage
; keep in mind the result is only 8 bit, lower and
;  upper registers are the same after calling this
 push af
 push hl
 ld hl,(AFStorage) ; the flags
 ex de,hl          ; the flags are now in de, speficically e
 ld hl,(HLStorage) ; last answer
 ld a,l            ; last answer now in a
 sla a             ; to the left
 sla a             ; to the left
 bit 5,e
 call nz,AppendUndocFlags_Bit5 ;call z? idk
 bit 3,e
 call nz,AppendUndocFlags_Bit3
; call Neutral_DispA
 ld l,a
 ld h,l
 ld (HLStorage),hl
 pop hl
 pop af
 ret

AppendUndocFlags_Bit5:
 or %00000010
 ret

AppendUndocFlags_Bit3:
 or %00000001
 ret
 
 
 
 
 ;
 
 
 
UpdateTestingValue:
 ; this preserves all registers :D (until it reaches exit condition).
 ; it reads the testing value (0,8,$20,$28) and loads the next value
 ; into all memory positions. if $28 is already present, it goes to 
 ; Exit, which resets the testing values, resets b to 3 (4 iterations
 ; of each test), and branches to the appropriate test. 
 push af
 ld a,(OrValue_T1) ;OrValue_T1 should be the same as every other test value
 cp $28
 jp z,UpdateTestingValue_Done ;no more values to test
 bit 3,a
 jr z,UpdateTestingValue_Bit3
 add a,$08
UpdateTestingValue_Exit:
 ld (OrValue_T1),a
 ld (HLValue_T2+1),a
 ld (TestValue_T3+1),a
 pop af
 ret
UpdateTestingValue_Bit3:
 add a,$18
 jr UpdateTestingValue_Exit
 
UpdateTestingValue_Done:
 ; this gets called at the end of every testing loop (4 iterations)
 ; branches to appropriate test via LoopCounter byte
 pop af              ; af isn't preserved anyways
 ld a,0              ; reset the values when exit is jumped to
 ld (OrValue_T1),a
 ld (HLValue_T2+1),a
 ld (TestValue_T3+1),a
 ld a,(LoopCounter)
 inc a
 ld (LoopCounter),a
 cp 6
 jp z,Main_Loop_EndTests
 cp 1
 jp z,Main_Loop_T1p2
 cp 2
 jp z,Main_Loop_T2p1
 cp 3
 jp z,Main_Loop_T2p2
 cp 4
 jp z,Main_Loop_T3p1
 cp 5
 jp z,Main_Loop_T3p2
 jp Main_Loop_EndTests

Neutral_DispA:
 push af
 push bc
 push de
 push hl
 ld hl,0
 ld l,a
 call _DispHL
 call _NewLine
 pop hl
 pop de
 pop bc
 pop af
 ret

ResetFlags:
 push de
 ld de,$0000
 push de
 pop af
 pop de
 ret
 
ResetFlagsHigh:
 push de
 ld de,$ffff
 push de
 pop af
 pop de
 ret

Test1:
 xor a
 .db $f6
OrValue_T1:
 .db 0
 ret

Test2:
 push hl
 xor a
 .db $21
HLValue_T2:
 .dw 0
 ex (sp),hl
 ex (sp),hl
 bit 0,(hl)
 pop hl
 ret

Test3:
 push ix
 xor a
 .db $dd,$21
TestValue_T3:
 .dw 0
 bit 0,(ix+0)
 pop ix
 ret

; storages
 
LoopCounter:
 ; number of tests that have finished-ish executing
 .db 0
 
NumberStorage:
 .ds 6 ; size is [number of tests] * 2
 
AFStorage:
 .dw 0

HLStorage:
 .dw 0
 
Z180String:
 .db "Found Z180!",0

.squish
.db $3F,$D4,$3F,$30,$30,$30,$30,$3F,$D4
.end