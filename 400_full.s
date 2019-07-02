;;
;; This is the disassembled 3B2 Model 400 ROM. I'm attempting to trace it to
;; the best of my ability to understand what the 3B2 does at startup.
;;
;; Disassembled with:
;;
;;    we32dis.rb -s 0x1274 -i 400_full.bin > disassembled.txt
;;

;;; Strings
628:	"SBD"
62c:	"\nEnter name of program to execute [ %s ]: "
659:	"passwd"
660:	"\nenter old password: "
676:	"\nenter new password: "
68c:	"\nconfirmation: "
69c:	"\n"
69e:	"newkey"
6a5:	"\nCreating a floppy key to enable clearing of saved NVRAM information.\n\n"
6ec:	"go"
6ef:	"Insert a formatted floppy, then type 'go' (q to quit): "
727:	"\nCreation of floppy key complete\n\n"
74a:	"sysdump"
752:	"version"
75a:	"\nCreated: %s\n"
768:	"Issue: %08lx\n"
776:	"Release: %s\nLoad: %s\n"
78c:	"Serial Number: %08lx\n\n"
7a3:	"q"
7a5:	"edt"
7a9:	"error info"
7b4:	"baud"
7b9:	"?"
7bb:	"Enter an executable or system file, a directory name,\n"
7f3:	"or one of the possible firmware program names:\n\n"
824:	"baud    edt    newkey    passwd    sysdump    version    q(uit)\n\n"
866:	"*VOID*"
86d:	"\tPossible load devices are:\n\n"
88b:	"Option Number    Slot     Name\n"
8ab:	"---------------------------------------\n"
8d4:	"      %2d         %2d"
8ea:	"*VOID*"
8f1:	"     %10s\n"
8fd:	"\nEnter Load Device Option Number "
91f:	"[%d"
923:	"*VOID*"
92a:	" (%s)"
930:	"]: "
936:	"\n%s is not a valid option number.\n"
959:	"Possible subdevices are:\n\n"
974:	"Option Number   Subdevice    Name\n"
997:	"--------------------------------------------\n"

;;; Exception Vector Table
;;; ----------------------
;;;
;;; Normal Exception Vector = 0x00000548 which points to 0x421F
;;;
;;; Interrupt Vector Table Pointers
;;; -------------------------------
;;;
;;; NMI Interrupt Handler
;;;
;;;   0x8C = 02000bc8
;;;
;;; Auto Vector Interrupts
;;;
;;;   0x090:  02000bc8
;;;   0x094:  02000bc8
;;;   0x098:  02000bc8
;;;   0x09C:  02000bc8
;;;   0x0A0:  02000bc8
;;;   0x0A4:  02000bc8
;;;   0x0A8:  02000bc8
;;;   0x0AC:  02000c18
;;;   0x0B0:  02000c68
;;;   0x0B4:  02000cb8
;;;   0x0B8:  02000d08
;;;   0x0BC:  02000d58
;;;   0x0C0:  0x200da8
;;;   0x0C4:  0x200da8
;;;   0x0C8:  0x200e48
;;;   0x0CC:  0x200bc8
;;;   0x0D0:  0x200bc8
;;;    ... [same] ...
;;;   0x104:  0x200bc8
;;;   0x108:  0x200bc8
;;;
;;; Device Interrupt Handlers
;;;
;;;   0x10c:  0x200bc8
;;;   0x110:  0x200bc8
;;;    ... [same] ...
;;;   0x484:  0x200bc8
;;;   0x488:  0x200bc8
;;;
;;;
;;; In all, there are 8 distinct interrupt PCBPs:
;;;
;;;    02000bc8
;;;    02000c18
;;;    02000c68
;;;    02000d08
;;;    02000cb8
;;;    02000d58
;;;    02000da8
;;;    02000e48


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Reset entry point. We start running here at power-up.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; Set up the stack pointer, frame pointer, argument pointer,
;; and the interrupt stack pointer.

00001274: 04 7f 08 00 00 02 4c                           MOVAW $0x2000008,%sp
0000127b: 04 7f 08 00 00 02 49                           MOVAW $0x2000008,%fp
00001282: 04 7f 08 00 00 02 4a                           MOVAW $0x2000008,%ap
00001289: 04 7f 08 08 00 02 4e                           MOVAW $0x2000808,%isp

;; Next we set some timers. These commands write to the 8253 programmable
;; timer chip and configure Counter 0 and Counter 2. It is as yet unknown what
;; these timers are used for or what they're connected to.

;; Send 0x16 to the command register of the 8253.
;; BCD=0, M=011, RL=01, SC=00
;; This selects counter 0, sets Read/Load to "Lest significant byte only",
;; and sets mode to "Mode 3" (Square Wave generator)

00001290: 87 16 7f 0f 20 04 00                           MOVB &0x16,$0x4200f
00001297: 70                                             NOP

;; Put 0x64 (SITINIT in firmware.h) into Counter 0

00001298: 87 6f 64 7f 03 20 04 00                        MOVB &0x64,$0x42003
000012a0: 70                                             NOP

;; Send 0x94 to the command register of the 8253.
;; BCD=0, M=010, RL=01, SC=10
;; This selects counter 2, sets Read/Load to "Least significant byte only",
;; and sets mode to "Mode 2" (Rate generator)

000012a1: 87 5f 94 00 7f 0f 20 04 00                     MOVB &0x94,$0x4200f
000012aa: 70                                             NOP

;; Puts 0xa into Counter 2

000012ab: 87 0a 7f 0b 20 04 00                           MOVB &0xa,$0x4200b
000012b2: 70                                             NOP

;; Send 0x74 to the command register of the 8253.
;; BCD=0, M=010, RL=11, SC=01
;; Select counter 1, sets Read/Load to "Least, then most SB",
;; then sets mode to "Mode 2" (Rate generator)

000012b3: 87 6f 74 7f 0f 20 04 00                        MOVB &0x74,$0x4200f
000012bb: 70                                             NOP

;; ... but oddly, we don't seem to do anything with timer 1, we just let it
;; sit there without loading any data into it, so its period is unknown.
;; Counter 1 (0x42007) is unused in the rest of the ROM!

;; Unconditional jump to 0x12d5 -- basically we skip the next block

000012bc: 24 7f d5 12 00 00                              JMP $0x12d5
000012c2: 70                                             NOP
000012c3: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Entry Point. Who jumps here?

000012c4: 10 43                                          SAVE %r3
000012c6: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
000012cd: 87 01 7f 1b 40 04 00                           MOVB &0x1,$0x4401b
000012d4: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Entry Point, but my current guess is that this is some
;; kind of sanity check or power-on self-test of the CPU.
;;

;;
;; Set the PSW's NZCV flags to all '0's, leaving the rest of the PSW
;; unaffected.
;;

000012d5: 70                                             NOP
000012d6: 84 4b 40                                       MOVW %psw,%r0
000012d9: b8 4f ff ff c3 ff 40                           ANDW2 &0xffc3ffff,%r0
000012e0: 84 40 4b                                       MOVW %r0,%psw

;;
;; Branches based on the state of the PSW after clearing
;; the NZCV bits. In short, each check looks to see if one
;; of the bits is set when it should not be set. If they
;; are, we jump to 0x1923. If not, we branch to the next
;; check.
;;

;; If (Z == 0), branch to 0x12e8
000012e3: 77 05                                          BNEB &0x5 <0x12e8>
;; No, branch to 0x1923
000012e5: 7a 3e 06                                       BRH &0x63e <0x1923>

;; If ((N|Z) == 0), branch to 0x12ed
000012e8: 47 05                                          BGB &0x5 <0x12ed>
;; No, branch to 0x1923
000012ea: 7a 39 06                                       BRH &0x639 <0x1923>

;; If ((N == 0)|(Z == 1)), branch to 0x12f2
000012ed: 43 05                                          BGEB &0x5 <0x12f2>
;; No, branch to 0x1923
000012ef: 7a 34 06                                       BRH &0x634 <0x1923>

;; If ((C|Z) == 0), branch to 0x12f7
000012f2: 57 05                                          BGUB &0x5 <0x12f7>
;; No, branch to 0x1923
000012f4: 7a 2f 06                                       BRH &0x62f <0x1923>

;; If (C == 0) branch to 0x12fc
000012f7: 53 05                                          BGEUB &0x5 <0x12fc>
;; No, branch to 0x1923
000012f9: 7a 2a 06                                       BRH &0x62a <0x1923>

;; if (C == 0) branch to 0x12fc
;; Why are we repeating this check?
000012fc: 53 05                                          BGEUB &0x5 <0x1301>
;; No, branch to 0x1923
000012fe: 7a 25 06                                       BRH &0x625 <0x1923>

;; if (V == 0) branch to 0x1306
00001301: 63 05                                          BVCB &0x5 <0x1306>
;; No, branch to 0x1923

;; We've fallen through.
;; Now we set the PSW's NZCV flags to all 1's.
00001303: 7a 20 06                                       BRH &0x620 <0x1923>
00001306: 70                                             NOP
00001307: 84 4b 40                                       MOVW %psw,%r0
0000130a: b0 4f 00 00 3c 00 40                           ORW2 &0x3c0000,%r0
00001311: 84 40 4b                                       MOVW %r0,%psw

;;
;; Now we do another check of the flags, very similar to
;; the behavior above. Each check looks to see if a flag
;; is clear when it should not be clear.
;;

;; If (Z == 1), branch to 0x1319
00001314: 7f 05                                          BEB &0x5 <0x1319>
;; No, branch to 0x1923
00001316: 7a 0d 06                                       BRH &0x60d <0x1923>

;; If ((N|Z) == 1), branch to 0x131e
00001319: 4f 05                                          BLEB &0x5 <0x131e>
;; No, branch to 0x1923
0000131b: 7a 08 06                                       BRH &0x608 <0x1923>

;; If ((N == 0) | (Z == 1)), branch to 0x1323
0000131e: 43 05                                          BGEB &0x5 <0x1323>
;; No, branch to 0x1923
00001320: 7a 03 06                                       BRH &0x603 <0x1923>

;; If ((C|Z) == 1), branch to 0x1328
00001323: 5f 05                                          BLEUB &0x5 <0x1328>
;; No, branch to 0x1923
00001325: 7a fe 05                                       BRH &0x5fe <0x1923>

;; If (C == 1), branch to 0x132d
00001328: 5b 05                                          BLUB &0x5 <0x132d>
;; No, branch to 0x1923
0000132a: 7a f9 05                                       BRH &0x5f9 <0x1923>

;; If (C == 1), branch to 0x1332.
;; Again, we repeat a check -- why?
0000132d: 5b 05                                          BLUB &0x5 <0x1332>
;; No, branch to 0x1923
0000132f: 7a f4 05                                       BRH &0x5f4 <0x1923>

;; If (V == 1), branch to 0x1337
00001332: 6b 05                                          BVSB &0x5 <0x1337>
;; No, branch to 0x1923
00001334: 7a ef 05                                       BRH &0x5ef <0x1923>

;; We've fallen through.
;; Time for some more self-testing!

00001337: 70                                             NOP
00001338: 84 4b 40                                       MOVW %psw,%r0
0000133b: b8 4f ff ff c3 ff 40                           ANDW2 &0xffc3ffff,%r0
00001342: b0 4f 00 00 10 00 40                           ORW2 &0x100000,%r0
00001349: 84 40 4b                                       MOVW %r0,%psw
0000134c: 43 05                                          BGEB &0x5 <0x1351>
0000134e: 7a d5 05                                       BRH &0x5d5 <0x1923>
00001351: 70                                             NOP
00001352: 84 4b 40                                       MOVW %psw,%r0
00001355: b8 4f ff ff c3 ff 40                           ANDW2 &0xffc3ffff,%r0
0000135c: b0 4f 00 00 04 00 40                           ORW2 &0x40000,%r0
00001363: 84 40 4b                                       MOVW %r0,%psw
00001366: 5e 06 00                                       BLEUH &0x6 <0x136c>
00001369: 7a ba 05                                       BRH &0x5ba <0x1923>
0000136c: 70                                             NOP
0000136d: 84 4b 40                                       MOVW %psw,%r0
00001370: b8 4f ff ff c3 ff 40                           ANDW2 &0xffc3ffff,%r0
00001377: b0 4f 00 00 20 00 40                           ORW2 &0x200000,%r0
0000137e: 84 40 4b                                       MOVW %r0,%psw
00001381: 4b 05                                          BLB &0x5 <0x1386>
00001383: 7a a0 05                                       BRH &0x5a0 <0x1923>

;; Put 0xff into R0, then rotate it through R1-R8

00001386: 84 ff 40                                       MOVW &-1,%r0
00001389: 84 40 41                                       MOVW %r0,%r1
0000138c: 84 41 42                                       MOVW %r1,%r2
0000138f: 84 42 43                                       MOVW %r2,%r3
00001392: 84 43 44                                       MOVW %r3,%r4
00001395: 84 44 45                                       MOVW %r4,%r5
00001398: 84 45 46                                       MOVW %r5,%r6
0000139b: 84 46 47                                       MOVW %r6,%r7
0000139e: 84 47 48                                       MOVW %r7,%r8
000013a1: 3c 40 48                                       CMPW %r0,%r8

;; If R0 != R8, fail.

000013a4: 76 7f 05                                       BNEH &0x57f <0x1923>

;; Success. Now left-shift R0 by 1, store in R0
000013a7: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0

;; Is zero flag set?
000013ab: 43 04                                          BGEB &0x4 <0x13af>
;; No, it's not, jump back and keep left-shifting until it is.
000013ad: 7b dc                                          BRB &0xdc <0x1389>

;; Next check:
000013af: 84 fe 40                                       MOVW &-2,%r0
000013b2: 88 40 41                                       MCOMW %r0,%r1
000013b5: 88 41 42                                       MCOMW %r1,%r2
000013b8: 88 42 43                                       MCOMW %r2,%r3
000013bb: 88 43 44                                       MCOMW %r3,%r4
000013be: 88 44 45                                       MCOMW %r4,%r5
000013c1: 88 45 46                                       MCOMW %r5,%r6
000013c4: 88 46 47                                       MCOMW %r6,%r7
000013c7: 88 47 48                                       MCOMW %r7,%r8
000013ca: 88 40 48                                       MCOMW %r0,%r8
000013cd: 88 41 47                                       MCOMW %r1,%r7
000013d0: 88 42 46                                       MCOMW %r2,%r6
000013d3: 88 43 45                                       MCOMW %r3,%r5
000013d6: 88 48 41                                       MCOMW %r8,%r1
000013d9: 88 47 42                                       MCOMW %r7,%r2
000013dc: 88 46 43                                       MCOMW %r6,%r3
000013df: 88 44 40                                       MCOMW %r4,%r0
000013e2: 88 41 44                                       MCOMW %r1,%r4
000013e5: 3c 40 48                                       CMPW %r0,%r8
000013e8: 76 3b 05                                       BNEH &0x53b <0x1923>
000013eb: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
000013ef: 4b 07                                          BLB &0x7 <0x13f6>
000013f1: 88 40 40                                       MCOMW %r0,%r0
000013f4: 7b be                                          BRB &0xbe <0x13b2>
000013f6: 84 49 41                                       MOVW %fp,%r1
000013f9: 84 4a 42                                       MOVW %ap,%r2
000013fc: 84 4c 43                                       MOVW %sp,%r3
000013ff: 84 4d 44                                       MOVW %pcbp,%r4
00001402: 84 4e 45                                       MOVW %isp,%r5
00001405: 84 ff 40                                       MOVW &-1,%r0
00001408: 84 40 49                                       MOVW %r0,%fp
0000140b: 84 49 4a                                       MOVW %fp,%ap
0000140e: 84 4a 4c                                       MOVW %ap,%sp
00001411: 84 4c 4d                                       MOVW %sp,%pcbp
00001414: 84 4d 4e                                       MOVW %pcbp,%isp
00001417: 3c 49 4e                                       CMPW %fp,%isp
0000141a: 76 4c 00                                       BNEH &0x4c <0x1466>
0000141d: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00001421: 43 04                                          BGEB &0x4 <0x1425>
00001423: 7b e5                                          BRB &0xe5 <0x1408>
00001425: 84 01 40                                       MOVW &0x1,%r0
00001428: 88 40 49                                       MCOMW %r0,%fp
0000142b: 88 49 4a                                       MCOMW %fp,%ap
0000142e: 88 4a 4c                                       MCOMW %ap,%sp
00001431: 88 4c 4d                                       MCOMW %sp,%pcbp
00001434: 88 4d 4e                                       MCOMW %pcbp,%isp
00001437: 88 49 4e                                       MCOMW %fp,%isp
0000143a: 88 4a 4d                                       MCOMW %ap,%pcbp
0000143d: 88 4c 49                                       MCOMW %sp,%fp
00001440: 88 4e 4a                                       MCOMW %isp,%ap
00001443: 88 4d 4c                                       MCOMW %pcbp,%sp
00001446: 3c 49 4e                                       CMPW %fp,%isp
00001449: 76 1d 00                                       BNEH &0x1d <0x1466>
0000144c: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00001450: 4b 04                                          BLB &0x4 <0x1454>
00001452: 7b d6                                          BRB &0xd6 <0x1428>

00001454: 84 41 49                                       MOVW %r1,%fp
00001457: 84 42 4a                                       MOVW %r2,%ap
0000145a: 84 43 4c                                       MOVW %r3,%sp
0000145d: 84 44 4d                                       MOVW %r4,%pcbp
00001460: 84 45 4e                                       MOVW %r5,%isp

00001463: 7a 15 00                                       BRH &0x15 <0x1478>

00001466: 84 41 49                                       MOVW %r1,%fp
00001469: 84 42 4a                                       MOVW %r2,%ap
0000146c: 84 43 4c                                       MOVW %r3,%sp
0000146f: 84 44 4d                                       MOVW %r4,%pcbp
00001472: 84 45 4e                                       MOVW %r5,%isp

00001475: 7a ae 04                                       BRH &0x4ae <0x1923>

;;; Here is where we checksum the ROM
00001478: 82 48                                          CLRH %r8
;;; We're going to read 7FEE bytes
0000147a: 84 5f ee 7f 45                                 MOVW &0x7fee,%r5
0000147f: 80 47                                          CLRW %r7

;; First jump to 14c0 to start the test...
00001481: 7b 3f                                          BRB &0x3f <0x14c0>

;; While r5 < r7...
00001483: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00001488: 87 57 e2 41                                    MOVB (%r7),{uhalf}%r1
0000148c: ba 5f ff 00 41                                 ANDH2 &0xff,%r1
00001491: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00001496: 9c 41 40                                       ADDW2 %r1,%r0
00001499: 86 40 48                                       MOVH %r0,%r8
0000149c: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000014a1: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
000014a5: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
000014aa: 86 e2 48 e0 41                                 MOVH {uhalf}%r8,{uword}%r1
000014af: d4 0f 41 41                                    LRSW3 &0xf,%r1,%r1
000014b3: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
000014b8: b0 41 40                                       ORW2 %r1,%r0
000014bb: 86 40 48                                       MOVH %r0,%r8
000014be: 90 47                                          INCW %r7
000014c0: 3c 45 47                                       CMPW %r5,%r7
000014c3: 5b c0                                          BLUB &0xc0 <0x1483>

000014c5: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000014ca: 88 40 40                                       MCOMW %r0,%r0
000014cd: 86 40 48                                       MOVH %r0,%r8
000014d0: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000014d5: 87 57 e0 41                                    MOVB (%r7),{uword}%r1
000014d9: 87 c7 01 e0 42                                 MOVB 1(%r7),{uword}%r2
000014de: d0 08 42 42                                    LLSW3 &0x8,%r2,%r2
000014e2: b0 42 41                                       ORW2 %r2,%r1
000014e5: 3c 41 40                                       CMPW %r1,%r0
000014e8: 77 08                                          BNEB &0x8 <0x14f0>

;;; Skip additional tests
000014ea: 24 7f 6e 15 00 00                              JMP $0x156e

;;; Some sort of additional ROM tests
000014f0: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000014f5: 88 40 40                                       MCOMW %r0,%r0
000014f8: 86 40 48                                       MOVH %r0,%r8
000014fb: 9c 4f 00 80 00 00 45                           ADDW2 &0x8000,%r5
00001502: 7b 3f                                          BRB &0x3f <0x1541>
00001504: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00001509: 87 57 e2 41                                    MOVB (%r7),{uhalf}%r1
0000150d: ba 5f ff 00 41                                 ANDH2 &0xff,%r1
00001512: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00001517: 9c 41 40                                       ADDW2 %r1,%r0
0000151a: 86 40 48                                       MOVH %r0,%r8
0000151d: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00001522: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00001526: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
0000152b: 86 e2 48 e0 41                                 MOVH {uhalf}%r8,{uword}%r1
00001530: d4 0f 41 41                                    LRSW3 &0xf,%r1,%r1
00001534: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00001539: b0 41 40                                       ORW2 %r1,%r0
0000153c: 86 40 48                                       MOVH %r0,%r8
0000153f: 90 47                                          INCW %r7
00001541: 3c 45 47                                       CMPW %r5,%r7
00001544: 5b c0                                          BLUB &0xc0 <0x1504>
00001546: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
0000154b: 88 40 40                                       MCOMW %r0,%r0
0000154e: 86 40 48                                       MOVH %r0,%r8
00001551: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00001556: 87 57 e0 41                                    MOVB (%r7),{uword}%r1
0000155a: 87 c7 01 e0 42                                 MOVB 1(%r7),{uword}%r2
0000155f: d0 08 42 42                                    LLSW3 &0x8,%r2,%r2
00001563: b0 42 41                                       ORW2 %r2,%r1
00001566: 3c 41 40                                       CMPW %r1,%r0
00001569: 7f 05                                          BEB &0x5 <0x156e>
;;; Checksum failure (?)
0000156b: 7a c1 03                                       BRH &0x3c1 <0x192c>
;;; Checksum success (?)
0000156e: 3c 4f ed 0d 1c a1 7f 64 08 00 02               CMPW &0xa11c0ded,$0x2000864
00001579: 7f 15                                          BEB &0x15 <0x158e>
0000157b: 3c 4f 0d f0 ad 8b 7f 64 08 00 02               CMPW &0x8badf00d,$0x2000864
00001586: 7f 08                                          BEB &0x8 <0x158e>
00001588: 24 7f bc 16 00 00                              JMP $0x16bc
0000158e: 2c 5c 7f 90 3b 00 00                           CALL (%sp),$0x3b90
00001595: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
0000159d: 3f 02 50                                       CMPB &0x2,(%r0)
000015a0: 77 07                                          BNEB &0x7 <0x15a7>
000015a2: 84 01 40                                       MOVW &0x1,%r0
000015a5: 7b 04                                          BRB &0x4 <0x15a9>
000015a7: 80 40                                          CLRW %r0
000015a9: a0 40                                          PUSHW %r0
000015ab: 2c cc fc 7f 2c 73 00 00                        CALL -4(%sp),$0x732c
000015b3: a0 00                                          PUSHW &0x0
000015b5: 2c cc fc 7f 8c 79 00 00                        CALL -4(%sp),$0x798c
000015bd: 87 7f 00 d0 04 00 e0 45                        MOVB $0x4d000,{uword}%r5
000015c5: 87 01 7f 1f 40 04 00                           MOVB &0x1,$0x4401f
000015cc: 70                                             NOP
000015cd: 87 10 7f 0f 90 04 00                           MOVB &0x10,$0x4900f
000015d4: 70                                             NOP
000015d5: 87 20 7f 0f 90 04 00                           MOVB &0x20,$0x4900f
000015dc: 70                                             NOP
000015dd: 87 01 7f 68 08 00 02                           MOVB &0x1,$0x2000868
000015e4: 70                                             NOP
000015e5: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
000015ed: 2b 50                                          TSTB (%r0)
000015ef: 7f 10                                          BEB &0x10 <0x15ff>
000015f1: 2c 5c 7f 72 5f 00 00                           CALL (%sp),$0x5f72
000015f8: 2c 5c 7f 78 63 00 00                           CALL (%sp),$0x6378
000015ff: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
00001607: 3f 01 50                                       CMPB &0x1,(%r0)
0000160a: 77 08                                          BNEB &0x8 <0x1612>
0000160c: 24 7f a0 16 00 00                              JMP $0x16a0
00001612: 2c 5c 7f 72 5f 00 00                           CALL (%sp),$0x5f72
00001619: a0 4f 0c 30 04 00                              PUSHW &0x4300c
0000161f: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00001627: a0 40                                          PUSHW %r0
00001629: a0 01                                          PUSHW &0x1

;; Read NVRAM
0000162b: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00001633: 28 40                                          TSTW %r0
00001635: 77 28                                          BNEB &0x28 <0x165d>
00001637: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
0000163f: 87 01 50                                       MOVB &0x1,(%r0)
00001642: 70                                             NOP
00001643: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
0000164b: a0 40                                          PUSHW %r0
0000164d: a0 4f 0c 30 04 00                              PUSHW &0x4300c
00001653: a0 01                                          PUSHW &0x1
00001655: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
0000165d: 84 7f 64 08 00 02 59                           MOVW $0x2000864,(%fp)
00001664: 70                                             NOP
00001665: 83 ef a0 04 00 00                              CLRB *$0x4a0
0000166b: 70                                             NOP
0000166c: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
;; Copy string "/filledt" (to where?)
00001674: a0 40                                          PUSHW %r0
00001676: a0 4f c8 05 00 00                              PUSHW &0x5c8
0000167c: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
00001684: 2c 5c 7f 70 69 00 00                           CALL (%sp),$0x6970
0000168b: 3c 4f ef be ed fe 7f 64 08 00 02               CMPW &0xfeedbeef,$0x2000864
00001696: 7f 0a                                          BEB &0xa <0x16a0>
00001698: 84 59 7f 64 08 00 02                           MOVW (%fp),$0x2000864
0000169f: 70                                             NOP
000016a0: 3c 4f ed 0d 1c a1 7f 64 08 00 02               CMPW &0xa11c0ded,$0x2000864
000016ab: 77 0b                                          BNEB &0xb <0x16b6>
000016ad: 2c 5c ef 58 08 00 02                           CALL (%sp),*$0x2000858
000016b4: 7b 08                                          BRB &0x8 <0x16bc>
000016b6: 24 7f f0 65 00 00                              JMP $0x65f0
000016bc: 3c 4f d0 f1 02 3b 7f 6c 08 00 02               CMPW &0x3b02f1d0,$0x200086c
000016c7: 7f 2a                                          BEB &0x2a <0x16f1>
000016c9: 87 6f 70 7f 04 90 04 00                        MOVB &0x70,$0x49004
000016d1: 70                                             NOP
000016d2: 87 6f 40 7f 06 90 04 00                        MOVB &0x40,$0x49006
000016da: 70                                             NOP
000016db: 83 7f 07 90 04 00                              CLRB $0x49007
000016e1: 70                                             NOP
000016e2: 87 04 7f 0d 90 04 00                           MOVB &0x4,$0x4900d
000016e9: 70                                             NOP
000016ea: 80 7f 5c 08 00 02                              CLRW $0x200085c
000016f0: 70                                             NOP
000016f1: 84 7f 64 08 00 02 45                           MOVW $0x2000864,%r5
000016f8: 84 7f 6c 08 00 02 44                           MOVW $0x200086c,%r4
000016ff: 84 7f 5c 08 00 02 43                           MOVW $0x200085c,%r3
00001706: 84 4f 00 00 00 02 47                           MOVW &0x2000000,%r7
0000170d: 84 4f 04 15 00 02 46                           MOVW &0x2001504,%r6
00001714: 7b 4b                                          BRB &0x4b <0x175f>
00001716: 87 5f ff 00 57                                 MOVB &0xff,(%r7)
0000171b: 70                                             NOP
0000171c: 3f 5f ff 00 57                                 CMPB &0xff,(%r7)
00001721: 7f 08                                          BEB &0x8 <0x1729>
00001723: 24 7f 35 19 00 00                              JMP $0x1935
00001729: 87 5f aa 00 57                                 MOVB &0xaa,(%r7)
0000172e: 70                                             NOP
0000172f: 3f 5f aa 00 57                                 CMPB &0xaa,(%r7)
00001734: 7f 08                                          BEB &0x8 <0x173c>
00001736: 24 7f 35 19 00 00                              JMP $0x1935
0000173c: 87 6f 55 57                                    MOVB &0x55,(%r7)
00001740: 70                                             NOP
00001741: 3f 6f 55 57                                    CMPB &0x55,(%r7)
00001745: 7f 08                                          BEB &0x8 <0x174d>
00001747: 24 7f 35 19 00 00                              JMP $0x1935
0000174d: 83 57                                          CLRB (%r7)
0000174f: 70                                             NOP
00001750: 84 47 40                                       MOVW %r7,%r0
00001753: 90 47                                          INCW %r7
00001755: 2b 50                                          TSTB (%r0)
00001757: 7f 08                                          BEB &0x8 <0x175f>
00001759: 24 7f 35 19 00 00                              JMP $0x1935
0000175f: 3c 46 47                                       CMPW %r6,%r7
00001762: 5b b4                                          BLUB &0xb4 <0x1716>
00001764: 3c 4f 00 40 00 02 47                           CMPW &0x2004000,%r7
0000176b: 4b 04                                          BLB &0x4 <0x176f>
0000176d: 7b 40                                          BRB &0x40 <0x17ad>
0000176f: 3c 4f ef be ed fe 45                           CMPW &0xfeedbeef,%r5
00001776: 7f 26                                          BEB &0x26 <0x179c>
00001778: 3c 4f d0 f1 02 3b 45                           CMPW &0x3b02f1d0,%r5
0000177f: 7f 1d                                          BEB &0x1d <0x179c>
00001781: 3c 4f 0d f0 ad 8b 45                           CMPW &0x8badf00d,%r5
00001788: 7f 14                                          BEB &0x14 <0x179c>
0000178a: 3c 4f 1e ac eb ad 45                           CMPW &0xadebac1e,%r5
00001791: 7f 0b                                          BEB &0xb <0x179c>
00001793: 3c 4f ed 0d 1c a1 45                           CMPW &0xa11c0ded,%r5
0000179a: 77 09                                          BNEB &0x9 <0x17a3>
0000179c: 84 4f 00 30 00 02 47                           MOVW &0x2003000,%r7
000017a3: 84 4f 00 40 00 02 46                           MOVW &0x2004000,%r6
000017aa: 7a 6a ff                                       BRH &0xff6a <0x1714>
000017ad: 84 44 7f 6c 08 00 02                           MOVW %r4,$0x200086c
000017b4: 70                                             NOP
000017b5: 84 45 7f 64 08 00 02                           MOVW %r5,$0x2000864
000017bc: 70                                             NOP
000017bd: 84 43 7f 5c 08 00 02                           MOVW %r3,$0x200085c
000017c4: 70                                             NOP
000017c5: 87 01 7f 68 08 00 02                           MOVB &0x1,$0x2000868
000017cc: 70                                             NOP
000017cd: 82 48                                          CLRH %r8

;; Put $43800 into R5. This is the top of NVRAM, and the stopping
;; point for the upcoming block that clears NVRAM.

000017cf: 84 4f 00 38 04 00 45                           MOVW &0x43800,%r5

;; Put $43000 into R7. This is the base of NVRAM.
000017d6: 84 4f 00 30 04 00 47                           MOVW &0x43000,%r7

;;
000017dd: 7b 40                                          BRB &0x40 <0x181d>
000017df: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
;; Read NVRAM address + 2 into R1
000017e4: 86 e2 c7 02 e0 41                              MOVH {uhalf}2(%r7),{uword}%r1
;; Mask the low nybble of R1
000017ea: ba 0f 41                                       ANDH2 &0xf,%r1
;; Zero-extend the halfword into a word
000017ed: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
;; Add R1 to R0, store in R0
000017f2: 9c 41 40                                       ADDW2 %r1,%r0
;; Move R0 to R8
000017f5: 86 40 48                                       MOVH %r0,%r8
000017f8: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
;; Left-shift R0 by 1
000017fd: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00001801: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
00001806: 86 e2 48 e0 41                                 MOVH {uhalf}%r8,{uword}%r1
0000180b: d4 0f 41 41                                    LRSW3 &0xf,%r1,%r1
0000180f: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00001814: b0 41 40                                       ORW2 %r1,%r0
00001817: 86 40 48                                       MOVH %r0,%r8

;; Increment the address in R7 by 4 bytes
0000181a: 9c 04 47                                       ADDW2 &0x4,%r7

;; While R5 < R7, keep going
0000181d: 3c 45 47                                       CMPW %r5,%r7
00001820: 5b bf                                          BLUB &0xbf <0x17df>

;; Now we do something odd with 43800, 43804, 43808, and 4380c. What
;; is this? Serial number structure of some kind?

00001822: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00001827: 88 40 40                                       MCOMW %r0,%r0
0000182a: 86 40 48                                       MOVH %r0,%r8
0000182d: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00001832: f8 0f 57 41                                    ANDW3 &0xf,(%r7),%r1
00001836: f8 0f c7 04 42                                 ANDW3 &0xf,4(%r7),%r2
0000183b: d0 04 42 42                                    LLSW3 &0x4,%r2,%r2
0000183f: b0 42 41                                       ORW2 %r2,%r1
00001842: f8 0f c7 08 42                                 ANDW3 &0xf,8(%r7),%r2
00001847: d0 08 42 42                                    LLSW3 &0x8,%r2,%r2
0000184b: b0 42 41                                       ORW2 %r2,%r1
0000184e: f8 0f c7 0c 42                                 ANDW3 &0xf,12(%r7),%r2
00001853: d0 0c 42 42                                    LLSW3 &0xc,%r2,%r2
00001857: b0 42 41                                       ORW2 %r2,%r1
0000185a: 3c 41 40                                       CMPW %r1,%r0

;; If R1 != R0, we clear out the NVRAM. Othwerise, jump to 191d
0000185d: 77 08                                          BNEB &0x8 <0x1865>
0000185f: 24 7f 1d 19 00 00                              JMP $0x191d

;; Load the NVRAM base address into R7
00001865: 84 4f 00 30 04 00 47                           MOVW &0x43000,%r7

0000186c: 7b 08                                          BRB &0x8 <0x1874>

;; Clear the NVRAM memory location stored in %r7
0000186e: 80 57                                          CLRW (%r7)
00001870: 70                                             NOP

;; Add 4 bytes to the address
00001871: 9c 04 47                                       ADDW2 &0x4,%r7

;; Is %r7 == %r5?
00001874: 3c 45 47                                       CMPW %r5,%r7

;; No, jump back and keep zeroing NVRAM.
00001877: 5b f7                                          BLUB &0xf7 <0x186e>

;; Yes, we're done.

;; Store 01 in $43060
00001879: 84 01 7f 60 30 04 00                           MOVW &0x1,$0x43060
00001880: 70                                             NOP

;; Store 00 in $43064
00001881: 80 7f 64 30 04 00                              CLRW $0x43064
00001887: 70                                             NOP

00001888: 82 48                                          CLRH %r8
0000188a: 84 4f 00 30 04 00 47                           MOVW &0x43000,%r7

00001891: 7b 40                                          BRB &0x40 <0x18d1>
00001893: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00001898: 86 e2 c7 02 e0 41                              MOVH {uhalf}2(%r7),{uword}%r1
0000189e: ba 0f 41                                       ANDH2 &0xf,%r1
000018a1: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
000018a6: 9c 41 40                                       ADDW2 %r1,%r0
000018a9: 86 40 48                                       MOVH %r0,%r8
000018ac: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000018b1: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
000018b5: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
000018ba: 86 e2 48 e0 41                                 MOVH {uhalf}%r8,{uword}%r1
000018bf: d4 0f 41 41                                    LRSW3 &0xf,%r1,%r1
000018c3: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
000018c8: b0 41 40                                       ORW2 %r1,%r0
000018cb: 86 40 48                                       MOVH %r0,%r8
000018ce: 9c 04 47                                       ADDW2 &0x4,%r7


000018d1: 3c 45 47                                       CMPW %r5,%r7
000018d4: 5b bf                                          BLUB &0xbf <0x1893>
000018d6: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000018db: 88 40 40                                       MCOMW %r0,%r0
000018de: 86 40 48                                       MOVH %r0,%r8
000018e1: 86 e2 48 e0 57                                 MOVH {uhalf}%r8,{uword}(%r7)
000018e6: 70                                             NOP
000018e7: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000018ec: d4 04 40 40                                    LRSW3 &0x4,%r0,%r0
000018f0: 84 40 c7 04                                    MOVW %r0,4(%r7)
000018f4: 70                                             NOP
000018f5: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000018fa: d4 08 40 40                                    LRSW3 &0x8,%r0,%r0
000018fe: 84 40 c7 08                                    MOVW %r0,8(%r7)
00001902: 70                                             NOP
00001903: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00001908: d4 0c 40 40                                    LRSW3 &0xc,%r0,%r0
0000190c: 84 40 c7 0c                                    MOVW %r0,12(%r7)
00001910: 70                                             NOP
00001911: b0 4f 00 00 00 20 7f 5c 08 00 02               ORW2 &0x20000000,$0x200085c
0000191c: 70                                             NOP

;;
0000191d: 24 7f b1 21 00 00                              JMP $0x21b1

;;
;; Test failure entry points, I think.
;;
;; Set %r4 based on the entry point. %r4 will be either: 2, 3, 4 or 5.
;;

;; Set %r4 to 2, then jump to 0x1941
00001923: 84 02 44                                       MOVW &0x2,%r4
00001926: 24 7f 41 19 00 00                              JMP $0x1941

;; Set %r4 to 3, then jump to 0x1941
0000192c: 84 03 44                                       MOVW &0x3,%r4
0000192f: 24 7f 41 19 00 00                              JMP $0x1941

;; Set %r4 to 4, then jump to 0x1941
00001935: 84 04 44                                       MOVW &0x4,%r4
00001938: 24 7f 41 19 00 00                              JMP $0x1941

;; Set %r4 to 5, fall through to 0x1941
0000193e: 84 05 44                                       MOVW &0x5,%r4

;; Set 0x4900d to 0. This is 2681 UART.
00001941: 83 7f 0d 90 04 00                              CLRB $0x4900d
00001947: 70                                             NOP
00001948: 87 08 7f 0f 90 04 00                           MOVB &0x8,$0x4900f
0000194f: 70                                             NOP

;; 0x440?? == System Board Status register
00001950: 87 01 7f 17 40 04 00                           MOVB &0x1,$0x44017
00001957: 70                                             NOP
00001958: 87 01 7f 03 40 04 00                           MOVB &0x1,$0x44003
0000195f: 70                                             NOP

00001960: 80 45                                          CLRW %r5
00001962: 7b 32                                          BRB &0x32 <0x1994>
00001964: 80 43                                          CLRW %r3
00001966: 7b 04                                          BRB &0x4 <0x196a>
00001968: 90 43                                          INCW %r3
0000196a: 3c 4f 50 c3 00 00 43                           CMPW &0xc350,%r3
00001971: 5f f7                                          BLEUB &0xf7 <0x1968>
00001973: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
0000197a: 70                                             NOP
0000197b: 80 43                                          CLRW %r3
0000197d: 7b 04                                          BRB &0x4 <0x1981>
0000197f: 90 43                                          INCW %r3
00001981: 3c 4f 50 c3 00 00 43                           CMPW &0xc350,%r3
00001988: 5f f7                                          BLEUB &0xf7 <0x197f>

;; Write to the CSR (what register?)
0000198a: 87 01 7f 17 40 04 00                           MOVB &0x1,$0x44017
00001991: 70                                             NOP
00001992: 90 45                                          INCW %r5
00001994: 3c 44 45                                       CMPW %r4,%r5
00001997: 5b cd                                          BLUB &0xcd <0x1964>
00001999: 3f 01 ef 10 05 00 00                           CMPB &0x1,*$0x510
000019a0: 7f 2b                                          BEB &0x2b <0x19cb>
000019a2: 3f 6f 64 7f 03 20 04 00                        CMPB &0x64,$0x42003

;; If *0x42003 == 0x64, jump over the up-coming infinite loop...
000019aa: 7f 21                                          BEB &0x21 <0x19cb>

;; Otherwise, we're terminal. Set some state...
000019ac: 80 ef 8c 04 00 00                              CLRW *$0x48c
000019b2: 70                                             NOP
000019b3: 80 ef 14 05 00 00                              CLRW *$0x514
000019b9: 70                                             NOP
000019ba: 83 7f 0d 90 04 00                              CLRB $0x4900d
000019c0: 70                                             NOP
000019c1: 87 04 7f 0e 90 04 00                           MOVB &0x4,$0x4900e
000019c8: 70                                             NOP

;; ... and then die in an infinite loop (BRB 0)
000019c9: 7b 00                                          BRB &0x0 <0x19c9>

;; R3 = 0
000019cb: 80 43                                          CLRW %r3

;; Skip first increment, so R3 still = 0. Go to 19d1
000019cd: 7b 04                                          BRB &0x4 <0x19d1>

000019cf: 90 43                                          INCW %r3

;; Multiply R4 by 0xC350 (50000d) and store in R0.
000019d1: e8 4f 50 c3 00 00 44 40                        MULW3 &0xc350,%r4,%r0

;; While R3 < R0, keep incremting R3.
000019d9: 3c 40 43                                       CMPW %r0,%r3
000019dc: 5f f3                                          BLEUB &0xf3 <0x19cf>

000019de: 24 7f 60 19 00 00                              JMP $0x1960

;; OK, I don't actually see how any code can reach this point. The
;; unconditional jump above catches everything, and I don't see any
;; other branches to this location. Weird.
000019e4: 04 59 4c                                       MOVAW (%fp),%sp
000019e7: 20 48                                          POPW %r8
000019e9: 20 47                                          POPW %r7
000019eb: 20 46                                          POPW %r6
000019ed: 20 45                                          POPW %r5
000019ef: 20 44                                          POPW %r4
000019f1: 20 43                                          POPW %r3
000019f3: 20 49                                          POPW %fp
000019f5: 08                                             RET
000019f6: 70                                             NOP
000019f7: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine - in fact, nothing calls this code! It looks unreachable.
;;
000019f8: 10 43                                          SAVE %r3
000019fa: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp

;; Jump point from 0x25d3
00001a01: 87 5f d0 00 7f 00 d0 04 00                     MOVB &0xd0,$0x4d000
00001a0a: 70                                             NOP
00001a0b: a0 01                                          PUSHW &0x1
00001a0d: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00001a15: 87 01 7f 70 08 00 02                           MOVB &0x1,$0x2000870
00001a1c: 70                                             NOP
00001a1d: 87 5f ff 00 7f 71 08 00 02                     MOVB &0xff,$0x2000871
00001a26: 70                                             NOP
00001a27: 84 4f 00 38 04 00 43                           MOVW &0x43800,%r3
00001a2e: a0 00                                          PUSHW &0x0
00001a30: a0 4f 74 08 00 02                              PUSHW &0x2000874
00001a36: a0 00                                          PUSHW &0x0
00001a38: a0 03                                          PUSHW &0x3
00001a3a: 2c cc f0 7f 2c 7b 00 00                        CALL -16(%sp),$0x7b2c
00001a42: 28 40                                          TSTW %r0
00001a44: 77 08                                          BNEB &0x8 <0x1a4c>
00001a46: 24 7f 67 1b 00 00                              JMP $0x1b67
00001a4c: dc 03 7f 08 05 00 00 40                        ADDW3 &0x3,$0x508,%r0
00001a54: 3f 50 7f 74 08 00 02                           CMPB (%r0),$0x2000874
00001a5b: 7f 08                                          BEB &0x8 <0x1a63>
00001a5d: 24 7f 67 1b 00 00                              JMP $0x1b67
00001a63: dc 07 7f 08 05 00 00 40                        ADDW3 &0x7,$0x508,%r0
00001a6b: 3f 50 7f 75 08 00 02                           CMPB (%r0),$0x2000875
00001a72: 7f 08                                          BEB &0x8 <0x1a7a>
00001a74: 24 7f 67 1b 00 00                              JMP $0x1b67
00001a7a: dc 0b 7f 08 05 00 00 40                        ADDW3 &0xb,$0x508,%r0
00001a82: 3f 50 7f 76 08 00 02                           CMPB (%r0),$0x2000876
00001a89: 7f 08                                          BEB &0x8 <0x1a91>
00001a8b: 24 7f 67 1b 00 00                              JMP $0x1b67
00001a91: dc 0f 7f 08 05 00 00 40                        ADDW3 &0xf,$0x508,%r0
00001a99: 3f 50 7f 77 08 00 02                           CMPB (%r0),$0x2000877
00001aa0: 7f 08                                          BEB &0x8 <0x1aa8>
00001aa2: 24 7f 67 1b 00 00                              JMP $0x1b67
00001aa8: 84 4f 00 30 04 00 48                           MOVW &0x43000,%r8
00001aaf: 7b 08                                          BRB &0x8 <0x1ab7>
00001ab1: 80 58                                          CLRW (%r8)
00001ab3: 70                                             NOP
00001ab4: 9c 04 48                                       ADDW2 &0x4,%r8
00001ab7: 3c 43 48                                       CMPW %r3,%r8
00001aba: 5b f7                                          BLUB &0xf7 <0x1ab1>
00001abc: 84 01 7f 60 30 04 00                           MOVW &0x1,$0x43060
00001ac3: 70                                             NOP
00001ac4: 80 7f 64 30 04 00                              CLRW $0x43064
00001aca: 70                                             NOP
00001acb: 82 44                                          CLRH %r4
00001acd: 84 4f 00 30 04 00 48                           MOVW &0x43000,%r8
00001ad4: 7b 40                                          BRB &0x40 <0x1b14>
00001ad6: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001adb: 86 e2 c8 02 e0 41                              MOVH {uhalf}2(%r8),{uword}%r1
00001ae1: ba 0f 41                                       ANDH2 &0xf,%r1
00001ae4: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00001ae9: 9c 41 40                                       ADDW2 %r1,%r0
00001aec: 86 40 44                                       MOVH %r0,%r4
00001aef: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001af4: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00001af8: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
00001afd: 86 e2 44 e0 41                                 MOVH {uhalf}%r4,{uword}%r1
00001b02: d4 0f 41 41                                    LRSW3 &0xf,%r1,%r1
00001b06: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00001b0b: b0 41 40                                       ORW2 %r1,%r0
00001b0e: 86 40 44                                       MOVH %r0,%r4
00001b11: 9c 04 48                                       ADDW2 &0x4,%r8
00001b14: 3c 43 48                                       CMPW %r3,%r8
00001b17: 5b bf                                          BLUB &0xbf <0x1ad6>
00001b19: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001b1e: 88 40 40                                       MCOMW %r0,%r0
00001b21: 86 40 44                                       MOVH %r0,%r4
00001b24: 86 e2 44 e0 58                                 MOVH {uhalf}%r4,{uword}(%r8)
00001b29: 70                                             NOP
00001b2a: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001b2f: d4 04 40 40                                    LRSW3 &0x4,%r0,%r0
00001b33: 84 40 c8 04                                    MOVW %r0,4(%r8)
00001b37: 70                                             NOP
00001b38: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001b3d: d4 08 40 40                                    LRSW3 &0x8,%r0,%r0
00001b41: 84 40 c8 08                                    MOVW %r0,8(%r8)
00001b45: 70                                             NOP
00001b46: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001b4b: d4 0c 40 40                                    LRSW3 &0xc,%r0,%r0
00001b4f: 84 40 c8 0c                                    MOVW %r0,12(%r8)
00001b53: 70                                             NOP
00001b54: b0 4f 00 00 00 40 7f 5c 08 00 02               ORW2 &0x40000000,$0x200085c
00001b5f: 70                                             NOP
00001b60: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
00001b67: a0 4f 0c 30 04 00                              PUSHW &0x4300c
00001b6d: a0 4f 61 08 00 02                              PUSHW &0x2000861
00001b73: a0 01                                          PUSHW &0x1
00001b75: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00001b7d: 28 40                                          TSTW %r0
00001b7f: 77 20                                          BNEB &0x20 <0x1b9f>
00001b81: 87 01 7f 61 08 00 02                           MOVB &0x1,$0x2000861
00001b88: 70                                             NOP
00001b89: a0 4f 61 08 00 02                              PUSHW &0x2000861
00001b8f: a0 4f 0c 30 04 00                              PUSHW &0x4300c
00001b95: a0 01                                          PUSHW &0x1
00001b97: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00001b9f: 3f 01 7f 61 08 00 02                           CMPB &0x1,$0x2000861
00001ba6: 7f 0b                                          BEB &0xb <0x1bb1>
00001ba8: 3f 02 7f 61 08 00 02                           CMPB &0x2,$0x2000861
00001baf: 77 12                                          BNEB &0x12 <0x1bc1>
00001bb1: 87 01 45                                       MOVB &0x1,%r5
00001bb4: ff 01 7f 61 08 00 02 40                        SUBB3 &0x1,$0x2000861,%r0
00001bbc: 87 40 47                                       MOVB %r0,%r7
00001bbf: 7b 06                                          BRB &0x6 <0x1bc5>
00001bc1: 83 45                                          CLRB %r5
00001bc3: 83 47                                          CLRB %r7
00001bc5: 83 7f 60 08 00 02                              CLRB $0x2000860
00001bcb: 70                                             NOP
00001bcc: 82 44                                          CLRH %r4
00001bce: 7b 1a                                          BRB &0x1a <0x1be8>
00001bd0: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001bd5: 86 e2 44 e0 41                                 MOVH {uhalf}%r4,{uword}%r1
00001bda: 87 81 ec 10 00 00 80 74 0a 00 02               MOVB 0x10ec(%r1),0x2000a74(%r0)
00001be5: 70                                             NOP
00001be6: 92 44                                          INCH %r4
00001be8: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001bed: 3c 08 40                                       CMPW &0x8,%r0
00001bf0: 5b e0                                          BLUB &0xe0 <0x1bd0>
00001bf2: 82 44                                          CLRH %r4
00001bf4: 7b 23                                          BRB &0x23 <0x1c17>
00001bf6: 87 47 e0 40                                    MOVB %r7,{uword}%r0
00001bfa: a0 40                                          PUSHW %r0
00001bfc: 2c cc fc 7f 2c 73 00 00                        CALL -4(%sp),$0x732c
00001c04: 28 40                                          TSTW %r0
00001c06: 7f 04                                          BEB &0x4 <0x1c0a>
00001c08: 7b 19                                          BRB &0x19 <0x1c21>
00001c0a: a0 6f 64                                       PUSHW &0x64
00001c0d: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00001c15: 92 44                                          INCH %r4
00001c17: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001c1c: 3c 3c 40                                       CMPW &0x3c,%r0
00001c1f: 5b d7                                          BLUB &0xd7 <0x1bf6>
00001c21: 87 47 e0 40                                    MOVB %r7,{uword}%r0
00001c25: a0 40                                          PUSHW %r0
;; XXX Call to 6e28
00001c27: 2c cc fc 7f 28 6e 00 00                        CALL -4(%sp),$0x6e28
00001c2f: 28 40                                          TSTW %r0
00001c31: 77 39                                          BNEB &0x39 <0x1c6a>
;; Here we seem to be setting 0x2 in r0
00001c33: f0 02 7f 7c 0a 00 02 40                        ORW3 &0x2,$0x2000a7c,%r0
00001c3b: 87 47 e0 41                                    MOVB %r7,{uword}%r1
00001c3f: d0 17 41 41                                    LLSW3 &0x17,%r1,%r1
00001c43: b0 41 40                                       ORW2 %r1,%r0
00001c46: a0 40                                          PUSHW %r0
00001c48: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00001c50: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
00001c57: 70                                             NOP
00001c58: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00001c63: 70                                             NOP
00001c64: 24 7f 37 1e 00 00                              JMP $0x1e37
00001c6a: eb 6f 54 47 40                                 MULB3 &0x54,%r7,%r0
00001c6f: 3c 4f 0d 60 5e ca 80 84 0a 00 02               CMPW &0xca5e600d,0x2000a84(%r0)
00001c7a: 7f 08                                          BEB &0x8 <0x1c82>
00001c7c: 24 7f a0 1d 00 00                              JMP $0x1da0
00001c82: df 01 47 40                                    ADDB3 &0x1,%r7,%r0
00001c86: b3 40 7f 60 08 00 02                           ORB2 %r0,$0x2000860
00001c8d: 70                                             NOP
00001c8e: bb 5f f0 00 7f 75 0a 00 02                     ANDB2 &0xf0,$0x2000a75
00001c97: 70                                             NOP
00001c98: eb 6f 54 47 40                                 MULB3 &0x54,%r7,%r0
00001c9d: d4 08 80 a4 0a 00 02 40                        LRSW3 &0x8,0x2000aa4(%r0),%r0
00001ca5: b3 40 7f 75 0a 00 02                           ORB2 %r0,$0x2000a75
00001cac: 70                                             NOP
00001cad: eb 6f 54 47 40                                 MULB3 &0x54,%r7,%r0
00001cb2: 87 80 a7 0a 00 02 7f 76 0a 00 02               MOVB 0x2000aa7(%r0),$0x2000a76
00001cbd: 70                                             NOP
00001cbe: eb 6f 54 47 40                                 MULB3 &0x54,%r7,%r0
00001cc3: ff 01 80 9f 0a 00 02 40                        SUBB3 &0x1,0x2000a9f(%r0),%r0
00001ccb: 87 40 7f 77 0a 00 02                           MOVB %r0,$0x2000a77
00001cd2: 70                                             NOP
00001cd3: eb 6f 54 47 40                                 MULB3 &0x54,%r7,%r0
00001cd8: ff 01 80 a3 0a 00 02 40                        SUBB3 &0x1,0x2000aa3(%r0),%r0
00001ce0: 87 40 7f 78 0a 00 02                           MOVB %r0,$0x2000a78
00001ce7: 70                                             NOP
00001ce8: eb 6f 54 47 40                                 MULB3 &0x54,%r7,%r0
00001ced: d4 09 80 98 0a 00 02 40                        LRSW3 &0x9,0x2000a98(%r0),%r0
00001cf5: 87 40 7f 7a 0a 00 02                           MOVB %r0,$0x2000a7a
00001cfc: 70                                             NOP
00001cfd: eb 6f 54 47 40                                 MULB3 &0x54,%r7,%r0
00001d02: d4 01 80 98 0a 00 02 40                        LRSW3 &0x1,0x2000a98(%r0),%r0
00001d0a: 87 40 7f 7b 0a 00 02                           MOVB %r0,$0x2000a7b
00001d11: 70                                             NOP
00001d12: 87 47 e0 40                                    MOVB %r7,{uword}%r0
00001d16: a0 40                                          PUSHW %r0
00001d18: 2c cc fc 7f 2c 73 00 00                        CALL -4(%sp),$0x732c
00001d20: 28 40                                          TSTW %r0
00001d22: 77 35                                          BNEB &0x35 <0x1d57>
00001d24: 2b 45                                          TSTB %r5
00001d26: 7f 31                                          BEB &0x31 <0x1d57>
00001d28: 87 47 e0 40                                    MOVB %r7,{uword}%r0
00001d2c: d0 17 40 40                                    LLSW3 &0x17,%r0,%r0
00001d30: b0 4f 02 00 04 00 40                           ORW2 &0x40002,%r0
00001d37: a0 40                                          PUSHW %r0
00001d39: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00001d41: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
00001d48: 70                                             NOP
00001d49: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00001d54: 70                                             NOP
00001d55: 7b 45                                          BRB &0x45 <0x1d9a>
00001d57: 2b 45                                          TSTB %r5
00001d59: 7f 41                                          BEB &0x41 <0x1d9a>
00001d5b: 87 47 e0 40                                    MOVB %r7,{uword}%r0
00001d5f: a0 40                                          PUSHW %r0
00001d61: 2c cc fc 7f d4 78 00 00                        CALL -4(%sp),$0x78d4
00001d69: 28 40                                          TSTW %r0
00001d6b: 77 2f                                          BNEB &0x2f <0x1d9a>
00001d6d: 87 47 e0 40                                    MOVB %r7,{uword}%r0
00001d71: d0 17 40 40                                    LLSW3 &0x17,%r0,%r0
00001d75: b0 4f 02 00 05 00 40                           ORW2 &0x50002,%r0
00001d7c: a0 40                                          PUSHW %r0
00001d7e: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00001d86: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
00001d8d: 70                                             NOP
00001d8e: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00001d99: 70                                             NOP
00001d9a: 24 7f 37 1e 00 00                              JMP $0x1e37
00001da0: 3c 4f ef be ed fe 7f 78 08 00 02               CMPW &0xfeedbeef,$0x2000878
00001dab: 77 5b                                          BNEB &0x5b <0x1e06>
00001dad: 84 3d 7f 64 08 00 02                           MOVW &0x3d,$0x2000864
00001db4: 70                                             NOP
00001db5: a0 4f 64 08 00 02                              PUSHW &0x2000864
00001dbb: a0 4f 0a 30 04 00                              PUSHW &0x4300a
00001dc1: a0 02                                          PUSHW &0x2
00001dc3: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00001dcb: 2c 5c 7f 90 3b 00 00                           CALL (%sp),$0x3b90
00001dd2: 87 01 7f 61 08 00 02                           MOVB &0x1,$0x2000861
00001dd9: 70                                             NOP
00001dda: a0 4f 61 08 00 02                              PUSHW &0x2000861
00001de0: a0 4f 0c 30 04 00                              PUSHW &0x4300c
00001de6: a0 01                                          PUSHW &0x1
00001de8: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00001df0: 84 4f 1e ac eb ad 7f 64 08 00 02               MOVW &0xadebac1e,$0x2000864
00001dfb: 70                                             NOP
00001dfc: b0 10 7f 5c 08 00 02                           ORW2 &0x10,$0x200085c
00001e03: 70                                             NOP
00001e04: 7b 33                                          BRB &0x33 <0x1e37>
00001e06: 2b 45                                          TSTB %r5
00001e08: 7f 2f                                          BEB &0x2f <0x1e37>
00001e0a: 87 47 e0 40                                    MOVB %r7,{uword}%r0
00001e0e: d0 17 40 40                                    LLSW3 &0x17,%r0,%r0
00001e12: b0 4f 02 00 02 00 40                           ORW2 &0x20002,%r0
00001e19: a0 40                                          PUSHW %r0
00001e1b: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00001e23: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
00001e2a: 70                                             NOP
00001e2b: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00001e36: 70                                             NOP
00001e37: f7 01 47 40                                    XORB3 &0x1,%r7,%r0
00001e3b: 87 40 46                                       MOVB %r0,%r6
00001e3e: a0 4f 3a 30 04 00                              PUSHW &0x4303a
00001e44: a0 4f 61 08 00 02                              PUSHW &0x2000861
00001e4a: a0 01                                          PUSHW &0x1
00001e4c: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00001e54: 28 40                                          TSTW %r0
00001e56: 77 1f                                          BNEB &0x1f <0x1e75>
00001e58: 83 7f 61 08 00 02                              CLRB $0x2000861
00001e5e: 70                                             NOP
00001e5f: a0 4f 61 08 00 02                              PUSHW &0x2000861
00001e65: a0 4f 3a 30 04 00                              PUSHW &0x4303a
00001e6b: a0 01                                          PUSHW &0x1
00001e6d: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00001e75: 3f 01 7f 61 08 00 02                           CMPB &0x1,$0x2000861
00001e7c: 77 05                                          BNEB &0x5 <0x1e81>
00001e7e: 86 3b 44                                       MOVH &0x3b,%r4
00001e81: a0 6f 64                                       PUSHW &0x64
00001e84: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00001e8c: 87 46 e0 40                                    MOVB %r6,{uword}%r0
00001e90: a0 40                                          PUSHW %r0
00001e92: 2c cc fc 7f 80 73 00 00                        CALL -4(%sp),$0x7380
00001e9a: 28 40                                          TSTW %r0
00001e9c: 7f 04                                          BEB &0x4 <0x1ea0>
00001e9e: 7b 0e                                          BRB &0xe <0x1eac>
00001ea0: 92 44                                          INCH %r4
00001ea2: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001ea7: 3c 3c 40                                       CMPW &0x3c,%r0
00001eaa: 5b d7                                          BLUB &0xd7 <0x1e81>
00001eac: 86 e2 44 e0 40                                 MOVH {uhalf}%r4,{uword}%r0
00001eb1: 3c 3c 40                                       CMPW &0x3c,%r0
00001eb4: 5b 26                                          BLUB &0x26 <0x1eda>
00001eb6: 87 01 7f 61 08 00 02                           MOVB &0x1,$0x2000861
00001ebd: 70                                             NOP
00001ebe: a0 4f 61 08 00 02                              PUSHW &0x2000861
00001ec4: a0 4f 3a 30 04 00                              PUSHW &0x4303a
00001eca: a0 01                                          PUSHW &0x1
00001ecc: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00001ed4: 24 7f a9 20 00 00                              JMP $0x20a9
00001eda: 87 46 e0 40                                    MOVB %r6,{uword}%r0
00001ede: a0 40                                          PUSHW %r0
00001ee0: 2c cc fc 7f 28 6e 00 00                        CALL -4(%sp),$0x6e28
00001ee8: 28 40                                          TSTW %r0
00001eea: 77 39                                          BNEB &0x39 <0x1f23>
00001eec: f0 02 7f 7c 0a 00 02 40                        ORW3 &0x2,$0x2000a7c,%r0
00001ef4: 87 46 e0 41                                    MOVB %r6,{uword}%r1
00001ef8: d0 17 41 41                                    LLSW3 &0x17,%r1,%r1
00001efc: b0 41 40                                       ORW2 %r1,%r0
00001eff: a0 40                                          PUSHW %r0
00001f01: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00001f09: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
00001f10: 70                                             NOP
00001f11: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00001f1c: 70                                             NOP
00001f1d: 24 7f a9 20 00 00                              JMP $0x20a9
00001f23: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
00001f28: 3c 4f 0d 60 5e ca 80 84 0a 00 02               CMPW &0xca5e600d,0x2000a84(%r0)
00001f33: 7f 35                                          BEB &0x35 <0x1f68>
00001f35: 87 46 e0 40                                    MOVB %r6,{uword}%r0
00001f39: d0 17 40 40                                    LLSW3 &0x17,%r0,%r0
00001f3d: b0 4f 02 00 02 00 40                           ORW2 &0x20002,%r0
00001f44: a0 40                                          PUSHW %r0
00001f46: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00001f4e: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
00001f55: 70                                             NOP
00001f56: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00001f61: 70                                             NOP
00001f62: 24 7f a9 20 00 00                              JMP $0x20a9
00001f68: df 01 46 40                                    ADDB3 &0x1,%r6,%r0
00001f6c: b3 40 7f 60 08 00 02                           ORB2 %r0,$0x2000860
00001f73: 70                                             NOP
00001f74: 80 43                                          CLRW %r3
00001f76: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
00001f7b: eb 6f 54 47 41                                 MULB3 &0x54,%r7,%r1
00001f80: 3c 81 a4 0a 00 02 80 a4 0a 00 02               CMPW 0x2000aa4(%r1),0x2000aa4(%r0)
00001f8b: 5f 35                                          BLEUB &0x35 <0x1fc0>
00001f8d: bb 5f f0 00 7f 75 0a 00 02                     ANDB2 &0xf0,$0x2000a75
00001f96: 70                                             NOP
00001f97: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
00001f9c: d4 08 80 a4 0a 00 02 40                        LRSW3 &0x8,0x2000aa4(%r0),%r0
00001fa4: b3 40 7f 75 0a 00 02                           ORB2 %r0,$0x2000a75
00001fab: 70                                             NOP
00001fac: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
00001fb1: 87 80 a7 0a 00 02 7f 76 0a 00 02               MOVB 0x2000aa7(%r0),$0x2000a76
00001fbc: 70                                             NOP
00001fbd: 84 01 43                                       MOVW &0x1,%r3
00001fc0: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
00001fc5: eb 6f 54 47 41                                 MULB3 &0x54,%r7,%r1
00001fca: 3c 81 9c 0a 00 02 80 9c 0a 00 02               CMPW 0x2000a9c(%r1),0x2000a9c(%r0)
00001fd5: 5f 1a                                          BLEUB &0x1a <0x1fef>
00001fd7: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
00001fdc: ff 01 80 9f 0a 00 02 40                        SUBB3 &0x1,0x2000a9f(%r0),%r0
00001fe4: 87 40 7f 77 0a 00 02                           MOVB %r0,$0x2000a77
00001feb: 70                                             NOP
00001fec: 84 01 43                                       MOVW &0x1,%r3
00001fef: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
00001ff4: eb 6f 54 47 41                                 MULB3 &0x54,%r7,%r1
00001ff9: 3c 81 a0 0a 00 02 80 a0 0a 00 02               CMPW 0x2000aa0(%r1),0x2000aa0(%r0)
00002004: 5f 1a                                          BLEUB &0x1a <0x201e>
00002006: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
0000200b: ff 01 80 a3 0a 00 02 40                        SUBB3 &0x1,0x2000aa3(%r0),%r0
00002013: 87 40 7f 78 0a 00 02                           MOVB %r0,$0x2000a78
0000201a: 70                                             NOP
0000201b: 84 01 43                                       MOVW &0x1,%r3
0000201e: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
00002023: eb 6f 54 47 41                                 MULB3 &0x54,%r7,%r1
00002028: 3c 81 98 0a 00 02 80 98 0a 00 02               CMPW 0x2000a98(%r1),0x2000a98(%r0)
00002033: 5f 2f                                          BLEUB &0x2f <0x2062>
00002035: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
0000203a: d4 09 80 98 0a 00 02 40                        LRSW3 &0x9,0x2000a98(%r0),%r0
00002042: 87 40 7f 7a 0a 00 02                           MOVB %r0,$0x2000a7a
00002049: 70                                             NOP
0000204a: eb 6f 54 46 40                                 MULB3 &0x54,%r6,%r0
0000204f: d4 01 80 98 0a 00 02 40                        LRSW3 &0x1,0x2000a98(%r0),%r0
00002057: 87 40 7f 7b 0a 00 02                           MOVB %r0,$0x2000a7b
0000205e: 70                                             NOP
0000205f: 84 01 43                                       MOVW &0x1,%r3
00002062: 28 43                                          TSTW %r3
00002064: 7f 45                                          BEB &0x45 <0x20a9>
00002066: 87 46 e0 40                                    MOVB %r6,{uword}%r0
0000206a: a0 40                                          PUSHW %r0
0000206c: 2c cc fc 7f 2c 73 00 00                        CALL -4(%sp),$0x732c
00002074: 28 40                                          TSTW %r0
00002076: 77 33                                          BNEB &0x33 <0x20a9>
00002078: 2b 45                                          TSTB %r5
0000207a: 7f 2f                                          BEB &0x2f <0x20a9>
0000207c: 87 46 e0 40                                    MOVB %r6,{uword}%r0
00002080: d0 17 40 40                                    LLSW3 &0x17,%r0,%r0
00002084: b0 4f 02 00 04 00 40                           ORW2 &0x40002,%r0
0000208b: a0 40                                          PUSHW %r0
0000208d: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00002095: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
0000209c: 70                                             NOP
0000209d: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
000020a8: 70                                             NOP
000020a9: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
000020b0: 3f 02 7f 60 08 00 02                           CMPB &0x2,$0x2000860
000020b7: 4f 12                                          BLEB &0x12 <0x20c9>
000020b9: 87 7f 60 08 00 02 e2 40                        MOVB $0x2000860,{uhalf}%r0
000020c1: be 01 40                                       SUBH2 &0x1,%r0
000020c4: 86 40 44                                       MOVH %r0,%r4
000020c7: 7b 0d                                          BRB &0xd <0x20d4>
000020c9: 87 7f 60 08 00 02 e2 40                        MOVB $0x2000860,{uhalf}%r0
000020d1: 86 40 44                                       MOVH %r0,%r4
000020d4: dc 04 7f 90 04 00 00 40                        ADDW3 &0x4,$0x490,%r0
000020dc: 86 e2 44 e0 41                                 MOVH {uhalf}%r4,{uword}%r1
000020e1: 90 41                                          INCW %r1
000020e3: c8 03 00 41 50                                 INSFW &0x3,&0x0,%r1,(%r0)
000020e8: 70                                             NOP
000020e9: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
000020f1: 84 ef e8 04 00 00 50                           MOVW *$0x4e8,(%r0)
000020f8: 70                                             NOP
000020f9: dc 04 7f 90 04 00 00 40                        ADDW3 &0x4,$0x490,%r0
00002101: cc 03 00 50 40                                 EXTFW &0x3,&0x0,(%r0),%r0
00002106: a8 0c 40                                       MULW2 &0xc,%r0
00002109: 9c 40 ef e8 04 00 00                           ADDW2 %r0,*$0x4e8
00002110: 70                                             NOP
00002111: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
00002119: 86 01 d0 00                                    MOVH &0x1,*0(%r0)
0000211d: 70                                             NOP
0000211e: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
00002126: dc 02 50 40                                    ADDW3 &0x2,(%r0),%r0
0000212a: a0 40                                          PUSHW %r0
0000212c: a0 4f d1 05 00 00                              PUSHW &0x5d1
00002132: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
0000213a: 3b 7f 60 08 00 02 01                           BITB $0x2000860,&0x1
00002141: 7f 23                                          BEB &0x23 <0x2164>
00002143: 3c 4f 0d 60 5e ca 7f 84 0a 00 02               CMPW &0xca5e600d,$0x2000a84
0000214e: 77 16                                          BNEB &0x16 <0x2164>
00002150: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
00002158: 84 50 40                                       MOVW (%r0),%r0
0000215b: 86 7f 82 0a 00 02 c0 0c                        MOVH $0x2000a82,12(%r0)
00002163: 70                                             NOP
00002164: 3b 7f 60 08 00 02 02                           BITB $0x2000860,&0x2
0000216b: 7f 23                                          BEB &0x23 <0x218e>
0000216d: 3c 4f 0d 60 5e ca 7f d8 0a 00 02               CMPW &0xca5e600d,$0x2000ad8
00002178: 77 16                                          BNEB &0x16 <0x218e>
0000217a: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
00002182: 84 50 40                                       MOVW (%r0),%r0
00002185: 86 7f d6 0a 00 02 c0 18                        MOVH $0x2000ad6,24(%r0)
0000218d: 70                                             NOP
0000218e: 24 7f f0 65 00 00                              JMP $0x65f0
00002194: 04 59 4c                                       MOVAW (%fp),%sp
00002197: 20 48                                          POPW %r8
00002199: 20 47                                          POPW %r7
0000219b: 20 46                                          POPW %r6
0000219d: 20 45                                          POPW %r5
0000219f: 20 44                                          POPW %r4
000021a1: 20 43                                          POPW %r3
000021a3: 20 49                                          POPW %fp
000021a5: 08                                             RET
000021a6: 70                                             NOP
000021a7: 70                                             NOP

000021a8: 10 45                                          SAVE %r5
000021aa: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
;; Jump point from 0x191d
000021b1: 84 4f 28 0b 00 02 48                           MOVW &0x2000b28,%r8
000021b8: 84 4f e4 05 00 00 47                           MOVW &0x5e4,%r7
000021bf: 80 45                                          CLRW %r5
000021c1: 7b 12                                          BRB &0x12 <0x21d3>
000021c3: 84 48 40                                       MOVW %r8,%r0
000021c6: 90 48                                          INCW %r8
000021c8: 84 47 41                                       MOVW %r7,%r1
000021cb: 90 47                                          INCW %r7
000021cd: 87 51 50                                       MOVB (%r1),(%r0)
000021d0: 70                                             NOP
000021d1: 90 45                                          INCW %r5
000021d3: 3c 6f 44 45                                    CMPW &0x44,%r5
000021d7: 5b ec                                          BLUB &0xec <0x21c3>

;;; Stick initial PSW 0x81e180 into PCB at 0x2000b78
000021d9: 84 4f 80 e1 81 00 7f 78 0b 00 02               MOVW &0x81e180,$0x2000b78
000021e4: 70                                             NOP
;;; Stick PC 0x41f8 into PCB at 0x2000b78
000021e5: 84 4f f8 41 00 00 7f 7c 0b 00 02               MOVW &0x41f8,$0x2000b7c
000021f0: 70                                             NOP
000021f1: 84 4f e8 0e 00 02 7f 80 0b 00 02               MOVW &0x2000ee8,$0x2000b80
000021fc: 70                                             NOP
000021fd: 84 4f e8 0e 00 02 7f 90 0b 00 02               MOVW &0x2000ee8,$0x2000b90
00002208: 70                                             NOP
00002209: 84 4f e8 10 00 02 7f 94 0b 00 02               MOVW &0x20010e8,$0x2000b94
00002214: 70                                             NOP
00002215: 80 7f c4 0b 00 02                              CLRW $0x2000bc4
0000221b: 70                                             NOP
0000221c: 80 45                                          CLRW %r5

;;; GOTO 2258
0000221e: 7b 3a                                          BRB &0x3a <0x2258>

;;; Each time through this loop, we're incrementing the PCBP by 50, to
;;; point at the next PCBP.
;;;    Loop 0: r5 = 0
;;;    Loop 1: r5 = 1
;;;    Loop 2: r5 = 2, etc...
;;;
;;; %r0 accumulates the new PCBP, which we stuff into R6.

00002220: e8 6f 50 45 40                                 MULW3 &0x50,%r5,%r0
00002225: 9c 4f c8 0b 00 02 40                           ADDW2 &0x2000bc8,%r0
0000222c: 84 40 46                                       MOVW %r0,%r6
0000222f: 84 4f 80 e1 81 00 56                           MOVW &0x81e180,(%r6)
00002236: 70                                             NOP
00002237: 84 4f e8 10 00 02 c6 08                        MOVW &0x20010e8,8(%r6)
0000223f: 70                                             NOP
00002240: 84 4f e8 10 00 02 c6 18                        MOVW &0x20010e8,24(%r6)
00002248: 70                                             NOP
00002249: 84 4f e8 11 00 02 c6 1c                        MOVW &0x20011e8,28(%r6)
00002251: 70                                             NOP
00002252: 80 c6 4c                                       CLRW 76(%r6)
00002255: 70                                             NOP
00002256: 90 45                                          INCW %r5

;;; If R5 < 9, GOTO 2220
00002258: 3c 09 45                                       CMPW &0x9,%r5
0000225b: 4b c5                                          BLB &0xc5 <0x2220>

;;; After the loop, PCBPs look like this:
;;;
;;;     PSW = 0x81e180
;;;     PC = Undefined (filled out below)
;;;     Stack Pointer = 0x20010e8
;;;     Stack Lower Bound = 0x200010e8
;;;     Stack Upper Bound = 0x200011e8
;;;


;;; Now, fill the Interrupt PCB Program Counters
;;;
;;; Each interrupt vector in the ROM interrupt vectors table (located at
;;; 0x090 through 0x108) points to a PCB in RAM, consisting of
;;; at least a PSW/PC/SP "initial context". This set of MOVs appears
;;; to fill the PCB PC's
;;;

;;; PCBP = 0x2000bc8. Handler = 0x40a0
0000225d: 84 4f a0 40 00 00 7f cc 0b 00 02               MOVW &0x40a0,$0x2000bcc
00002268: 70                                             NOP

;;; PCBP = 0x2000c18. Handler = 0x40c6
00002269: 84 4f c6 40 00 00 7f 1c 0c 00 02               MOVW &0x40c6,$0x2000c1c
00002274: 70                                             NOP

;;; PCBP = 0x2000c68. Handler = 0x40ec
00002275: 84 4f ec 40 00 00 7f 6c 0c 00 02               MOVW &0x40ec,$0x2000c6c
00002280: 70                                             NOP

;;; PCBP = 0x2000cb8. Handler = 0x4112
00002281: 84 4f 12 41 00 00 7f bc 0c 00 02               MOVW &0x4112,$0x2000cbc
0000228c: 70                                             NOP

;;; PCBP = 0x2000d08. Handler = 0x4138
0000228d: 84 4f 38 41 00 00 7f 0c 0d 00 02               MOVW &0x4138,$0x2000d0c
00002298: 70                                             NOP

;;; PCBP = 0x2000d58. Handler = 0x415e
00002299: 84 4f 5e 41 00 00 7f 5c 0d 00 02               MOVW &0x415e,$0x2000d5c
000022a4: 70                                             NOP

;;; PCBP = 0x2000da8. Handler = 0x4184
000022a5: 84 4f 84 41 00 00 7f ac 0d 00 02               MOVW &0x4184,$0x2000dac
000022b0: 70                                             NOP

;;; PCBP = 0x2000df8. Handler = 0x41aa
;;; (n.b.: This PCBP doesn't seem to appear in the vector table. Mysterious!)
000022b1: 84 4f aa 41 00 00 7f fc 0d 00 02               MOVW &0x41aa,$0x2000dfc
000022bc: 70                                             NOP

;;; PCBP = 0x2000e48. Handler = 0x41d0
000022bd: 84 4f d0 41 00 00 7f 4c 0e 00 02               MOVW &0x41d0,$0x2000e4c
000022c8: 70                                             NOP

;;; PCBP = 0x2000e90. PSW = 0x81e180.
;;; (n.b.: This PCBP doesn't seem to appear in the vector table, either.)
000022c9: 84 4f 80 e1 81 00 7f 98 0e 00 02               MOVW &0x81e180,$0x2000e98
000022d4: 70                                             NOP


000022d5: 84 4f 8e 42 00 00 7f 9c 0e 00 02               MOVW &0x428e,$0x2000e9c
000022e0: 70                                             NOP
000022e1: 84 4f e8 0e 00 02 7f a0 0e 00 02               MOVW &0x2000ee8,$0x2000ea0
000022ec: 70                                             NOP
000022ed: 84 4f e8 0e 00 02 7f b0 0e 00 02               MOVW &0x2000ee8,$0x2000eb0
000022f8: 70                                             NOP
000022f9: 84 4f e8 10 00 02 7f b4 0e 00 02               MOVW &0x20010e8,$0x2000eb4
00002304: 70                                             NOP
00002305: 80 7f e4 0e 00 02                              CLRW $0x2000ee4
0000230b: 70                                             NOP
0000230c: 04 7f 28 0b 00 02 4d                           MOVAW $0x2000b28,%pcbp
00002313: 24 7f 31 23 00 00                              JMP $0x2331
00002319: 04 c9 f8 4c                                    MOVAW -8(%fp),%sp
0000231d: 20 48                                          POPW %r8
0000231f: 20 47                                          POPW %r7
00002321: 20 46                                          POPW %r6
00002323: 20 45                                          POPW %r5
00002325: 20 49                                          POPW %fp
00002327: 08                                             RET


;; Who jumps here?
00002328: 10 49                                          SAVE %fp
0000232a: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp

;; Jumped to from $0x2313
00002331: 84 4f 00 90 04 00 7f e8 11 00 02               MOVW &0x49000,$0x20011e8
0000233c: 70                                             NOP
0000233d: 2c 5c 7f 90 3b 00 00                           CALL (%sp),$0x3b90
00002344: 2c 5c af 7c 03                                 CALL (%sp),0x37c(%pc)
00002349: 87 40 59                                       MOVB %r0,(%fp)
0000234c: 70                                             NOP
0000234d: 2b 59                                          TSTB (%fp)
0000234f: 77 0a                                          BNEB &0xa <0x2359>
;; If the contents of the address pointed to by %fp are == 0,
;; jump to a failure point.
00002351: 24 7f 3e 19 00 00                              JMP $0x193e
00002357: 7b 0d                                          BRB &0xd <0x2364>
00002359: 3f 02 59                                       CMPB &0x2,(%fp)

0000235c: 77 08                                          BNEB &0x8 <0x2364>
0000235e: 24 7f d5 12 00 00                              JMP $0x12d5

;; Set the fatal "EXECUTION HALTED" bit in 2000085C
00002364: b0 4f 00 00 00 80 7f 5c 08 00 02               ORW2 &0x80000000,$0x200085c
0000236f: 70                                             NOP
00002370: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
00002377: 2c 5c 7f 7c 29 00 00                           CALL (%sp),$0x297c
0000237e: 84 40 ef e4 04 00 00                           MOVW %r0,*$0x4e4
00002385: 70                                             NOP
00002386: 84 4f 14 15 00 02 ef e8 04 00 00               MOVW &0x2001514,*$0x4e8
00002391: 70                                             NOP
00002392: 9c 20 ef e8 04 00 00                           ADDW2 &0x20,*$0x4e8
00002399: 70                                             NOP
0000239a: 87 00 e0 40                                    MOVB &0x0,{uword}%r0
0000239e: c8 03 0c 40 ef 90 04 00 00                     INSFW &0x3,&0xc,%r0,*$0x490
000023a7: 70                                             NOP
000023a8: 87 01 e0 40                                    MOVB &0x1,{uword}%r0
000023ac: c8 0f 10 40 ef 90 04 00 00                     INSFW &0xf,&0x10,%r0,*$0x490
000023b5: 70                                             NOP
000023b6: dc 04 7f 90 04 00 00 40                        ADDW3 &0x4,$0x490,%r0
000023be: 87 01 e0 41                                    MOVB &0x1,{uword}%r1
000023c2: c8 00 05 41 50                                 INSFW &0x0,&0x5,%r1,(%r0)
000023c7: 70                                             NOP
000023c8: dc 04 7f 90 04 00 00 40                        ADDW3 &0x4,$0x490,%r0
000023d0: 87 01 e0 41                                    MOVB &0x1,{uword}%r1
000023d4: c8 00 06 41 50                                 INSFW &0x0,&0x6,%r1,(%r0)
000023d9: 70                                             NOP
000023da: dc 0c 7f 90 04 00 00 40                        ADDW3 &0xc,$0x490,%r0
000023e2: a0 40                                          PUSHW %r0
000023e4: a0 4f 28 06 00 00                              PUSHW &0x628
000023ea: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
000023f2: dc 04 7f 90 04 00 00 40                        ADDW3 &0x4,$0x490,%r0
000023fa: 87 01 e0 41                                    MOVB &0x1,{uword}%r1
000023fe: c8 00 07 41 50                                 INSFW &0x0,&0x7,%r1,(%r0)
00002403: 70                                             NOP
00002404: dc 04 7f 90 04 00 00 40                        ADDW3 &0x4,$0x490,%r0
0000240c: 87 01 e0 41                                    MOVB &0x1,{uword}%r1
00002410: c8 00 09 41 50                                 INSFW &0x0,&0x9,%r1,(%r0)
00002415: 70                                             NOP
00002416: 84 4f a4 65 00 00 ef 98 04 00 00               MOVW &0x65a4,*$0x498
00002421: 70                                             NOP
00002422: 84 4f a4 65 00 00 ef 0c 05 00 00               MOVW &0x65a4,*$0x50c
0000242d: 70                                             NOP
0000242e: 2c 5c 7f 72 5f 00 00                           CALL (%sp),$0x5f72
00002435: 87 01 7f 1f 40 04 00                           MOVB &0x1,$0x4401f
0000243c: 70                                             NOP
0000243d: 87 01 ef e0 04 00 00                           MOVB &0x1,*$0x4e0
00002444: 70                                             NOP
00002445: 83 7f f1 11 00 02                              CLRB $0x20011f1
0000244b: 70                                             NOP
0000244c: 84 4f e0 25 00 00 ef 98 04 00 00               MOVW &0x25e0,*$0x498
00002457: 70                                             NOP
00002458: 84 4f e0 25 00 00 ef 0c 05 00 00               MOVW &0x25e0,*$0x50c
00002463: 70                                             NOP
00002464: 2c 5c ef c0 04 00 00                           CALL (%sp),*$0x4c0
0000246b: 24 7f 3a 25 00 00                              JMP $0x253a
00002471: 87 7f f1 11 00 02 e0 40                        MOVB $0x20011f1,{uword}%r0
00002479: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
0000247d: 83 c0 05                                       CLRB 5(%r0)
00002480: 70                                             NOP
00002481: a0 14                                          PUSHW &0x14
00002483: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
0000248b: 87 ef e0 04 00 00 e0 40                        MOVB *$0x4e0,{uword}%r0
00002493: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00002497: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
0000249e: 87 7f f1 11 00 02 e0 41                        MOVB $0x20011f1,{uword}%r1
000024a6: d0 15 41 41                                    LLSW3 &0x15,%r1,%r1
000024aa: 87 c1 01 e0 42                                 MOVB 1(%r1),{uword}%r2
000024af: c8 0f 10 42 50                                 INSFW &0xf,&0x10,%r2,(%r0)
000024b4: 70                                             NOP
000024b5: 9c 20 ef e8 04 00 00                           ADDW2 &0x20,*$0x4e8
000024bc: 70                                             NOP
000024bd: 87 ef e0 04 00 00 40                           MOVB *$0x4e0,%r0
000024c4: 93 ef e0 04 00 00                              INCB *$0x4e0
000024ca: 70                                             NOP
000024cb: 87 40 e0 40                                    MOVB %r0,{uword}%r0
000024cf: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
000024d3: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
000024da: 87 7f f1 11 00 02 e0 41                        MOVB $0x20011f1,{uword}%r1
000024e2: c8 03 0c 41 50                                 INSFW &0x3,&0xc,%r1,(%r0)
000024e7: 70                                             NOP
000024e8: 87 7f f1 11 00 02 e0 40                        MOVB $0x20011f1,{uword}%r0
000024f0: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
000024f4: 87 50 e2 40                                    MOVB (%r0),{uhalf}%r0
000024f8: 86 40 62                                       MOVH %r0,2(%fp)
000024fb: 70                                             NOP
000024fc: 97 ef e0 04 00 00                              DECB *$0x4e0
00002502: 70                                             NOP
00002503: 87 ef e0 04 00 00 e0 40                        MOVB *$0x4e0,{uword}%r0
0000250b: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
0000250f: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00002516: 84 40 64                                       MOVW %r0,4(%fp)
00002519: 70                                             NOP
0000251a: cc 0f 10 d9 04 40                              EXTFW &0xf,&0x10,*4(%fp),%r0
00002520: 86 e2 62 e0 41                                 MOVH {uhalf}2(%fp),{uword}%r1
00002525: d0 08 41 41                                    LLSW3 &0x8,%r1,%r1
00002529: b0 41 40                                       ORW2 %r1,%r0
0000252c: c8 0f 10 40 d9 04                              INSFW &0xf,&0x10,%r0,*4(%fp)
00002532: 70                                             NOP
00002533: 93 ef e0 04 00 00                              INCB *$0x4e0
00002539: 70                                             NOP
0000253a: 93 7f f1 11 00 02                              INCB $0x20011f1
00002540: 70                                             NOP
00002541: 3f 0c 7f f1 11 00 02                           CMPB &0xc,$0x20011f1
00002548: 4e 29 ff                                       BLEH &0xff29 <0x2471>
0000254b: 84 4f a4 65 00 00 ef 98 04 00 00               MOVW &0x65a4,*$0x498
00002556: 70                                             NOP
00002557: 84 4f a4 65 00 00 ef 0c 05 00 00               MOVW &0x65a4,*$0x50c
00002562: 70                                             NOP
00002563: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
0000256b: 2b 50                                          TSTB (%r0)
0000256d: 7f 28                                          BEB &0x28 <0x2595>
0000256f: 2c 5c 7f 72 5f 00 00                           CALL (%sp),$0x5f72
00002576: 2c 5c 7f 78 63 00 00                           CALL (%sp),$0x6378
0000257d: 3c 01 40                                       CMPW &0x1,%r0
00002580: 77 15                                          BNEB &0x15 <0x2595>
00002582: b0 4f 00 00 00 80 7f 5c 08 00 02               ORW2 &0x80000000,$0x200085c
0000258d: 70                                             NOP
0000258e: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
00002595: 3c 4f ef be ed fe 7f 64 08 00 02               CMPW &0xfeedbeef,$0x2000864
000025a0: 7f 2c                                          BEB &0x2c <0x25cc>
000025a2: 3c 4f 0d f0 ad 8b 7f 64 08 00 02               CMPW &0x8badf00d,$0x2000864
000025ad: 7f 1f                                          BEB &0x1f <0x25cc>
000025af: 3c 4f 1e ac eb ad 7f 64 08 00 02               CMPW &0xadebac1e,$0x2000864
000025ba: 7f 12                                          BEB &0x12 <0x25cc>
000025bc: 2c 5c af 80 00                                 CALL (%sp),0x80(%pc)
000025c1: 28 40                                          TSTW %r0
000025c3: 77 09                                          BNEB &0x9 <0x25cc>
000025c5: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
000025cc: 2c 5c 7f 72 5f 00 00                           CALL (%sp),$0x5f72
000025d3: 24 7f 01 1a 00 00                              JMP $0x1a01
000025d9: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000025dd: 20 49                                          POPW %fp
000025df: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Routine that sets the "Self-config failure" flag in 0x200085C
;;
000025e0: 10 49                                          SAVE %fp
000025e2: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
000025e9: 86 e2 7f 02 40 04 00 e0 40                     MOVH {uhalf}$0x44002,{uword}%r0
000025f2: 38 40 4f 00 80 00 00                           BITW %r0,&0x8000
000025f9: 7f 0c                                          BEB &0xc <0x2605>
000025fb: 87 01 7f 27 40 04 00                           MOVB &0x1,$0x44027
00002602: 70                                             NOP
00002603: 7b 32                                          BRB &0x32 <0x2635>
00002605: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00002610: 70                                             NOP
00002611: 2c 5c 7f 72 5f 00 00                           CALL (%sp),$0x5f72
00002618: 87 01 7f 1f 40 04 00                           MOVB &0x1,$0x4401f
0000261f: 70                                             NOP
;; This appears to set a flag meaning "Self-config failure" in the
;; failure flags.
00002620: b0 01 7f 5c 08 00 02                           ORW2 &0x1,$0x200085c
00002627: 70                                             NOP
00002628: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
0000262f: 24 7f f0 65 00 00                              JMP $0x65f0
00002635: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00002639: 20 49                                          POPW %fp
0000263b: 08                                             RET


0000263c: 10 47                                          SAVE %r7
0000263e: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00002645: 84 4f 00 40 00 02 48                           MOVW &0x2004000,%r8
0000264c: 84 4f 00 00 04 02 47                           MOVW &0x2040000,%r7
00002653: 7b 3b                                          BRB &0x3b <0x268e>
00002655: 87 5f ff 00 58                                 MOVB &0xff,(%r8)
0000265a: 70                                             NOP
0000265b: 3f 5f ff 00 58                                 CMPB &0xff,(%r8)
00002660: 7f 04                                          BEB &0x4 <0x2664>
00002662: 7b 31                                          BRB &0x31 <0x2693>
00002664: 87 5f aa 00 58                                 MOVB &0xaa,(%r8)
00002669: 70                                             NOP
0000266a: 3f 5f aa 00 58                                 CMPB &0xaa,(%r8)
0000266f: 7f 04                                          BEB &0x4 <0x2673>
00002671: 7b 22                                          BRB &0x22 <0x2693>
00002673: 87 6f 55 58                                    MOVB &0x55,(%r8)
00002677: 70                                             NOP
00002678: 3f 6f 55 58                                    CMPB &0x55,(%r8)
0000267c: 7f 04                                          BEB &0x4 <0x2680>
0000267e: 7b 15                                          BRB &0x15 <0x2693>
00002680: 83 58                                          CLRB (%r8)
00002682: 70                                             NOP
00002683: 84 48 40                                       MOVW %r8,%r0
00002686: 90 48                                          INCW %r8
00002688: 2b 50                                          TSTB (%r0)
0000268a: 7f 04                                          BEB &0x4 <0x268e>
0000268c: 7b 07                                          BRB &0x7 <0x2693>
0000268e: 3c 47 48                                       CMPW %r7,%r8
00002691: 5b c4                                          BLUB &0xc4 <0x2655>
00002693: 3c 47 48                                       CMPW %r7,%r8
00002696: 53 1a                                          BGEUB &0x1a <0x26b0>
00002698: b0 08 7f 5c 08 00 02                           ORW2 &0x8,$0x200085c
0000269f: 70                                             NOP
000026a0: 84 4f ef be ed fe 7f 64 08 00 02               MOVW &0xfeedbeef,$0x2000864
000026ab: 70                                             NOP
000026ac: 80 40                                          CLRW %r0
000026ae: 7b 07                                          BRB &0x7 <0x26b5>
000026b0: 84 01 40                                       MOVW &0x1,%r0
000026b3: 7b 02                                          BRB &0x2 <0x26b5>
000026b5: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
000026b9: 20 48                                          POPW %r8
000026bb: 20 47                                          POPW %r7
000026bd: 20 49                                          POPW %fp
000026bf: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; These look like UART tests, specifically testing the Tx/Rx buffer
;;
000026c0: 10 49                                          SAVE %fp
000026c2: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp

;; Set up the UART for our test. These three commands are as follows:
;; 0x20 = Reset Receiver (Disable receiver, flush FIFO)
;; 0x30 = Start Break (Forces TxDA output low)
;; 0x10 = Reset MR pointer. Causes channel A MR pointer to point to
;;        channel 1.

000026c9: 87 20 7f 02 90 04 00                           MOVB &0x20,$0x49002
000026d0: 70                                             NOP
000026d1: 87 30 7f 02 90 04 00                           MOVB &0x30,$0x49002
000026d8: 70                                             NOP
000026d9: 87 10 7f 02 90 04 00                           MOVB &0x10,$0x49002
000026e0: 70                                             NOP

;; Now set bit 4 of the MRA (no parity)
000026e1: 87 7f 00 90 04 00 e2 40                        MOVB $0x49000,{uhalf}%r0
000026e9: 86 40 59                                       MOVH %r0,(%fp)
000026ec: 70                                             NOP
000026ed: b3 5f 80 00 7f 00 90 04 00                     ORB2 &0x80,$0x49000
000026f6: 70                                             NOP

;; Now reset chanel a break change interrupt.
000026f7: 87 05 7f 02 90 04 00                           MOVB &0x5,$0x49002
000026fe: 70                                             NOP

;; Run the UART delay clock for 14 clock cycles
000026ff: a0 14                                          PUSHW &0x14
00002701: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528

;; Write 0x55 into the UART's buffer.
00002709: 87 6f 55 7f 03 90 04 00                        MOVB &0x55,$0x49003
00002711: 70                                             NOP

;; Run the UART delay clock for 14 clock cycles
00002712: a0 14                                          PUSHW &0x14
00002714: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528

;; Check to see if UART status bit RxRDY is set. If it is, go to next
;; check. If not, return.
0000271c: 3b 7f 01 90 04 00 01                           BITB $0x49001,&0x1
00002723: 77 0a                                          BNEB &0xa <0x272d>
00002725: 80 40                                          CLRW %r0
00002727: 24 7f 73 29 00 00                              JMP $0x2973

;; Check if 0x55 is in the UART's buffer. If it is, go to next check.
;; If not, return.
0000272d: 3f 6f 55 7f 03 90 04 00                        CMPB &0x55,$0x49003
00002735: 7f 0a                                          BEB &0xa <0x273f>
00002737: 80 40                                          CLRW %r0
00002739: 24 7f 73 29 00 00                              JMP $0x2973

;; Check to see if UART status bit RxRDY is set. If it is, go to next
;; check. If not, return.
0000273f: 3b 7f 01 90 04 00 01                           BITB $0x49001,&0x1
00002746: 7f 0a                                          BEB &0xa <0x2750>
00002748: 80 40                                          CLRW %r0

;; Write 0xAA to the TX buffer
0000274a: 24 7f 73 29 00 00                              JMP $0x2973
00002750: 87 5f aa 00 7f 03 90 04 00                     MOVB &0xaa,$0x49003
00002759: 70                                             NOP

;; Call UART delay for 14 clock cycles
0000275a: a0 14                                          PUSHW &0x14
0000275c: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528

;; Check to see if RxRDY is set again
00002764: 3b 7f 01 90 04 00 01                           BITB $0x49001,&0x1
0000276b: 77 0a                                          BNEB &0xa <0x2775>
0000276d: 80 40                                          CLRW %r0
0000276f: 24 7f 73 29 00 00                              JMP $0x2973
00002775: 3f 5f aa 00 7f 03 90 04 00                     CMPB &0xaa,$0x49003
0000277e: 7f 0a                                          BEB &0xa <0x2788>
00002780: 80 40                                          CLRW %r0
00002782: 24 7f 73 29 00 00                              JMP $0x2973
00002788: 87 20 7f 02 90 04 00                           MOVB &0x20,$0x49002
0000278f: 70                                             NOP
00002790: 87 30 7f 02 90 04 00                           MOVB &0x30,$0x49002
00002797: 70                                             NOP
00002798: 87 10 7f 02 90 04 00                           MOVB &0x10,$0x49002
0000279f: 70                                             NOP
000027a0: 87 7f 00 90 04 00 e2 40                        MOVB $0x49000,{uhalf}%r0
000027a8: 86 40 59                                       MOVH %r0,(%fp)
000027ab: 70                                             NOP
000027ac: bb 6f 7f 7f 00 90 04 00                        ANDB2 &0x7f,$0x49000
000027b4: 70                                             NOP
000027b5: 87 05 7f 02 90 04 00                           MOVB &0x5,$0x49002
000027bc: 70                                             NOP
000027bd: a0 14                                          PUSHW &0x14
000027bf: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
000027c7: 87 20 7f 0a 90 04 00                           MOVB &0x20,$0x4900a
000027ce: 70                                             NOP
000027cf: 87 30 7f 0a 90 04 00                           MOVB &0x30,$0x4900a
000027d6: 70                                             NOP
000027d7: 87 10 7f 0a 90 04 00                           MOVB &0x10,$0x4900a
000027de: 70                                             NOP
000027df: 87 7f 08 90 04 00 e2 40                        MOVB $0x49008,{uhalf}%r0
000027e7: 86 40 59                                       MOVH %r0,(%fp)
000027ea: 70                                             NOP
000027eb: b3 5f 80 00 7f 08 90 04 00                     ORB2 &0x80,$0x49008
000027f4: 70                                             NOP
000027f5: 87 05 7f 0a 90 04 00                           MOVB &0x5,$0x4900a
000027fc: 70                                             NOP
000027fd: a0 14                                          PUSHW &0x14
000027ff: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00002807: 87 6f 55 7f 0b 90 04 00                        MOVB &0x55,$0x4900b
0000280f: 70                                             NOP

00002810: a0 14                                          PUSHW &0x14
00002812: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
0000281a: 3b 7f 09 90 04 00 01                           BITB $0x49009,&0x1
00002821: 77 0a                                          BNEB &0xa <0x282b>
00002823: 80 40                                          CLRW %r0
00002825: 24 7f 73 29 00 00                              JMP $0x2973

0000282b: 3f 6f 55 7f 0b 90 04 00                        CMPB &0x55,$0x4900b
00002833: 7f 0a                                          BEB &0xa <0x283d>
00002835: 80 40                                          CLRW %r0
00002837: 24 7f 73 29 00 00                              JMP $0x2973

0000283d: 3b 7f 09 90 04 00 01                           BITB $0x49009,&0x1
00002844: 7f 0a                                          BEB &0xa <0x284e>
00002846: 80 40                                          CLRW %r0
00002848: 24 7f 73 29 00 00                              JMP $0x2973

0000284e: 87 5f aa 00 7f 0b 90 04 00                     MOVB &0xaa,$0x4900b
00002857: 70                                             NOP
00002858: a0 14                                          PUSHW &0x14
0000285a: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00002862: 3b 7f 09 90 04 00 01                           BITB $0x49009,&0x1
00002869: 77 0a                                          BNEB &0xa <0x2873>
0000286b: 80 40                                          CLRW %r0
0000286d: 24 7f 73 29 00 00                              JMP $0x2973
00002873: 3f 5f aa 00 7f 0b 90 04 00                     CMPB &0xaa,$0x4900b
0000287c: 7f 0a                                          BEB &0xa <0x2886>
0000287e: 80 40                                          CLRW %r0
00002880: 24 7f 73 29 00 00                              JMP $0x2973
00002886: 87 20 7f 0a 90 04 00                           MOVB &0x20,$0x4900a
0000288d: 70                                             NOP
0000288e: 87 30 7f 0a 90 04 00                           MOVB &0x30,$0x4900a
00002895: 70                                             NOP
00002896: 87 10 7f 0a 90 04 00                           MOVB &0x10,$0x4900a
0000289d: 70                                             NOP
0000289e: 87 7f 08 90 04 00 e0 40                        MOVB $0x49008,{uword}%r0
000028a6: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
000028aa: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
000028af: 87 7f 08 90 04 00 e0 41                        MOVB $0x49008,{uword}%r1
000028b7: 84 4f 7f ff 00 00 42                           MOVW &0xff7f,%r2
000028be: 86 e2 42 e0 42                                 MOVH {uhalf}%r2,{uword}%r2
000028c3: b8 42 41                                       ANDW2 %r2,%r1
000028c6: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
000028cb: b0 41 40                                       ORW2 %r1,%r0
000028ce: 86 40 59                                       MOVH %r0,(%fp)
000028d1: 70                                             NOP
000028d2: 87 10 7f 02 90 04 00                           MOVB &0x10,$0x49002
000028d9: 70                                             NOP
000028da: 87 10 7f 0a 90 04 00                           MOVB &0x10,$0x4900a
000028e1: 70                                             NOP
000028e2: 87 7f 00 90 04 00 7f 08 90 04 00               MOVB $0x49000,$0x49008
000028ed: 70                                             NOP
000028ee: 87 7f 00 90 04 00 7f 08 90 04 00               MOVB $0x49000,$0x49008
000028f9: 70                                             NOP
000028fa: 87 05 7f 0a 90 04 00                           MOVB &0x5,$0x4900a
00002901: 70                                             NOP
00002902: a0 14                                          PUSHW &0x14
00002904: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
0000290c: 87 20 7f 03 90 04 00                           MOVB &0x20,$0x49003
00002913: 70                                             NOP
00002914: a0 14                                          PUSHW &0x14
00002916: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
0000291e: 3b 7f 09 90 04 00 01                           BITB $0x49009,&0x1
00002925: 7f 10                                          BEB &0x10 <0x2935>
00002927: 3f 20 7f 0b 90 04 00                           CMPB &0x20,$0x4900b
0000292e: 77 07                                          BNEB &0x7 <0x2935>
00002930: 84 02 40                                       MOVW &0x2,%r0
00002933: 7b 40                                          BRB &0x40 <0x2973>
00002935: 87 20 7f 0a 90 04 00                           MOVB &0x20,$0x4900a
0000293c: 70                                             NOP
0000293d: 87 30 7f 0a 90 04 00                           MOVB &0x30,$0x4900a
00002944: 70                                             NOP
00002945: 87 10 7f 0a 90 04 00                           MOVB &0x10,$0x4900a
0000294c: 70                                             NOP
0000294d: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00002952: d4 08 40 40                                    LRSW3 &0x8,%r0,%r0
00002956: 87 40 7f 08 90 04 00                           MOVB %r0,$0x49008
0000295d: 70                                             NOP
0000295e: 87 61 7f 08 90 04 00                           MOVB 1(%fp),$0x49008
00002965: 70                                             NOP
00002966: 87 05 7f 0a 90 04 00                           MOVB &0x5,$0x4900a
0000296d: 70                                             NOP
0000296e: 84 01 40                                       MOVW &0x1,%r0
00002971: 7b 02                                          BRB &0x2 <0x2973>

00002973: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00002977: 20 49                                          POPW %fp
00002979: 08                                             RET
0000297a: 70                                             NOP
0000297b: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Set up RAM size. This procedure tests two bits at 0x4C003, and uses
;;; them to determine how much RAM is installed in the system.
;;; The mapping is essentially:
;;;
;;;  0x4C003         Installed RAM
;;; ---------        -------------
;;;    00b               512KB
;;;    01b               2MB
;;;    10b               1MB
;;;    11b               4MB
;;;
0000297c: 10 45                                          SAVE %r5
0000297e: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00002985: 84 4f c4 2a 00 00 7f f4 11 00 02               MOVW &0x2ac4,$0x20011f4
00002990: 70                                             NOP
00002991: 84 4f dc 2a 00 00 7f f8 11 00 02               MOVW &0x2adc,$0x20011f8
0000299c: 70                                             NOP
0000299d: 83 ef c4 04 00 00                              CLRB *$0x4c4
000029a3: 70                                             NOP
000029a4: 83 7f f2 11 00 02                              CLRB $0x20011f2
000029aa: 70                                             NOP
000029ab: 80 46                                          CLRW %r6
000029ad: 3b 7f 03 c0 04 00 01                           BITB $0x4c003,&0x1
000029b4: 7f 0e                                          BEB &0xe <0x29c2>
000029b6: 84 4f 00 00 10 00 48                           MOVW &0x100000,%r8
000029bd: 84 48 40                                       MOVW %r8,%r0
000029c0: 7b 0c                                          BRB &0xc <0x29cc>
000029c2: 84 4f 00 00 04 00 48                           MOVW &0x40000,%r8
000029c9: 84 48 40                                       MOVW %r8,%r0
000029cc: 3b 7f 03 c0 04 00 02                           BITB $0x4c003,&0x2
000029d3: 7f 06                                          BEB &0x6 <0x29d9>
000029d5: d0 01 48 48                                    LLSW3 &0x1,%r8,%r8
000029d9: 2c 5c ef c0 04 00 00                           CALL (%sp),*$0x4c0
000029e0: 2b 7f f2 11 00 02                              TSTB $0x20011f2
000029e6: 7f 08                                          BEB &0x8 <0x29ee>
000029e8: 24 7f 97 2a 00 00                              JMP $0x2a97
000029ee: 3c 4f d0 f1 02 3b 7f 6c 08 00 02               CMPW &0x3b02f1d0,$0x200086c
000029f9: 77 09                                          BNEB &0x9 <0x2a02>
000029fb: 84 88 00 00 00 02 47                           MOVW 0x2000000(%r8),%r7
00002a02: 84 4f ef be ed fe 88 00 00 00 02               MOVW &0xfeedbeef,0x2000000(%r8)
00002a0d: 70                                             NOP
00002a0e: 3c 4f ef be ed fe 88 00 00 00 02               CMPW &0xfeedbeef,0x2000000(%r8)
00002a19: 77 05                                          BNEB &0x5 <0x2a1e>
00002a1b: 84 01 46                                       MOVW &0x1,%r6
00002a1e: 84 47 88 00 00 00 02                           MOVW %r7,0x2000000(%r8)
00002a25: 70                                             NOP
00002a26: 28 46                                          TSTW %r6
00002a28: 7f 6f                                          BEB &0x6f <0x2a97>
00002a2a: 3c 4f 00 00 20 00 48                           CMPW &0x200000,%r8
00002a31: 77 66                                          BNEB &0x66 <0x2a97>
00002a33: e8 03 48 40                                    MULW3 &0x3,%r8,%r0
00002a37: ac 04 40                                       DIVW2 &0x4,%r0
00002a3a: 70                                             NOP
00002a3b: 84 40 48                                       MOVW %r0,%r8
00002a3e: d0 01 48 40                                    LLSW3 &0x1,%r8,%r0
00002a42: 84 40 45                                       MOVW %r0,%r5
00002a45: 83 7f f2 11 00 02                              CLRB $0x20011f2
00002a4b: 70                                             NOP
00002a4c: 2c 5c ef c0 04 00 00                           CALL (%sp),*$0x4c0
00002a53: 2b 7f f2 11 00 02                              TSTB $0x20011f2
00002a59: 77 3e                                          BNEB &0x3e <0x2a97>
00002a5b: 3c 4f d0 f1 02 3b 7f 6c 08 00 02               CMPW &0x3b02f1d0,$0x200086c
00002a66: 77 09                                          BNEB &0x9 <0x2a6f>
00002a68: 84 85 00 00 00 02 47                           MOVW 0x2000000(%r5),%r7
00002a6f: 84 4f ef be ed fe 85 00 00 00 02               MOVW &0xfeedbeef,0x2000000(%r5)
00002a7a: 70                                             NOP
00002a7b: 3c 4f ef be ed fe 85 00 00 00 02               CMPW &0xfeedbeef,0x2000000(%r5)
00002a86: 77 09                                          BNEB &0x9 <0x2a8f>
00002a88: 84 4f 00 00 20 00 48                           MOVW &0x200000,%r8
00002a8f: 84 47 85 00 00 00 02                           MOVW %r7,0x2000000(%r5)
00002a96: 70                                             NOP
00002a97: 84 4f a4 65 00 00 7f f4 11 00 02               MOVW &0x65a4,$0x20011f4
00002aa2: 70                                             NOP
00002aa3: 84 4f 04 65 00 00 7f f8 11 00 02               MOVW &0x6504,$0x20011f8
00002aae: 70                                             NOP
00002aaf: d0 46 48 40                                    LLSW3 %r6,%r8,%r0
00002ab3: 7b 02                                          BRB &0x2 <0x2ab5>
00002ab5: 04 c9 f8 4c                                    MOVAW -8(%fp),%sp
00002ab9: 20 48                                          POPW %r8
00002abb: 20 47                                          POPW %r7
00002abd: 20 46                                          POPW %r6
00002abf: 20 45                                          POPW %r5
00002ac1: 20 49                                          POPW %fp
00002ac3: 08                                             RET


00002ac4: 10 49                                          SAVE %fp
00002ac6: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00002acd: 87 01 7f f2 11 00 02                           MOVB &0x1,$0x20011f2
00002ad4: 70                                             NOP
00002ad5: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00002ad9: 20 49                                          POPW %fp
00002adb: 08                                             RET


00002adc: 10 49                                          SAVE %fp
00002ade: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00002ae5: 84 4f 00 e1 81 00 cd 0c                        MOVW &0x81e100,12(%pcbp)
00002aed: 70                                             NOP
00002aee: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00002af2: 20 49                                          POPW %fp
00002af4: 08                                             RET
00002af5: 70                                             NOP
00002af6: 70                                             NOP
00002af7: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exception Return Point Routine (excret)
;;
00002af8: 84 cc f8 7f fc 11 00 02                        MOVW -8(%sp),$0x20011fc
00002b00: 70                                             NOP
00002b01: 08                                             RET
00002b02: 70                                             NOP
00002b03: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine
;;
00002b04: 10 49                                          SAVE %fp
00002b06: 9c 4f b8 01 00 00 4c                           ADDW2 &0x1b8,%sp
00002b0d: a0 4f 0d 30 04 00                              PUSHW &0x4300d
00002b13: e0 59                                          PUSHAW (%fp)
00002b15: a0 2d                                          PUSHW &0x2d
00002b17: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
;; Print "\nEnter name of program to execute [%s]"
00002b1f: a0 4f 2c 06 00 00                              PUSHW &0x62c
00002b25: e0 59                                          PUSHAW (%fp)
00002b27: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00002b2f: a0 00                                          PUSHW &0x0
00002b31: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
00002b39: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002b41: a0 40                                          PUSHW %r0
00002b43: 2c cc fc 7f 60 43 00 00                        CALL -4(%sp),$0x4360
00002b4b: 3c ff 40                                       CMPW &-1,%r0
00002b4e: 77 20                                          BNEB &0x20 <0x2b6e>
00002b50: a0 01                                          PUSHW &0x1
00002b52: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
;; Print "\n"
00002b5a: a0 4f 57 06 00 00                              PUSHW &0x657
00002b60: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002b68: 24 7f ab 3a 00 00                              JMP $0x3aab
00002b6e: a0 01                                          PUSHW &0x1
00002b70: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
00002b78: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002b80: a0 40                                          PUSHW %r0
00002b82: a0 4f 59 06 00 00                              PUSHW &0x659
00002b88: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002b90: 28 40                                          TSTW %r0
00002b92: 7f 08                                          BEB &0x8 <0x2b9a>
00002b94: 24 7f 6b 2c 00 00                              JMP $0x2c6b
;; Print "\nenter old password: "
00002b9a: a0 4f 60 06 00 00                              PUSHW &0x660
00002ba0: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002ba8: e0 c9 50                                       PUSHAW 80(%fp)
00002bab: 2c cc fc af 09 0f                              CALL -4(%sp),0xf09(%pc)
00002bb1: 28 40                                          TSTW %r0
00002bb3: 77 07                                          BNEB &0x7 <0x2bba>
00002bb5: 2c 5c af 59 0f                                 CALL (%sp),0xf59(%pc)
00002bba: a0 4f 00 30 04 00                              PUSHW &0x43000
00002bc0: e0 c9 5a                                       PUSHAW 90(%fp)
00002bc3: a0 09                                          PUSHW &0x9
00002bc5: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00002bcd: e0 c9 50                                       PUSHAW 80(%fp)
00002bd0: e0 c9 5a                                       PUSHAW 90(%fp)
00002bd3: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002bdb: 28 40                                          TSTW %r0
00002bdd: 7f 07                                          BEB &0x7 <0x2be4>
00002bdf: 2c 5c af 2f 0f                                 CALL (%sp),0xf2f(%pc)
;; Print "\nenter new password: "
00002be4: a0 4f 76 06 00 00                              PUSHW &0x676
00002bea: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002bf2: e0 59                                          PUSHAW (%fp)
00002bf4: 2c cc fc af c0 0e                              CALL -4(%sp),0xec0(%pc)
00002bfa: 28 40                                          TSTW %r0
00002bfc: 77 07                                          BNEB &0x7 <0x2c03>
00002bfe: 2c 5c af 10 0f                                 CALL (%sp),0xf10(%pc)
;; Print "\nconfirmation: "
00002c03: a0 4f 8c 06 00 00                              PUSHW &0x68c
00002c09: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002c11: e0 c9 50                                       PUSHAW 80(%fp)
00002c14: 2c cc fc af a0 0e                              CALL -4(%sp),0xea0(%pc)
00002c1a: 28 40                                          TSTW %r0
00002c1c: 77 07                                          BNEB &0x7 <0x2c23>
00002c1e: 2c 5c af f0 0e                                 CALL (%sp),0xef0(%pc)
00002c23: e0 c9 50                                       PUSHAW 80(%fp)
00002c26: e0 59                                          PUSHAW (%fp)
00002c28: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002c30: 28 40                                          TSTW %r0
00002c32: 7f 07                                          BEB &0x7 <0x2c39>
00002c34: 2c 5c af da 0e                                 CALL (%sp),0xeda(%pc)
;; Print "\nnewkey"
00002c39: a0 4f 9c 06 00 00                              PUSHW &0x69c
00002c3f: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002c47: e0 59                                          PUSHAW (%fp)
00002c49: a0 4f 00 30 04 00                              PUSHW &0x43000
00002c4f: e0 59                                          PUSHAW (%fp)
00002c51: 2c cc fc 7f 98 7f 00 00                        CALL -4(%sp),$0x7f98
00002c59: 90 40                                          INCW %r0
00002c5b: a0 40                                          PUSHW %r0
00002c5d: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00002c65: 24 7f a8 3a 00 00                              JMP $0x3aa8
00002c6b: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002c73: a0 40                                          PUSHW %r0
00002c75: a0 4f 9e 06 00 00                              PUSHW &0x69e
00002c7b: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002c83: 28 40                                          TSTW %r0
00002c85: 7f 08                                          BEB &0x8 <0x2c8d>
00002c87: 24 7f 52 2d 00 00                              JMP $0x2d52
;; Print "Creating a floppy key to to enable clearing of saved NVRAM information\n"
00002c8d: a0 4f a5 06 00 00                              PUSHW &0x6a5
00002c93: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002c9b: 83 59                                          CLRB (%fp)
00002c9d: 70                                             NOP
00002c9e: 7b 26                                          BRB &0x26 <0x2cc4>
;; Print "Insert a formatted floppy, then type 'go' (q to quit)"
00002ca0: a0 4f ef 06 00 00                              PUSHW &0x6ef
00002ca6: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002cae: e0 59                                          PUSHAW (%fp)
00002cb0: 2c cc fc 7f 60 43 00 00                        CALL -4(%sp),$0x4360
00002cb8: 3f 6f 71 59                                    CMPB &0x71,(%fp)
00002cbc: 77 08                                          BNEB &0x8 <0x2cc4>
00002cbe: 24 7f ab 3a 00 00                              JMP $0x3aab
00002cc4: e0 59                                          PUSHAW (%fp)
00002cc6: a0 4f ec 06 00 00                              PUSHW &0x6ec
00002ccc: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002cd4: 28 40                                          TSTW %r0
00002cd6: 77 ca                                          BNEB &0xca <0x2ca0>
00002cd8: dc 03 7f 08 05 00 00 40                        ADDW3 &0x3,$0x508,%r0
00002ce0: 87 50 c9 5a                                    MOVB (%r0),90(%fp)
00002ce4: 70                                             NOP
00002ce5: dc 07 7f 08 05 00 00 40                        ADDW3 &0x7,$0x508,%r0
00002ced: 87 50 c9 5b                                    MOVB (%r0),91(%fp)
00002cf1: 70                                             NOP
00002cf2: dc 0b 7f 08 05 00 00 40                        ADDW3 &0xb,$0x508,%r0
00002cfa: 87 50 c9 5c                                    MOVB (%r0),92(%fp)
00002cfe: 70                                             NOP
00002cff: dc 0f 7f 08 05 00 00 40                        ADDW3 &0xf,$0x508,%r0
00002d07: 87 50 c9 5d                                    MOVB (%r0),93(%fp)
00002d0b: 70                                             NOP
00002d0c: a0 00                                          PUSHW &0x0
00002d0e: e0 c9 5a                                       PUSHAW 90(%fp)
00002d11: a0 01                                          PUSHW &0x1
00002d13: a0 03                                          PUSHW &0x3
00002d15: 2c cc f0 7f 2c 7b 00 00                        CALL -16(%sp),$0x7b2c
00002d1d: 28 40                                          TSTW %r0
00002d1f: 77 1f                                          BNEB &0x1f <0x2d3e>
00002d21: b0 20 7f 5c 08 00 02                           ORW2 &0x20,$0x200085c
00002d28: 70                                             NOP
00002d29: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
00002d30: a0 4f ef be ed fe                              PUSHW &0xfeedbeef
00002d36: 2c cc fc 7f 22 63 00 00                        CALL -4(%sp),$0x6322
00002d3e: a0 4f 27 07 00 00                              PUSHW &0x727
00002d44: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002d4c: 24 7f a8 3a 00 00                              JMP $0x3aa8
00002d52: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002d5a: a0 40                                          PUSHW %r0
00002d5c: a0 4f 4a 07 00 00                              PUSHW &0x74a
00002d62: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002d6a: 28 40                                          TSTW %r0
00002d6c: 77 1d                                          BNEB &0x1d <0x2d89>
00002d6e: 2c 5c 7f 00 40 00 02                           CALL (%sp),$0x2004000
00002d75: a0 4f ef be ed fe                              PUSHW &0xfeedbeef
00002d7b: 2c cc fc 7f 22 63 00 00                        CALL -4(%sp),$0x6322
00002d83: 24 7f a8 3a 00 00                              JMP $0x3aa8
00002d89: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002d91: a0 40                                          PUSHW %r0
00002d93: a0 4f 52 07 00 00                              PUSHW &0x752
00002d99: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002da1: 28 40                                          TSTW %r0
00002da3: 7f 08                                          BEB &0x8 <0x2dab>
00002da5: 24 7f 38 2e 00 00                              JMP $0x2e38
;; Print "Created: 05/31/85"
00002dab: a0 4f 5a 07 00 00                              PUSHW &0x75a
00002db1: a0 4f 58 11 00 00                              PUSHW &0x1158
00002db7: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
;; Print "Issue: %s"
00002dbf: a0 4f 68 07 00 00                              PUSHW &0x768
00002dc5: a0 7f f0 7f 00 00                              PUSHW $0x7ff0
00002dcb: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
;; Print "Release: 1.2.1.PF3"
00002dd3: a0 4f 76 07 00 00                              PUSHW &0x776
00002dd9: a0 4f 68 11 00 00                              PUSHW &0x1168
00002ddf: a0 4f 64 11 00 00                              PUSHW &0x1164
00002de5: 2c cc f4 7f e4 44 00 00                        CALL -12(%sp),$0x44e4
00002ded: a0 4f 8c 07 00 00                              PUSHW &0x78c
00002df3: 87 7f f3 7f 00 00 e0 40                        MOVB $0x7ff3,{uword}%r0
00002dfb: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
00002dff: 87 7f f7 7f 00 00 e0 41                        MOVB $0x7ff7,{uword}%r1
00002e07: b0 41 40                                       ORW2 %r1,%r0
00002e0a: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
00002e0e: 87 7f fb 7f 00 00 e0 41                        MOVB $0x7ffb,{uword}%r1
00002e16: b0 41 40                                       ORW2 %r1,%r0
00002e19: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
00002e1d: 87 7f ff 7f 00 00 e0 41                        MOVB $0x7fff,{uword}%r1
00002e25: b0 41 40                                       ORW2 %r1,%r0
00002e28: a0 40                                          PUSHW %r0
00002e2a: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00002e32: 24 7f a8 3a 00 00                              JMP $0x3aa8
00002e38: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002e40: a0 40                                          PUSHW %r0
00002e42: a0 4f a3 07 00 00                              PUSHW &0x7a3
00002e48: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002e50: 28 40                                          TSTW %r0
00002e52: 77 08                                          BNEB &0x8 <0x2e5a>
00002e54: 24 7f ab 3a 00 00                              JMP $0x3aab
00002e5a: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002e62: a0 40                                          PUSHW %r0
00002e64: a0 4f a5 07 00 00                              PUSHW &0x7a5
00002e6a: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002e72: 28 40                                          TSTW %r0
00002e74: 77 0f                                          BNEB &0xf <0x2e83>
00002e76: 2c 5c 7f 14 4e 00 00                           CALL (%sp),$0x4e14
00002e7d: 24 7f a8 3a 00 00                              JMP $0x3aa8
00002e83: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002e8b: a0 40                                          PUSHW %r0
00002e8d: a0 4f a9 07 00 00                              PUSHW &0x7a9
00002e93: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002e9b: 28 40                                          TSTW %r0
00002e9d: 77 0f                                          BNEB &0xf <0x2eac>
00002e9f: 2c 5c 7f e6 5f 00 00                           CALL (%sp),$0x5fe6
00002ea6: 24 7f a8 3a 00 00                              JMP $0x3aa8
00002eac: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002eb4: a0 40                                          PUSHW %r0
00002eb6: a0 4f b4 07 00 00                              PUSHW &0x7b4
00002ebc: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002ec4: 28 40                                          TSTW %r0
00002ec6: 77 0f                                          BNEB &0xf <0x2ed5>
00002ec8: 2c 5c 7f cc 3f 00 00                           CALL (%sp),$0x3fcc
00002ecf: 24 7f a8 3a 00 00                              JMP $0x3aa8
00002ed5: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002edd: a0 40                                          PUSHW %r0
00002edf: a0 4f b9 07 00 00                              PUSHW &0x7b9
00002ee5: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00002eed: 28 40                                          TSTW %r0
00002eef: 77 32                                          BNEB &0x32 <0x2f21>
;; Print "\nEnter an executable or system file, a directory name, "
00002ef1: a0 4f bb 07 00 00                              PUSHW &0x7bb
00002ef7: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
;; Print "or one of the possible firmware program names:\n\n"
00002eff: a0 4f f3 07 00 00                              PUSHW &0x7f3
00002f05: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
;; Print: "baud    edt    newkey    passwd    sysdump    version    q(uit)"
00002f0d: a0 4f 24 08 00 00                              PUSHW &0x824
00002f13: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00002f1b: 24 7f a8 3a 00 00                              JMP $0x3aa8
00002f21: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002f29: 2b 50                                          TSTB (%r0)
00002f2b: 77 16                                          BNEB &0x16 <0x2f41>
00002f2d: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00002f35: a0 40                                          PUSHW %r0
00002f37: e0 59                                          PUSHAW (%fp)
00002f39: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
00002f41: 82 a9 b4 00                                    CLRH 0xb4(%fp)
00002f45: 70                                             NOP
00002f46: 7b 5e                                          BRB &0x5e <0x2fa4>
00002f48: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00002f4d: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
00002f53: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00002f57: 9c 41 40                                       ADDW2 %r1,%r0
00002f5a: 82 50                                          CLRH (%r0)
00002f5c: 70                                             NOP
00002f5d: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00002f62: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
00002f68: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00002f6c: 9c 41 40                                       ADDW2 %r1,%r0
00002f6f: 82 c0 02                                       CLRH 2(%r0)
00002f72: 70                                             NOP
00002f73: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00002f78: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
00002f7e: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00002f82: 9c 41 40                                       ADDW2 %r1,%r0
00002f85: 82 c0 04                                       CLRH 4(%r0)
00002f88: 70                                             NOP
00002f89: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00002f8e: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
00002f94: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00002f98: 9c 41 40                                       ADDW2 %r1,%r0
00002f9b: 83 c0 06                                       CLRB 6(%r0)
00002f9e: 70                                             NOP
00002f9f: 92 a9 b4 00                                    INCH 0xb4(%fp)
00002fa3: 70                                             NOP
00002fa4: 3e 10 a9 b4 00                                 CMPH &0x10,0xb4(%fp)
00002fa9: 4b 9f                                          BLB &0x9f <0x2f48>
00002fab: 83 a9 ac 00                                    CLRB 0xac(%fp)
00002faf: 70                                             NOP
00002fb0: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00002fb5: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00002fbb: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00002fbf: 9c 41 40                                       ADDW2 %r1,%r0
00002fc2: 9c 06 40                                       ADDW2 &0x6,%r0
00002fc5: a0 40                                          PUSHW %r0
00002fc7: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
00002fcf: dc 02 50 40                                    ADDW3 &0x2,(%r0),%r0
00002fd3: a0 40                                          PUSHW %r0
00002fd5: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
00002fdd: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00002fe2: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00002fe8: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00002fec: 9c 41 40                                       ADDW2 %r1,%r0
00002fef: 86 01 c0 02                                    MOVH &0x1,2(%r0)
00002ff3: 70                                             NOP
00002ff4: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00002ff9: 87 a9 ac 00 41                                 MOVB 0xac(%fp),%r1
00002ffe: 93 a9 ac 00                                    INCB 0xac(%fp)
00003002: 70                                             NOP
00003003: 87 41 e0 41                                    MOVB %r1,{uword}%r1
00003007: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000300b: 9c 41 40                                       ADDW2 %r1,%r0
0000300e: 82 50                                          CLRH (%r0)
00003010: 70                                             NOP
00003011: 87 7f 60 08 00 02 e0 40                        MOVB $0x2000860,{uword}%r0
00003019: 24 7f b5 31 00 00                              JMP $0x31b5
0000301f: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003024: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
0000302a: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000302e: 9c 41 40                                       ADDW2 %r1,%r0
00003031: 9c 06 40                                       ADDW2 &0x6,%r0
00003034: a0 40                                          PUSHW %r0
00003036: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
0000303e: dc 0e 50 40                                    ADDW3 &0xe,(%r0),%r0
00003042: a0 40                                          PUSHW %r0
00003044: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
0000304c: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003051: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00003057: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000305b: 9c 41 40                                       ADDW2 %r1,%r0
0000305e: 86 01 c0 02                                    MOVH &0x1,2(%r0)
00003062: 70                                             NOP
00003063: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003068: 87 a9 ac 00 41                                 MOVB 0xac(%fp),%r1
0000306d: 93 a9 ac 00                                    INCB 0xac(%fp)
00003071: 70                                             NOP
00003072: 87 41 e0 41                                    MOVB %r1,{uword}%r1
00003076: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000307a: 9c 41 40                                       ADDW2 %r1,%r0
0000307d: 86 01 50                                       MOVH &0x1,(%r0)
00003080: 70                                             NOP
00003081: 24 7f c7 31 00 00                              JMP $0x31c7
00003087: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
0000308c: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00003092: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003096: 9c 41 40                                       ADDW2 %r1,%r0
00003099: 9c 06 40                                       ADDW2 &0x6,%r0
0000309c: a0 40                                          PUSHW %r0
0000309e: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
000030a6: dc 1a 50 40                                    ADDW3 &0x1a,(%r0),%r0
000030aa: a0 40                                          PUSHW %r0
000030ac: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
000030b4: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000030b9: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
000030bf: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000030c3: 9c 41 40                                       ADDW2 %r1,%r0
000030c6: 86 01 c0 02                                    MOVH &0x1,2(%r0)
000030ca: 70                                             NOP
000030cb: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000030d0: 87 a9 ac 00 41                                 MOVB 0xac(%fp),%r1
000030d5: 93 a9 ac 00                                    INCB 0xac(%fp)
000030d9: 70                                             NOP
000030da: 87 41 e0 41                                    MOVB %r1,{uword}%r1
000030de: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000030e2: 9c 41 40                                       ADDW2 %r1,%r0
000030e5: 86 02 50                                       MOVH &0x2,(%r0)
000030e8: 70                                             NOP
000030e9: 24 7f c7 31 00 00                              JMP $0x31c7
000030ef: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000030f4: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
000030fa: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000030fe: 9c 41 40                                       ADDW2 %r1,%r0
00003101: 9c 06 40                                       ADDW2 &0x6,%r0
00003104: a0 40                                          PUSHW %r0
00003106: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
0000310e: dc 0e 50 40                                    ADDW3 &0xe,(%r0),%r0
00003112: a0 40                                          PUSHW %r0
00003114: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
0000311c: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003121: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00003127: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000312b: 9c 41 40                                       ADDW2 %r1,%r0
0000312e: 86 01 c0 02                                    MOVH &0x1,2(%r0)
00003132: 70                                             NOP
00003133: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003138: 87 a9 ac 00 41                                 MOVB 0xac(%fp),%r1
0000313d: 93 a9 ac 00                                    INCB 0xac(%fp)
00003141: 70                                             NOP
00003142: 87 41 e0 41                                    MOVB %r1,{uword}%r1
00003146: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000314a: 9c 41 40                                       ADDW2 %r1,%r0
0000314d: 86 01 50                                       MOVH &0x1,(%r0)
00003150: 70                                             NOP
00003151: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003156: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
0000315c: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003160: 9c 41 40                                       ADDW2 %r1,%r0
00003163: 9c 06 40                                       ADDW2 &0x6,%r0
00003166: a0 40                                          PUSHW %r0
00003168: dc 08 7f 90 04 00 00 40                        ADDW3 &0x8,$0x490,%r0
00003170: dc 1a 50 40                                    ADDW3 &0x1a,(%r0),%r0
00003174: a0 40                                          PUSHW %r0
00003176: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
0000317e: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003183: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00003189: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000318d: 9c 41 40                                       ADDW2 %r1,%r0
00003190: 86 01 c0 02                                    MOVH &0x1,2(%r0)
00003194: 70                                             NOP
00003195: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
0000319a: 87 a9 ac 00 41                                 MOVB 0xac(%fp),%r1
0000319f: 93 a9 ac 00                                    INCB 0xac(%fp)
000031a3: 70                                             NOP
000031a4: 87 41 e0 41                                    MOVB %r1,{uword}%r1
000031a8: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000031ac: 9c 41 40                                       ADDW2 %r1,%r0
000031af: 86 02 50                                       MOVH &0x2,(%r0)
000031b2: 70                                             NOP
000031b3: 7b 14                                          BRB &0x14 <0x31c7>
000031b5: 3c 40 01                                       CMPW %r0,&0x1
000031b8: 7e 67 fe                                       BEH &0xfe67 <0x301f>
000031bb: 3c 40 02                                       CMPW %r0,&0x2
000031be: 7e c9 fe                                       BEH &0xfec9 <0x3087>
000031c1: 3c 40 03                                       CMPW %r0,&0x3
000031c4: 7e 2b ff                                       BEH &0xff2b <0x30ef>
000031c7: 86 01 a9 b4 00                                 MOVH &0x1,0xb4(%fp)
000031cc: 70                                             NOP
000031cd: 24 7f 39 33 00 00                              JMP $0x3339
000031d3: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
000031d9: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
000031dd: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
000031e4: cc 00 07 c0 04 40                              EXTFW &0x0,&0x7,4(%r0),%r0
000031ea: 3c 00 40                                       CMPW &0x0,%r0
000031ed: 77 08                                          BNEB &0x8 <0x31f5>
000031ef: 24 7f 93 32 00 00                              JMP $0x3293
000031f5: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000031fa: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00003200: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003204: 9c 41 40                                       ADDW2 %r1,%r0
00003207: 9c 06 40                                       ADDW2 &0x6,%r0
0000320a: a0 40                                          PUSHW %r0
0000320c: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
00003212: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00003216: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
0000321d: 9c 0c 40                                       ADDW2 &0xc,%r0
00003220: a0 40                                          PUSHW %r0
00003222: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
0000322a: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
0000322f: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00003235: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003239: 9c 41 40                                       ADDW2 %r1,%r0
0000323c: 82 c0 02                                       CLRH 2(%r0)
0000323f: 70                                             NOP
00003240: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003245: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
0000324b: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000324f: 9c 41 40                                       ADDW2 %r1,%r0
00003252: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
00003258: d0 05 41 41                                    LLSW3 &0x5,%r1,%r1
0000325c: 9c 7f 90 04 00 00 41                           ADDW2 $0x490,%r1
00003263: cc 03 0c 51 41                                 EXTFW &0x3,&0xc,(%r1),%r1
00003268: 86 41 c0 04                                    MOVH %r1,4(%r0)
0000326c: 70                                             NOP
0000326d: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003272: 87 a9 ac 00 41                                 MOVB 0xac(%fp),%r1
00003277: 93 a9 ac 00                                    INCB 0xac(%fp)
0000327b: 70                                             NOP
0000327c: 87 41 e0 41                                    MOVB %r1,{uword}%r1
00003280: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003284: 9c 41 40                                       ADDW2 %r1,%r0
00003287: 86 a9 b4 00 50                                 MOVH 0xb4(%fp),(%r0)
0000328c: 70                                             NOP
0000328d: 24 7f 34 33 00 00                              JMP $0x3334
00003293: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
00003299: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
0000329d: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
000032a4: 2b c0 0c                                       TSTB 12(%r0)
000032a7: 7f 2a                                          BEB &0x2a <0x32d1>
000032a9: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
000032af: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
000032b3: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
000032ba: 9c 0c 40                                       ADDW2 &0xc,%r0
000032bd: a0 40                                          PUSHW %r0
000032bf: a0 4f 66 08 00 00                              PUSHW &0x866
000032c5: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
000032cd: 28 40                                          TSTW %r0
000032cf: 77 65                                          BNEB &0x65 <0x3334>
000032d1: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000032d6: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
000032dc: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000032e0: 9c 41 40                                       ADDW2 %r1,%r0
000032e3: 82 c0 02                                       CLRH 2(%r0)
000032e6: 70                                             NOP
000032e7: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000032ec: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
000032f2: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000032f6: 9c 41 40                                       ADDW2 %r1,%r0
000032f9: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
000032ff: d0 05 41 41                                    LLSW3 &0x5,%r1,%r1
00003303: 9c 7f 90 04 00 00 41                           ADDW2 $0x490,%r1
0000330a: cc 03 0c 51 41                                 EXTFW &0x3,&0xc,(%r1),%r1
0000330f: 86 41 c0 04                                    MOVH %r1,4(%r0)
00003313: 70                                             NOP
00003314: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003319: 87 a9 ac 00 41                                 MOVB 0xac(%fp),%r1
0000331e: 93 a9 ac 00                                    INCB 0xac(%fp)
00003322: 70                                             NOP
00003323: 87 41 e0 41                                    MOVB %r1,{uword}%r1
00003327: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000332b: 9c 41 40                                       ADDW2 %r1,%r0
0000332e: 86 a9 b4 00 50                                 MOVH 0xb4(%fp),(%r0)
00003333: 70                                             NOP
00003334: 92 a9 b4 00                                    INCH 0xb4(%fp)
00003338: 70                                             NOP
00003339: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
0000333f: 87 ef e0 04 00 00 e0 41                        MOVB *$0x4e0,{uword}%r1
00003347: 3c 41 40                                       CMPW %r1,%r0
0000334a: 4a 89 fe                                       BLH &0xfe89 <0x31d3>
;; Print "Possible load devices are:\n\n"
0000334d: a0 4f 6d 08 00 00                              PUSHW &0x86d
00003353: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
;; Print "Option Number    Slot     Name\n"
0000335b: a0 4f 8b 08 00 00                              PUSHW &0x88b
00003361: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
;; Print "------------------------------\n"
00003369: a0 4f ab 08 00 00                              PUSHW &0x8ab
0000336f: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00003377: 82 a9 b4 00                                    CLRH 0xb4(%fp)
0000337b: 70                                             NOP
0000337c: 24 7f 13 34 00 00                              JMP $0x3413
00003382: a0 4f d4 08 00 00                              PUSHW &0x8d4
00003388: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
0000338e: a0 40                                          PUSHW %r0
00003390: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003395: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
0000339b: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000339f: 9c 41 40                                       ADDW2 %r1,%r0
000033a2: 86 e2 c0 04 e0 40                              MOVH {uhalf}4(%r0),{uword}%r0
000033a8: a0 40                                          PUSHW %r0
000033aa: 2c cc f4 7f e4 44 00 00                        CALL -12(%sp),$0x44e4
000033b2: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000033b7: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
000033bd: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000033c1: 9c 41 40                                       ADDW2 %r1,%r0
000033c4: 9c 06 40                                       ADDW2 &0x6,%r0
000033c7: a0 40                                          PUSHW %r0
000033c9: a0 4f ea 08 00 00                              PUSHW &0x8ea
000033cf: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
000033d7: 28 40                                          TSTW %r0
000033d9: 7f 27                                          BEB &0x27 <0x3400>
000033db: a0 4f f1 08 00 00                              PUSHW &0x8f1
000033e1: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000033e6: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
000033ec: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000033f0: 9c 41 40                                       ADDW2 %r1,%r0
000033f3: 9c 06 40                                       ADDW2 &0x6,%r0
000033f6: a0 40                                          PUSHW %r0
000033f8: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00003400: a0 4f fb 08 00 00                              PUSHW &0x8fb
00003406: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
0000340e: 92 a9 b4 00                                    INCH 0xb4(%fp)
00003412: 70                                             NOP
00003413: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
00003419: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
0000341f: 3c 41 40                                       CMPW %r1,%r0
00003422: 5a 60 ff                                       BLUH &0xff60 <0x3382>
00003425: a0 4f 0c 30 04 00                              PUSHW &0x4300c
0000342b: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00003433: a0 40                                          PUSHW %r0
00003435: a0 01                                          PUSHW &0x1
00003437: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
0000343f: 83 a9 aa 00                                    CLRB 0xaa(%fp)
00003443: 70                                             NOP
00003444: 82 a9 b4 00                                    CLRH 0xb4(%fp)
00003448: 70                                             NOP
00003449: 24 7f d5 34 00 00                              JMP $0x34d5
0000344f: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003454: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
0000345a: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000345e: 9c 41 40                                       ADDW2 %r1,%r0
00003461: 86 e2 c0 02 e0 40                              MOVH {uhalf}2(%r0),{uword}%r0
00003467: 7f 34                                          BEB &0x34 <0x349b>
00003469: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00003471: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
00003475: 04 a9 b8 00 41                                 MOVAW 0xb8(%fp),%r1
0000347a: 86 a9 b4 00 e4 42                              MOVH 0xb4(%fp),{word}%r2
00003480: d0 04 42 42                                    LLSW3 &0x4,%r2,%r2
00003484: 9c 42 41                                       ADDW2 %r2,%r1
00003487: 86 e2 51 e0 41                                 MOVH {uhalf}(%r1),{uword}%r1
0000348c: 3c 41 40                                       CMPW %r1,%r0
0000348f: 77 0a                                          BNEB &0xa <0x3499>
00003491: 87 01 a9 aa 00                                 MOVB &0x1,0xaa(%fp)
00003496: 70                                             NOP
00003497: 7b 50                                          BRB &0x50 <0x34e7>
00003499: 7b 37                                          BRB &0x37 <0x34d0>
0000349b: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000034a0: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
000034a6: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000034aa: 9c 41 40                                       ADDW2 %r1,%r0
000034ad: 86 e2 c0 04 e0 40                              MOVH {uhalf}4(%r0),{uword}%r0
000034b3: dc 01 7f a0 04 00 00 41                        ADDW3 &0x1,$0x4a0,%r1
000034bb: 87 51 e0 41                                    MOVB (%r1),{uword}%r1
000034bf: d4 04 41 41                                    LRSW3 &0x4,%r1,%r1
000034c3: 3c 41 40                                       CMPW %r1,%r0
000034c6: 77 0a                                          BNEB &0xa <0x34d0>
000034c8: 87 01 a9 aa 00                                 MOVB &0x1,0xaa(%fp)
000034cd: 70                                             NOP
000034ce: 7b 19                                          BRB &0x19 <0x34e7>
000034d0: 92 a9 b4 00                                    INCH 0xb4(%fp)
000034d4: 70                                             NOP
000034d5: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
000034db: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
000034e1: 3c 41 40                                       CMPW %r1,%r0
000034e4: 5a 6b ff                                       BLUH &0xff6b <0x344f>
000034e7: 2b a9 aa 00                                    TSTB 0xaa(%fp)
000034eb: 77 09                                          BNEB &0x9 <0x34f4>
000034ed: 83 a9 af 00                                    CLRB 0xaf(%fp)
000034f1: 70                                             NOP
000034f2: 7b 0a                                          BRB &0xa <0x34fc>
000034f4: 87 a9 b5 00 a9 af 00                           MOVB 0xb5(%fp),0xaf(%fp)
000034fb: 70                                             NOP
000034fc: a0 4f fd 08 00 00                              PUSHW &0x8fd
00003502: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
0000350a: a0 4f 1f 09 00 00                              PUSHW &0x91f
00003510: 87 a9 af 00 e0 40                              MOVB 0xaf(%fp),{uword}%r0
00003516: a0 40                                          PUSHW %r0
00003518: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00003520: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003525: 87 a9 af 00 e0 41                              MOVB 0xaf(%fp),{uword}%r1
0000352b: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000352f: 9c 41 40                                       ADDW2 %r1,%r0
00003532: 9c 06 40                                       ADDW2 &0x6,%r0
00003535: a0 40                                          PUSHW %r0
00003537: a0 4f 23 09 00 00                              PUSHW &0x923
0000353d: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00003545: 28 40                                          TSTW %r0
00003547: 7f 27                                          BEB &0x27 <0x356e>
00003549: a0 4f 2a 09 00 00                              PUSHW &0x92a
0000354f: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003554: 87 a9 af 00 e0 41                              MOVB 0xaf(%fp),{uword}%r1
0000355a: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000355e: 9c 41 40                                       ADDW2 %r1,%r0
00003561: 9c 06 40                                       ADDW2 &0x6,%r0
00003564: a0 40                                          PUSHW %r0
00003566: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
0000356e: a0 4f 30 09 00 00                              PUSHW &0x930
00003574: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
0000357c: a0 00                                          PUSHW &0x0
0000357e: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
00003586: e0 c9 5a                                       PUSHAW 90(%fp)
00003589: 2c cc fc 7f 60 43 00 00                        CALL -4(%sp),$0x4360
00003591: 3c ff 40                                       CMPW &-1,%r0
00003594: 77 20                                          BNEB &0x20 <0x35b4>
00003596: a0 01                                          PUSHW &0x1
00003598: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
000035a0: a0 4f 34 09 00 00                              PUSHW &0x934
000035a6: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000035ae: 24 7f ab 3a 00 00                              JMP $0x3aab
000035b4: a0 01                                          PUSHW &0x1
000035b6: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
000035be: 83 a9 aa 00                                    CLRB 0xaa(%fp)
000035c2: 70                                             NOP
000035c3: 2b c9 5a                                       TSTB 90(%fp)
000035c6: 7f 5f                                          BEB &0x5f <0x3625>
000035c8: 82 a9 b4 00                                    CLRH 0xb4(%fp)
000035cc: 70                                             NOP
000035cd: 7b 23                                          BRB &0x23 <0x35f0>
000035cf: e0 c9 5a                                       PUSHAW 90(%fp)
000035d2: 2c cc fc af 68 05                              CALL -4(%sp),0x568(%pc)
000035d8: 86 a9 b4 00 e4 41                              MOVH 0xb4(%fp),{word}%r1
000035de: 3c 40 41                                       CMPW %r0,%r1
000035e1: 77 0a                                          BNEB &0xa <0x35eb>
000035e3: 87 01 a9 aa 00                                 MOVB &0x1,0xaa(%fp)
000035e8: 70                                             NOP
000035e9: 7b 18                                          BRB &0x18 <0x3601>
000035eb: 92 a9 b4 00                                    INCH 0xb4(%fp)
000035ef: 70                                             NOP
000035f0: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
000035f6: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
000035fc: 3c 41 40                                       CMPW %r1,%r0
000035ff: 5b d0                                          BLUB &0xd0 <0x35cf>
00003601: 2b a9 aa 00                                    TSTB 0xaa(%fp)
00003605: 77 16                                          BNEB &0x16 <0x361b>
00003607: a0 4f 36 09 00 00                              PUSHW &0x936
0000360d: e0 c9 5a                                       PUSHAW 90(%fp)
00003610: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00003618: 7a e4 fe                                       BRH &0xfee4 <0x34fc>
0000361b: 87 a9 b5 00 a9 ae 00                           MOVB 0xb5(%fp),0xae(%fp)
00003622: 70                                             NOP
00003623: 7b 0a                                          BRB &0xa <0x362d>
00003625: 87 a9 af 00 a9 ae 00                           MOVB 0xaf(%fp),0xae(%fp)
0000362c: 70                                             NOP
0000362d: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003632: 87 a9 ae 00 e0 41                              MOVB 0xae(%fp),{uword}%r1
00003638: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000363c: 9c 41 40                                       ADDW2 %r1,%r0
0000363f: 86 e2 c0 02 e0 40                              MOVH {uhalf}2(%r0),{uword}%r0
00003645: 7f 27                                          BEB &0x27 <0x366c>
00003647: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
0000364f: 04 a9 b8 00 41                                 MOVAW 0xb8(%fp),%r1
00003654: 87 a9 ae 00 e0 42                              MOVB 0xae(%fp),{uword}%r2
0000365a: d0 04 42 42                                    LLSW3 &0x4,%r2,%r2
0000365e: 9c 42 41                                       ADDW2 %r2,%r1
00003661: 87 c1 01 50                                    MOVB 1(%r1),(%r0)
00003665: 70                                             NOP
00003666: 24 7f 78 3a 00 00                              JMP $0x3a78
0000366c: 3f a9 af 00 a9 ae 00                           CMPB 0xaf(%fp),0xae(%fp)
00003673: 77 16                                          BNEB &0x16 <0x3689>
00003675: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
0000367d: fb 0f 50 40                                    ANDB3 &0xf,(%r0),%r0
00003681: 87 40 a9 ad 00                                 MOVB %r0,0xad(%fp)
00003686: 70                                             NOP
00003687: 7b 07                                          BRB &0x7 <0x368e>
00003689: 83 a9 ad 00                                    CLRB 0xad(%fp)
0000368d: 70                                             NOP
0000368e: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00003696: 04 a9 b8 00 41                                 MOVAW 0xb8(%fp),%r1
0000369b: 87 a9 ae 00 e0 42                              MOVB 0xae(%fp),{uword}%r2
000036a1: d0 04 42 42                                    LLSW3 &0x4,%r2,%r2
000036a5: 9c 42 41                                       ADDW2 %r2,%r1
000036a8: 86 e2 c1 04 e0 41                              MOVH {uhalf}4(%r1),{uword}%r1
000036ae: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000036b2: 87 41 50                                       MOVB %r1,(%r0)
000036b5: 70                                             NOP
000036b6: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000036bb: 87 a9 ae 00 e0 41                              MOVB 0xae(%fp),{uword}%r1
000036c1: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000036c5: 9c 41 40                                       ADDW2 %r1,%r0
000036c8: 86 50 a9 b4 00                                 MOVH (%r0),0xb4(%fp)
000036cd: 70                                             NOP
000036ce: 82 a9 b6 00                                    CLRH 0xb6(%fp)
000036d2: 70                                             NOP
000036d3: 7b 5e                                          BRB &0x5e <0x3731>
000036d5: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000036da: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
000036e0: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000036e4: 9c 41 40                                       ADDW2 %r1,%r0
000036e7: 82 50                                          CLRH (%r0)
000036e9: 70                                             NOP
000036ea: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000036ef: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
000036f5: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000036f9: 9c 41 40                                       ADDW2 %r1,%r0
000036fc: 82 c0 02                                       CLRH 2(%r0)
000036ff: 70                                             NOP
00003700: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003705: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
0000370b: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000370f: 9c 41 40                                       ADDW2 %r1,%r0
00003712: 82 c0 04                                       CLRH 4(%r0)
00003715: 70                                             NOP
00003716: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
0000371b: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
00003721: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003725: 9c 41 40                                       ADDW2 %r1,%r0
00003728: 83 c0 06                                       CLRB 6(%r0)
0000372b: 70                                             NOP
0000372c: 92 a9 b6 00                                    INCH 0xb6(%fp)
00003730: 70                                             NOP
00003731: 3e 10 a9 b6 00                                 CMPH &0x10,0xb6(%fp)
00003736: 4b 9f                                          BLB &0x9f <0x36d5>
00003738: 87 01 a9 ab 00                                 MOVB &0x1,0xab(%fp)
0000373d: 70                                             NOP
0000373e: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
00003744: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00003748: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
0000374f: cc 03 00 c0 04 40                              EXTFW &0x3,&0x0,4(%r0),%r0
00003755: 87 40 a9 ac 00                                 MOVB %r0,0xac(%fp)
0000375a: 70                                             NOP
0000375b: 2b a9 ac 00                                    TSTB 0xac(%fp)
0000375f: 77 0d                                          BNEB &0xd <0x376c>
00003761: 87 0f a9 ac 00                                 MOVB &0xf,0xac(%fp)
00003766: 70                                             NOP
00003767: 83 a9 ab 00                                    CLRB 0xab(%fp)
0000376b: 70                                             NOP
0000376c: 82 a9 b6 00                                    CLRH 0xb6(%fp)
00003770: 70                                             NOP
00003771: 7b 60                                          BRB &0x60 <0x37d1>
00003773: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003778: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
0000377e: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003782: 9c 41 40                                       ADDW2 %r1,%r0
00003785: 9c 06 40                                       ADDW2 &0x6,%r0
00003788: a0 40                                          PUSHW %r0
0000378a: 86 a9 b4 00 e4 40                              MOVH 0xb4(%fp),{word}%r0
00003790: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00003794: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
0000379b: ea 0c a9 b6 00 41                              MULH3 &0xc,0xb6(%fp),%r1
000037a1: dc 41 c0 08 40                                 ADDW3 %r1,8(%r0),%r0
000037a6: 9c 02 40                                       ADDW2 &0x2,%r0
000037a9: a0 40                                          PUSHW %r0
000037ab: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
000037b3: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000037b8: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
000037be: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000037c2: 9c 41 40                                       ADDW2 %r1,%r0
000037c5: 86 a9 b6 00 c0 04                              MOVH 0xb6(%fp),4(%r0)
000037cb: 70                                             NOP
000037cc: 92 a9 b6 00                                    INCH 0xb6(%fp)
000037d0: 70                                             NOP
000037d1: 86 a9 b6 00 e4 40                              MOVH 0xb6(%fp),{word}%r0
000037d7: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
000037dd: 3c 41 40                                       CMPW %r1,%r0
000037e0: 5b 93                                          BLUB &0x93 <0x3773>
000037e2: a0 4f 59 09 00 00                              PUSHW &0x959
000037e8: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000037f0: a0 4f 74 09 00 00                              PUSHW &0x974
000037f6: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000037fe: a0 4f 97 09 00 00                              PUSHW &0x997
00003804: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
0000380c: 82 a9 b6 00                                    CLRH 0xb6(%fp)
00003810: 70                                             NOP
00003811: 24 7f ae 38 00 00                              JMP $0x38ae
00003817: a0 4f c5 09 00 00                              PUSHW &0x9c5
0000381d: 86 a9 b6 00 e4 40                              MOVH 0xb6(%fp),{word}%r0
00003823: a0 40                                          PUSHW %r0
00003825: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
0000382a: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
00003830: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003834: 9c 41 40                                       ADDW2 %r1,%r0
00003837: 86 e2 c0 04 e0 40                              MOVH {uhalf}4(%r0),{uword}%r0
0000383d: a0 40                                          PUSHW %r0
0000383f: 2c cc f4 7f e4 44 00 00                        CALL -12(%sp),$0x44e4
00003847: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
0000384c: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
00003852: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003856: 9c 41 40                                       ADDW2 %r1,%r0
00003859: 9c 06 40                                       ADDW2 &0x6,%r0
0000385c: a0 40                                          PUSHW %r0
0000385e: a0 4f dc 09 00 00                              PUSHW &0x9dc
00003864: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
0000386c: 28 40                                          TSTW %r0
0000386e: 7f 2d                                          BEB &0x2d <0x389b>
00003870: 2b a9 ab 00                                    TSTB 0xab(%fp)
00003874: 7f 27                                          BEB &0x27 <0x389b>
00003876: a0 4f e3 09 00 00                              PUSHW &0x9e3
0000387c: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003881: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
00003887: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000388b: 9c 41 40                                       ADDW2 %r1,%r0
0000388e: 9c 06 40                                       ADDW2 &0x6,%r0
00003891: a0 40                                          PUSHW %r0
00003893: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
0000389b: a0 4f f1 09 00 00                              PUSHW &0x9f1
000038a1: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000038a9: 92 a9 b6 00                                    INCH 0xb6(%fp)
000038ad: 70                                             NOP
000038ae: 86 a9 b6 00 e4 40                              MOVH 0xb6(%fp),{word}%r0
000038b4: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
000038ba: 3c 41 40                                       CMPW %r1,%r0
000038bd: 5a 5a ff                                       BLUH &0xff5a <0x3817>
000038c0: 83 a9 aa 00                                    CLRB 0xaa(%fp)
000038c4: 70                                             NOP
000038c5: 82 a9 b6 00                                    CLRH 0xb6(%fp)
000038c9: 70                                             NOP
000038ca: 7b 32                                          BRB &0x32 <0x38fc>
000038cc: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
000038d1: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
000038d7: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
000038db: 9c 41 40                                       ADDW2 %r1,%r0
000038de: 86 e2 c0 04 e0 40                              MOVH {uhalf}4(%r0),{uword}%r0
000038e4: 87 a9 ad 00 e0 41                              MOVB 0xad(%fp),{uword}%r1
000038ea: 3c 41 40                                       CMPW %r1,%r0
000038ed: 77 0a                                          BNEB &0xa <0x38f7>
000038ef: 87 01 a9 aa 00                                 MOVB &0x1,0xaa(%fp)
000038f4: 70                                             NOP
000038f5: 7b 18                                          BRB &0x18 <0x390d>
000038f7: 92 a9 b6 00                                    INCH 0xb6(%fp)
000038fb: 70                                             NOP
000038fc: 86 a9 b6 00 e4 40                              MOVH 0xb6(%fp),{word}%r0
00003902: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00003908: 3c 41 40                                       CMPW %r1,%r0
0000390b: 5b c1                                          BLUB &0xc1 <0x38cc>
0000390d: 2b a9 aa 00                                    TSTB 0xaa(%fp)
00003911: 77 09                                          BNEB &0x9 <0x391a>
00003913: 83 a9 af 00                                    CLRB 0xaf(%fp)
00003917: 70                                             NOP
00003918: 7b 0a                                          BRB &0xa <0x3922>
0000391a: 87 a9 b7 00 a9 af 00                           MOVB 0xb7(%fp),0xaf(%fp)
00003921: 70                                             NOP
00003922: a0 4f f3 09 00 00                              PUSHW &0x9f3
00003928: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00003930: a0 4f 13 0a 00 00                              PUSHW &0xa13
00003936: 87 a9 af 00 e0 40                              MOVB 0xaf(%fp),{uword}%r0
0000393c: a0 40                                          PUSHW %r0
0000393e: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00003946: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
0000394b: 87 a9 af 00 e0 41                              MOVB 0xaf(%fp),{uword}%r1
00003951: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00003955: 9c 41 40                                       ADDW2 %r1,%r0
00003958: 9c 06 40                                       ADDW2 &0x6,%r0
0000395b: a0 40                                          PUSHW %r0
0000395d: a0 4f 17 0a 00 00                              PUSHW &0xa17
00003963: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
0000396b: 28 40                                          TSTW %r0
0000396d: 7f 2d                                          BEB &0x2d <0x399a>
0000396f: 2b a9 ab 00                                    TSTB 0xab(%fp)
00003973: 7f 27                                          BEB &0x27 <0x399a>
00003975: a0 4f 1e 0a 00 00                              PUSHW &0xa1e
0000397b: 04 a9 b8 00 40                                 MOVAW 0xb8(%fp),%r0
00003980: 87 a9 af 00 e0 41                              MOVB 0xaf(%fp),{uword}%r1
00003986: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
0000398a: 9c 41 40                                       ADDW2 %r1,%r0
0000398d: 9c 06 40                                       ADDW2 &0x6,%r0
00003990: a0 40                                          PUSHW %r0
00003992: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
0000399a: a0 4f 23 0a 00 00                              PUSHW &0xa23
000039a0: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000039a8: a0 00                                          PUSHW &0x0
000039aa: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
000039b2: e0 c9 5a                                       PUSHAW 90(%fp)
000039b5: 2c cc fc 7f 60 43 00 00                        CALL -4(%sp),$0x4360
000039bd: 3c ff 40                                       CMPW &-1,%r0
000039c0: 77 20                                          BNEB &0x20 <0x39e0>
000039c2: a0 01                                          PUSHW &0x1
000039c4: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
000039cc: a0 4f 27 0a 00 00                              PUSHW &0xa27
000039d2: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000039da: 24 7f ab 3a 00 00                              JMP $0x3aab
000039e0: a0 01                                          PUSHW &0x1
000039e2: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
000039ea: 83 a9 aa 00                                    CLRB 0xaa(%fp)
000039ee: 70                                             NOP
000039ef: 2b c9 5a                                       TSTB 90(%fp)
000039f2: 7f 5f                                          BEB &0x5f <0x3a51>
000039f4: 82 a9 b6 00                                    CLRH 0xb6(%fp)
000039f8: 70                                             NOP
000039f9: 7b 23                                          BRB &0x23 <0x3a1c>
000039fb: e0 c9 5a                                       PUSHAW 90(%fp)
000039fe: 2c cc fc af 3c 01                              CALL -4(%sp),0x13c(%pc)
00003a04: 86 a9 b6 00 e4 41                              MOVH 0xb6(%fp),{word}%r1
00003a0a: 3c 40 41                                       CMPW %r0,%r1
00003a0d: 77 0a                                          BNEB &0xa <0x3a17>
00003a0f: 87 01 a9 aa 00                                 MOVB &0x1,0xaa(%fp)
00003a14: 70                                             NOP
00003a15: 7b 18                                          BRB &0x18 <0x3a2d>
00003a17: 92 a9 b6 00                                    INCH 0xb6(%fp)
00003a1b: 70                                             NOP
00003a1c: 86 a9 b6 00 e4 40                              MOVH 0xb6(%fp),{word}%r0
00003a22: 87 a9 ac 00 e0 41                              MOVB 0xac(%fp),{uword}%r1
00003a28: 3c 41 40                                       CMPW %r1,%r0
00003a2b: 5b d0                                          BLUB &0xd0 <0x39fb>
00003a2d: 2b a9 aa 00                                    TSTB 0xaa(%fp)
00003a31: 77 16                                          BNEB &0x16 <0x3a47>
00003a33: a0 4f 29 0a 00 00                              PUSHW &0xa29
00003a39: e0 c9 5a                                       PUSHAW 90(%fp)
00003a3c: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00003a44: 7a de fe                                       BRH &0xfede <0x3922>
00003a47: 87 a9 b7 00 a9 ae 00                           MOVB 0xb7(%fp),0xae(%fp)
00003a4e: 70                                             NOP
00003a4f: 7b 0a                                          BRB &0xa <0x3a59>
00003a51: 87 a9 af 00 a9 ae 00                           MOVB 0xaf(%fp),0xae(%fp)
00003a58: 70                                             NOP
00003a59: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00003a61: 04 a9 b8 00 41                                 MOVAW 0xb8(%fp),%r1
00003a66: 87 a9 ae 00 e0 42                              MOVB 0xae(%fp),{uword}%r2
00003a6c: d0 04 42 42                                    LLSW3 &0x4,%r2,%r2
00003a70: 9c 42 41                                       ADDW2 %r2,%r1
00003a73: b3 c1 05 50                                    ORB2 5(%r1),(%r0)
00003a77: 70                                             NOP
00003a78: 87 01 ef a0 04 00 00                           MOVB &0x1,*$0x4a0
00003a7f: 70                                             NOP
00003a80: 2c 5c 7f 70 69 00 00                           CALL (%sp),$0x6970
00003a87: 28 40                                          TSTW %r0
00003a89: 77 1f                                          BNEB &0x1f <0x3aa8>
;; Sets the "Boot Failure" flag in 0x200085c
00003a8b: b0 04 7f 5c 08 00 02                           ORW2 &0x4,$0x200085c
00003a92: 70                                             NOP
00003a93: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
00003a9a: a0 4f ef be ed fe                              PUSHW &0xfeedbeef
00003aa0: 2c cc fc 7f 22 63 00 00                        CALL -4(%sp),$0x6322
00003aa8: 7a 65 f0                                       BRH &0xf065 <0x2b0d>
00003aab: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00003aaf: 20 49                                          POPW %fp
00003ab1: 08                                             RET
00003ab2: 70                                             NOP
00003ab3: 70                                             NOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine - maybe get input of some kind? It calls 0x4484,
;; which checks to see if a character is available as input.

00003ab4: 10 49                                          SAVE %fp
00003ab6: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00003abd: 82 59                                          CLRH (%fp)
00003abf: 70                                             NOP
00003ac0: 7b 37                                          BRB &0x37 <0x3af7>
00003ac2: 7b 02                                          BRB &0x2 <0x3ac4>
00003ac4: 2c 5c 7f 84 44 00 00                           CALL (%sp),$0x4484
00003acb: 87 40 da 00                                    MOVB %r0,*0(%ap)
00003acf: 70                                             NOP
00003ad0: 2b 40                                          TSTB %r0
00003ad2: 7f f2                                          BEB &0xf2 <0x3ac4>
00003ad4: 3f 0d da 00                                    CMPB &0xd,*0(%ap)
00003ad8: 7f 08                                          BEB &0x8 <0x3ae0>
00003ada: 3f 0a da 00                                    CMPB &0xa,*0(%ap)
00003ade: 77 13                                          BNEB &0x13 <0x3af1>
00003ae0: 2a 59                                          TSTH (%fp)
00003ae2: 77 06                                          BNEB &0x6 <0x3ae8>
00003ae4: 80 40                                          CLRW %r0
00003ae6: 7b 1f                                          BRB &0x1f <0x3b05>
00003ae8: 83 da 00                                       CLRB *0(%ap)
00003aeb: 70                                             NOP
00003aec: 84 01 40                                       MOVW &0x1,%r0
00003aef: 7b 16                                          BRB &0x16 <0x3b05>
00003af1: 90 5a                                          INCW (%ap)
00003af3: 70                                             NOP
00003af4: 92 59                                          INCH (%fp)
00003af6: 70                                             NOP
00003af7: 3e 08 59                                       CMPH &0x8,(%fp)
00003afa: 4b c8                                          BLB &0xc8 <0x3ac2>
00003afc: 83 da 00                                       CLRB *0(%ap)
00003aff: 70                                             NOP
00003b00: 84 01 40                                       MOVW &0x1,%r0
00003b03: 7b 02                                          BRB &0x2 <0x3b05>
00003b05: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00003b09: 20 49                                          POPW %fp
00003b0b: 08                                             RET
00003b0c: 70                                             NOP
00003b0d: 70                                             NOP


00003b0e: 10 49                                          SAVE %fp
00003b10: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00003b17: a0 4f 4c 0a 00 00                              PUSHW &0xa4c
00003b1d: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00003b25: a0 4f 1e ac eb ad                              PUSHW &0xadebac1e
00003b2b: 2c cc fc 7f 22 63 00 00                        CALL -4(%sp),$0x6322
00003b33: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00003b37: 20 49                                          POPW %fp
00003b39: 08                                             RET
00003b3a: 10 49                                          SAVE %fp
00003b3c: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
00003b43: 82 64                                          CLRH 4(%fp)
00003b45: 70                                             NOP
00003b46: 86 64 62                                       MOVH 4(%fp),2(%fp)
00003b49: 70                                             NOP
00003b4a: 7b 29                                          BRB &0x29 <0x3b73>
00003b4c: 3f 30 59                                       CMPB &0x30,(%fp)
00003b4f: 4b 14                                          BLB &0x14 <0x3b63>
00003b51: 3f 39 59                                       CMPB &0x39,(%fp)
00003b54: 47 0f                                          BGB &0xf <0x3b63>
00003b56: 87 59 e2 40                                    MOVB (%fp),{uhalf}%r0
00003b5a: be 30 40                                       SUBH2 &0x30,%r0
00003b5d: 86 40 64                                       MOVH %r0,4(%fp)
00003b60: 70                                             NOP
00003b61: 7b 07                                          BRB &0x7 <0x3b68>
00003b63: 84 ff 40                                       MOVW &-1,%r0
00003b66: 7b 21                                          BRB &0x21 <0x3b87>
00003b68: ea 0a 62 40                                    MULH3 &0xa,2(%fp),%r0
00003b6c: 9e 64 40                                       ADDH2 4(%fp),%r0
00003b6f: 86 40 62                                       MOVH %r0,2(%fp)
00003b72: 70                                             NOP
00003b73: 84 5a 40                                       MOVW (%ap),%r0
00003b76: 90 5a                                          INCW (%ap)
00003b78: 70                                             NOP
00003b79: 87 50 59                                       MOVB (%r0),(%fp)
00003b7c: 70                                             NOP
00003b7d: 2b 59                                          TSTB (%fp)
00003b7f: 77 cd                                          BNEB &0xcd <0x3b4c>
00003b81: 86 62 e4 40                                    MOVH 2(%fp),{word}%r0
00003b85: 7b 02                                          BRB &0x2 <0x3b87>
00003b87: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00003b8b: 20 49                                          POPW %fp
00003b8d: 08                                             RET
00003b8e: 70                                             NOP
00003b8f: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Procedure
;;

00003b90: 10 49                                          SAVE %fp
00003b92: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00003b99: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
00003ba1: 83 50                                          CLRB (%r0)
00003ba3: 70                                             NOP
00003ba4: a0 4f 09 30 04 00                              PUSHW &0x43009
00003baa: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00003bb2: a0 40                                          PUSHW %r0
00003bb4: a0 01                                          PUSHW &0x1
;; Call 'rnvram'
00003bb6: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00003bbe: 3c 01 40                                       CMPW &0x1,%r0
00003bc1: 77 51                                          BNEB &0x51 <0x3c12>
00003bc3: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00003bcb: dc 03 7f a4 04 00 00 41                        ADDW3 &0x3,$0x4a4,%r1
00003bd3: fb 5f f0 00 51 41                              ANDB3 &0xf0,(%r1),%r1
00003bd9: d4 04 41 41                                    LRSW3 &0x4,%r1,%r1
00003bdd: 87 41 50                                       MOVB %r1,(%r0)
00003be0: 70                                             NOP
00003be1: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00003be9: bb 0f 50                                       ANDB2 &0xf,(%r0)
00003bec: 70                                             NOP
00003bed: 3c 4f 00 80 00 00 7f 08 05 00 00               CMPW &0x8000,$0x508
00003bf8: 4f 18                                          BLEB &0x18 <0x3c10>
00003bfa: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00003c02: 83 50                                          CLRB (%r0)
00003c04: 70                                             NOP
00003c05: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00003c0d: 83 50                                          CLRB (%r0)
00003c0f: 70                                             NOP
00003c10: 7b 18                                          BRB &0x18 <0x3c28>
00003c12: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00003c1a: 83 50                                          CLRB (%r0)
00003c1c: 70                                             NOP
00003c1d: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00003c25: 83 50                                          CLRB (%r0)
00003c27: 70                                             NOP
00003c28: a0 4f 80 30 04 00                              PUSHW &0x43080
00003c2e: e0 59                                          PUSHAW (%fp)
00003c30: a0 02                                          PUSHW &0x2
00003c32: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00003c3a: 28 40                                          TSTW %r0
00003c3c: 7f 09                                          BEB &0x9 <0x3c45>
00003c3e: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003c43: 77 1a                                          BNEB &0x1a <0x3c5d>
00003c45: 86 5f bd 04 59                                 MOVH &0x4bd,(%fp)
00003c4a: 70                                             NOP
00003c4b: e0 59                                          PUSHAW (%fp)
00003c4d: a0 4f 80 30 04 00                              PUSHW &0x43080
00003c53: a0 02                                          PUSHW &0x2
00003c55: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00003c5d: 86 59 ef a4 04 00 00                           MOVH (%fp),*$0x4a4
00003c64: 70                                             NOP
00003c65: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00003c6d: 2b 50                                          TSTB (%r0)
00003c6f: 7f 08                                          BEB &0x8 <0x3c77>
00003c71: 86 5f bd 04 59                                 MOVH &0x4bd,(%fp)
00003c76: 70                                             NOP
00003c77: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003c7c: a0 40                                          PUSHW %r0
00003c7e: a0 4f 00 90 04 00                              PUSHW &0x49000
00003c84: 2c cc f8 7f 84 3e 00 00                        CALL -8(%sp),$0x3e84
00003c8c: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00003c94: 2b 50                                          TSTB (%r0)
00003c96: 77 19                                          BNEB &0x19 <0x3caf>
00003c98: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00003ca0: 3f 01 50                                       CMPB &0x1,(%r0)
00003ca3: 77 0c                                          BNEB &0xc <0x3caf>
00003ca5: 86 ef a4 04 00 00 59                           MOVH *$0x4a4,(%fp)
00003cac: 70                                             NOP
00003cad: 7b 35                                          BRB &0x35 <0x3ce2>
00003caf: a0 4f 0a 30 04 00                              PUSHW &0x4300a
00003cb5: e0 59                                          PUSHAW (%fp)
00003cb7: a0 02                                          PUSHW &0x2
00003cb9: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00003cc1: 28 40                                          TSTW %r0
00003cc3: 7f 09                                          BEB &0x9 <0x3ccc>
00003cc5: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003cca: 77 18                                          BNEB &0x18 <0x3ce2>
00003ccc: 86 3d 59                                       MOVH &0x3d,(%fp)
00003ccf: 70                                             NOP
00003cd0: e0 59                                          PUSHAW (%fp)
00003cd2: a0 4f 0a 30 04 00                              PUSHW &0x4300a
00003cd8: a0 02                                          PUSHW &0x2
00003cda: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00003ce2: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003ce7: a0 40                                          PUSHW %r0
00003ce9: a0 4f 08 90 04 00                              PUSHW &0x49008
00003cef: 2c cc f8 7f 84 3e 00 00                        CALL -8(%sp),$0x3e84
00003cf7: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00003cff: 2b 50                                          TSTB (%r0)
00003d01: 77 6b                                          BNEB &0x6b <0x3d6c>
00003d03: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00003d0b: 2b 50                                          TSTB (%r0)
00003d0d: 77 0e                                          BNEB &0xe <0x3d1b>
00003d0f: 8b 7f 0d 90 04 00 40                           MCOMB $0x4900d,%r0
00003d16: 38 40 01                                       BITW %r0,&0x1
00003d19: 77 1b                                          BNEB &0x1b <0x3d34>
00003d1b: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00003d23: 3f 01 50                                       CMPB &0x1,(%r0)
00003d26: 77 46                                          BNEB &0x46 <0x3d6c>
00003d28: 8b 7f 0d 90 04 00 40                           MCOMB $0x4900d,%r0
00003d2f: 38 40 02                                       BITW %r0,&0x2
00003d32: 7f 3a                                          BEB &0x3a <0x3d6c>
00003d34: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
00003d3c: 87 01 50                                       MOVB &0x1,(%r0)
00003d3f: 70                                             NOP
00003d40: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00003d48: 2b 50                                          TSTB (%r0)
00003d4a: 7f 13                                          BEB &0x13 <0x3d5d>
00003d4c: 84 4f 08 90 04 00 40                           MOVW &0x49008,%r0
00003d53: 84 40 ef fc 04 00 00                           MOVW %r0,*$0x4fc
00003d5a: 70                                             NOP
00003d5b: 7b 11                                          BRB &0x11 <0x3d6c>
00003d5d: 84 4f 00 90 04 00 40                           MOVW &0x49000,%r0
00003d64: 84 40 ef fc 04 00 00                           MOVW %r0,*$0x4fc
00003d6b: 70                                             NOP
00003d6c: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00003d70: 20 49                                          POPW %fp
00003d72: 08                                             RET
00003d73: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'setbaud' - Routine to set baud rate. This is a full process,
;; ending with a "RETPS". It makes me wonder if this is a full-on
;; exception handler? If so, who calls it? It doesn't appear in any
;; interrupt vector tables.

00003d74: 10 48                                          SAVE %r8
00003d76: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00003d7d: 86 01 48                                       MOVH &0x1,%r8
00003d80: 7b 23                                          BRB &0x23 <0x3da3>
00003d82: 3e 10 48                                       CMPH &0x10,%r8
00003d85: 5b 1c                                          BLUB &0x1c <0x3da1>
00003d87: a0 4f d8 0a 00 00                              PUSHW &0xad8
00003d8d: 86 72 e4 40                                    MOVH 2(%ap),{word}%r0
00003d91: a0 40                                          PUSHW %r0
00003d93: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00003d9b: 24 7f 7a 3e 00 00                              JMP $0x3e7a
00003da1: 92 48                                          INCH %r8
00003da3: 86 48 e4 40                                    MOVH %r8,{word}%r0
00003da7: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00003dab: 3e 72 80 58 0a 00 00                           CMPH 2(%ap),0xa58(%r0)
00003db2: 77 d0                                          BNEB &0xd0 <0x3d82>
00003db4: 3c 4f 08 90 04 00 74                           CMPW &0x49008,4(%ap)
00003dbb: 77 31                                          BNEB &0x31 <0x3dec>
00003dbd: 86 48 e4 40                                    MOVH %r8,{word}%r0
00003dc1: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00003dc5: 87 80 5a 0a 00 00 e2 40                        MOVB 0xa5a(%r0),{uhalf}%r0
00003dcd: b2 30 40                                       ORH2 &0x30,%r0
00003dd0: 86 40 59                                       MOVH %r0,(%fp)
00003dd3: 70                                             NOP
00003dd4: e0 59                                          PUSHAW (%fp)
00003dd6: a0 4f 0a 30 04 00                              PUSHW &0x4300a
00003ddc: a0 02                                          PUSHW &0x2
00003dde: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00003de6: 24 7f 6b 3e 00 00                              JMP $0x3e6b
00003dec: a0 4f 80 30 04 00                              PUSHW &0x43080
00003df2: e0 59                                          PUSHAW (%fp)
00003df4: a0 02                                          PUSHW &0x2
00003df6: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00003dfe: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003e03: 7f 38                                          BEB &0x38 <0x3e3b>
00003e05: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003e0a: 84 4f f0 ff 00 00 41                           MOVW &0xfff0,%r1
00003e11: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00003e16: b8 41 40                                       ANDW2 %r1,%r0
00003e19: 86 40 59                                       MOVH %r0,(%fp)
00003e1c: 70                                             NOP
00003e1d: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003e22: 86 48 e4 41                                    MOVH %r8,{word}%r1
00003e26: d0 03 41 41                                    LLSW3 &0x3,%r1,%r1
00003e2a: 87 81 5a 0a 00 00 e0 41                        MOVB 0xa5a(%r1),{uword}%r1
00003e32: b0 41 40                                       ORW2 %r1,%r0
00003e35: 86 40 59                                       MOVH %r0,(%fp)
00003e38: 70                                             NOP
00003e39: 7b 20                                          BRB &0x20 <0x3e59>
00003e3b: 86 48 e4 40                                    MOVH %r8,{word}%r0
00003e3f: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00003e43: 87 80 5a 0a 00 00 e2 40                        MOVB 0xa5a(%r0),{uhalf}%r0
00003e4b: b2 5f 30 04 40                                 ORH2 &0x430,%r0
00003e50: b2 5f 80 00 40                                 ORH2 &0x80,%r0
00003e55: 86 40 59                                       MOVH %r0,(%fp)
00003e58: 70                                             NOP
00003e59: e0 59                                          PUSHAW (%fp)
00003e5b: a0 4f 80 30 04 00                              PUSHW &0x43080
00003e61: a0 02                                          PUSHW &0x2
00003e63: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00003e6b: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003e70: a0 40                                          PUSHW %r0
00003e72: a0 74                                          PUSHW 4(%ap)
00003e74: 2c cc f8 af 10 00                              CALL -8(%sp),0x10(%pc)
00003e7a: 04 c9 ec 4c                                    MOVAW -20(%fp),%sp
00003e7e: 20 48                                          POPW %r8
00003e80: 20 49                                          POPW %fp
00003e82: 08                                             RET
00003e83: 70                                             NOP
00003e84: 10 47                                          SAVE %r7
00003e86: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00003e8d: 86 01 48                                       MOVH &0x1,%r8
00003e90: 7b 17                                          BRB &0x17 <0x3ea7>
00003e92: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00003e97: 3c 10 40                                       CMPW &0x10,%r0
00003e9a: 5b 0b                                          BLUB &0xb <0x3ea5>
00003e9c: 86 0d 48                                       MOVH &0xd,%r8
00003e9f: 86 30 72                                       MOVH &0x30,2(%ap)
00003ea2: 70                                             NOP
00003ea3: 7b 22                                          BRB &0x22 <0x3ec5>
00003ea5: 92 48                                          INCH %r8
00003ea7: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00003eac: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00003eb0: 87 80 5a 0a 00 00 e0 40                        MOVB 0xa5a(%r0),{uword}%r0
00003eb8: 86 e2 72 e0 41                                 MOVH {uhalf}2(%ap),{uword}%r1
00003ebd: b8 0f 41                                       ANDW2 &0xf,%r1
00003ec0: 3c 41 40                                       CMPW %r1,%r0
00003ec3: 77 cf                                          BNEB &0xcf <0x3e92>
00003ec5: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
00003ec9: 87 1a 50                                       MOVB &0x1a,(%r0)
00003ecc: 70                                             NOP
00003ecd: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
00003ed1: 87 20 50                                       MOVB &0x20,(%r0)
00003ed4: 70                                             NOP
00003ed5: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
00003ed9: 87 30 50                                       MOVB &0x30,(%r0)
00003edc: 70                                             NOP
00003edd: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
00003ee1: 87 6f 40 50                                    MOVB &0x40,(%r0)
00003ee5: 70                                             NOP
00003ee6: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
00003eea: 87 6f 70 50                                    MOVB &0x70,(%r0)
00003eee: 70                                             NOP
00003eef: 86 e2 72 e0 40                                 MOVH {uhalf}2(%ap),{uword}%r0
00003ef4: 38 40 5f 00 01                                 BITW %r0,&0x100
00003ef9: 7f 1a                                          BEB &0x1a <0x3f13>
00003efb: 86 e2 72 e0 40                                 MOVH {uhalf}2(%ap),{uword}%r0
00003f00: 38 40 5f 00 02                                 BITW %r0,&0x200
00003f05: 7f 07                                          BEB &0x7 <0x3f0c>
00003f07: 84 04 40                                       MOVW &0x4,%r0
00003f0a: 7b 04                                          BRB &0x4 <0x3f0e>
00003f0c: 80 40                                          CLRW %r0
00003f0e: b0 00 40                                       ORW2 &0x0,%r0
00003f11: 7b 05                                          BRB &0x5 <0x3f16>
00003f13: 84 10 40                                       MOVW &0x10,%r0
00003f16: b3 00 40                                       ORB2 &0x0,%r0
00003f19: 87 40 47                                       MOVB %r0,%r7
00003f1c: 86 e2 72 e0 40                                 MOVH {uhalf}2(%ap),{uword}%r0
00003f21: b8 30 40                                       ANDW2 &0x30,%r0
00003f24: 7b 13                                          BRB &0x13 <0x3f37>
00003f26: 7b 22                                          BRB &0x22 <0x3f48>
00003f28: b3 01 47                                       ORB2 &0x1,%r7
00003f2b: 7b 1d                                          BRB &0x1d <0x3f48>
00003f2d: b3 02 47                                       ORB2 &0x2,%r7
00003f30: 7b 18                                          BRB &0x18 <0x3f48>
00003f32: b3 03 47                                       ORB2 &0x3,%r7
00003f35: 7b 13                                          BRB &0x13 <0x3f48>
00003f37: 3c 40 00                                       CMPW %r0,&0x0
00003f3a: 7f ec                                          BEB &0xec <0x3f26>
00003f3c: 3c 40 10                                       CMPW %r0,&0x10
00003f3f: 7f e9                                          BEB &0xe9 <0x3f28>
00003f41: 3c 40 20                                       CMPW %r0,&0x20
00003f44: 7f e9                                          BEB &0xe9 <0x3f2d>
00003f46: 7b ec                                          BRB &0xec <0x3f32>
00003f48: 87 47 da 04                                    MOVB %r7,*4(%ap)
00003f4c: 70                                             NOP
00003f4d: 86 e2 72 e0 40                                 MOVH {uhalf}2(%ap),{uword}%r0
00003f52: 38 40 6f 40                                    BITW %r0,&0x40
00003f56: 7f 07                                          BEB &0x7 <0x3f5d>
00003f58: 84 0f 40                                       MOVW &0xf,%r0
00003f5b: 7b 05                                          BRB &0x5 <0x3f60>
00003f5d: 84 07 40                                       MOVW &0x7,%r0
00003f60: b3 00 40                                       ORB2 &0x0,%r0
00003f63: 87 40 da 04                                    MOVB %r0,*4(%ap)
00003f67: 70                                             NOP
00003f68: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
00003f6c: 86 e2 48 e0 41                                 MOVH {uhalf}%r8,{uword}%r1
00003f71: d0 03 41 41                                    LLSW3 &0x3,%r1,%r1
00003f75: 87 81 5b 0a 00 00 50                           MOVB 0xa5b(%r1),(%r0)
00003f7c: 70                                             NOP
00003f7d: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00003f82: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00003f86: 87 80 5c 0a 00 00 7f 54 12 00 02               MOVB 0xa5c(%r0),$0x2001254
00003f91: 70                                             NOP
00003f92: dc 04 74 40                                    ADDW3 &0x4,4(%ap),%r0
00003f96: 87 7f 54 12 00 02 50                           MOVB $0x2001254,(%r0)
00003f9d: 70                                             NOP
00003f9e: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
00003fa2: 87 15 50                                       MOVB &0x15,(%r0)
00003fa5: 70                                             NOP
00003fa6: 87 03 7f 0e 90 04 00                           MOVB &0x3,$0x4900e
00003fad: 70                                             NOP
00003fae: a0 01                                          PUSHW &0x1
00003fb0: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00003fb8: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
00003fbc: 87 20 50                                       MOVB &0x20,(%r0)
00003fbf: 70                                             NOP
00003fc0: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00003fc4: 20 48                                          POPW %r8
00003fc6: 20 47                                          POPW %r7
00003fc8: 20 49                                          POPW %fp
00003fca: 08                                             RET
00003fcb: 70                                             NOP
00003fcc: 10 49                                          SAVE %fp
00003fce: 9c 4f 54 00 00 00 4c                           ADDW2 &0x54,%sp
00003fd5: a0 4f 80 30 04 00                              PUSHW &0x43080
00003fdb: e0 59                                          PUSHAW (%fp)
00003fdd: a0 02                                          PUSHW &0x2
00003fdf: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00003fe7: a0 4f f3 0a 00 00                              PUSHW &0xaf3
00003fed: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00003ff2: b8 0f 40                                       ANDW2 &0xf,%r0
00003ff5: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00003ff9: 86 80 58 0a 00 00 e4 40                        MOVH 0xa58(%r0),{word}%r0
00004001: a0 40                                          PUSHW %r0
00004003: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
0000400b: e0 62                                          PUSHAW 2(%fp)
0000400d: 2c cc fc ef b4 04 00 00                        CALL -4(%sp),*$0x4b4
00004015: 2b 62                                          TSTB 2(%fp)
00004017: 7f 3c                                          BEB &0x3c <0x4053>
00004019: e0 62                                          PUSHAW 2(%fp)
0000401b: a0 4f 09 0b 00 00                              PUSHW &0xb09
00004021: e0 59                                          PUSHAW (%fp)
00004023: 2c cc f4 7f e4 4a 00 00                        CALL -12(%sp),$0x4ae4
0000402b: a0 4f 0c 0b 00 00                              PUSHW &0xb0c
00004031: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00004036: a0 40                                          PUSHW %r0
00004038: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00004040: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00004045: a0 40                                          PUSHW %r0
00004047: a0 4f 00 90 04 00                              PUSHW &0x49000
0000404d: 2c cc f8 af 27 fd                              CALL -8(%sp),0x..fd27(%pc)
00004053: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00004057: 20 49                                          POPW %fp
00004059: 08                                             RET
0000405a: 70                                             NOP
0000405b: 70                                             NOP
0000405c: 10 49                                          SAVE %fp
0000405e: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00004065: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00004069: 20 49                                          POPW %fp
0000406b: 08                                             RET
0000406c: 10 49                                          SAVE %fp
0000406e: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00004075: 87 7f 13 20 04 00 59                           MOVB $0x42013,(%fp)
0000407c: 70                                             NOP
0000407d: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00004081: 20 49                                          POPW %fp
00004083: 08                                             RET
00004084: 28 5d                                          TSTW (%pcbp)
00004086: 70                                             NOP
00004087: 70                                             NOP
00004088: 70                                             NOP
00004089: 70                                             NOP
0000408a: 10 49                                          SAVE %fp
0000408c: 84 5a 42                                       MOVW (%ap),%r2
0000408f: 84 74 41                                       MOVW 4(%ap),%r1
00004092: 84 78 40                                       MOVW 8(%ap),%r0
00004095: 30 19                                          MOVBLW
00004097: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
0000409b: 20 49                                          POPW %fp
0000409d: 08                                             RET
0000409e: 70                                             NOP
0000409f: 70                                             NOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main interrupt handler during ROM startup. This is pointed at by
;; the PCBP at 0x2000bc8 during at least part of ROM startup.
;;
;; The clever part of this is the call to 0x64ec, which will then call
;; whatever function is currently registered at 0x494.
;;
000040a0: 84 ce fc 40                                    MOVW -4(%isp),%r0
000040a4: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
000040ab: 70                                             NOP
000040ac: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
000040b4: 70                                             NOP
000040b5: 87 00 7f 60 12 00 02                           MOVB &0x0,$0x2001260
000040bc: 70                                             NOP
;; Call the code that calls the registered handler
000040bd: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
000040c4: 30 c8                                          RETPS


;; Interrupt handler 40c6
000040c6: 84 ce fc 40                                    MOVW -4(%isp),%r0
000040ca: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
000040d1: 70                                             NOP
000040d2: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
000040da: 70                                             NOP
000040db: 87 08 7f 60 12 00 02                           MOVB &0x8,$0x2001260
000040e2: 70                                             NOP
000040e3: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
000040ea: 30 c8                                          RETPS

;; Interrupt handler 40ec
000040ec: 84 ce fc 40                                    MOVW -4(%isp),%r0
000040f0: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
000040f7: 70                                             NOP
000040f8: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
00004100: 70                                             NOP
00004101: 87 09 7f 60 12 00 02                           MOVB &0x9,$0x2001260
00004108: 70                                             NOP
00004109: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
00004110: 30 c8                                          RETPS

;;
00004112: 84 ce fc 40                                    MOVW -4(%isp),%r0
00004116: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
0000411d: 70                                             NOP
0000411e: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
00004126: 70                                             NOP
00004127: 87 0a 7f 60 12 00 02                           MOVB &0xa,$0x2001260
0000412e: 70                                             NOP
0000412f: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
00004136: 30 c8                                          RETPS

00004138: 84 ce fc 40                                    MOVW -4(%isp),%r0
0000413c: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
00004143: 70                                             NOP
00004144: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
0000414c: 70                                             NOP
0000414d: 87 0b 7f 60 12 00 02                           MOVB &0xb,$0x2001260
00004154: 70                                             NOP
00004155: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
0000415c: 30 c8                                          RETPS

0000415e: 84 ce fc 40                                    MOVW -4(%isp),%r0
00004162: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
00004169: 70                                             NOP
0000416a: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
00004172: 70                                             NOP
00004173: 87 0c 7f 60 12 00 02                           MOVB &0xc,$0x2001260
0000417a: 70                                             NOP
0000417b: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
00004182: 30 c8                                          RETPS

00004184: 84 ce fc 40                                    MOVW -4(%isp),%r0
00004188: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
0000418f: 70                                             NOP
00004190: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
00004198: 70                                             NOP
00004199: 87 0d 7f 60 12 00 02                           MOVB &0xd,$0x2001260
000041a0: 70                                             NOP
000041a1: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
000041a8: 30 c8                                          RETPS
000041aa: 84 ce fc 40                                    MOVW -4(%isp),%r0
000041ae: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
000041b5: 70                                             NOP
000041b6: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
000041be: 70                                             NOP
000041bf: 87 0e 7f 60 12 00 02                           MOVB &0xe,$0x2001260
000041c6: 70                                             NOP
000041c7: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
000041ce: 30 c8                                          RETPS
000041d0: 84 ce fc 40                                    MOVW -4(%isp),%r0
000041d4: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
000041db: 70                                             NOP
000041dc: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
000041e4: 70                                             NOP
000041e5: 87 0f 7f 60 12 00 02                           MOVB &0xf,$0x2001260
000041ec: 70                                             NOP
000041ed: 2c 5c 7f ec 64 00 00                           CALL (%sp),$0x64ec
000041f4: 30 c8                                          RETPS
000041f6: 70                                             NOP
000041f7: 70                                             NOP
000041f8: 84 ce fc 40                                    MOVW -4(%isp),%r0
000041fc: 84 50 7f 58 12 00 02                           MOVW (%r0),$0x2001258
00004203: 70                                             NOP
00004204: 84 c0 04 7f 5c 12 00 02                        MOVW 4(%r0),$0x200125c
0000420c: 70                                             NOP
0000420d: 84 c0 1c 7f 64 12 00 02                        MOVW 28(%r0),$0x2001264
00004215: 70                                             NOP
00004216: 2c 5c 7f 50 65 00 00                           CALL (%sp),$0x6550
0000421d: 30 c8                                          RETPS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'demon' - Routine to enter demon without init
;;
;; This appears to be an interrupt handler, but what?
;; It calls 0x6550, which is currently an unknown procedure.

0000421f: 84 cc fc 7f 58 12 00 02                        MOVW -4(%sp),$0x2001258
00004227: 70                                             NOP
00004228: 84 cc f8 7f 5c 12 00 02                        MOVW -8(%sp),$0x200125c
00004230: 70                                             NOP
00004231: 84 40 7f 64 12 00 02                           MOVW %r0,$0x2001264
00004238: 70                                             NOP
;; Load the PSW with 81E100
00004239: 84 4f 00 e1 81 00 4b                           MOVW &0x81e100,%psw
;; Call unknown procedure at 0x6550
00004240: 2c 5c 7f 50 65 00 00                           CALL (%sp),$0x6550
00004247: 84 7f fc 11 00 02 cc f8                        MOVW $0x20011fc,-8(%sp)
0000424f: 70                                             NOP
00004250: 84 7f 58 12 00 02 4b                           MOVW $0x2001258,%psw
00004257: 30 45                                          RETG

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Interrupt Handler
;;

00004259: 84 40 7f 64 12 00 02                           MOVW %r0,$0x2001264
00004260: 70                                             NOP
00004261: 84 cc fc 7f 58 12 00 02                        MOVW -4(%sp),$0x2001258
00004269: 70                                             NOP
0000426a: 84 cc f8 7f 5c 12 00 02                        MOVW -8(%sp),$0x200125c
00004272: 70                                             NOP
00004273: 04 7f 98 0e 00 02 40                           MOVAW $0x2000e98,%r0
0000427a: 30 ac                                          CALLPS
0000427c: 84 7f fc 11 00 02 cc f8                        MOVW $0x20011fc,-8(%sp)
00004284: 70                                             NOP
00004285: 84 7f 58 12 00 02 4b                           MOVW $0x2001258,%psw
0000428c: 30 45                                          RETG


0000428e: 84 4f 00 e1 81 00 4b                           MOVW &0x81e100,%psw
00004295: 2c 5c 7f 50 65 00 00                           CALL (%sp),$0x6550
0000429c: 30 c8                                          RETPS
0000429e: 70                                             NOP
0000429f: 70                                             NOP
000042a0: 10 49                                          SAVE %fp
000042a2: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
000042a9: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
000042b1: 2b 50                                          TSTB (%r0)
000042b3: 7f 15                                          BEB &0x15 <0x42c8>
000042b5: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
000042bd: 3f 01 50                                       CMPB &0x1,(%r0)
000042c0: 77 08                                          BNEB &0x8 <0x42c8>
000042c2: 24 7f 48 43 00 00                              JMP $0x4348
000042c8: 7b 09                                          BRB &0x9 <0x42d1>
000042ca: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
000042d1: dc 01 5a 40                                    ADDW3 &0x1,(%ap),%r0
000042d5: 3b 50 01                                       BITB (%r0),&0x1
000042d8: 7f f2                                          BEB &0xf2 <0x42ca>
000042da: 3c 7f e8 11 00 02 5a                           CMPW $0x20011e8,(%ap)
000042e1: 77 59                                          BNEB &0x59 <0x433a>
000042e3: 2b 7f 68 08 00 02                              TSTB $0x2000868
000042e9: 77 51                                          BNEB &0x51 <0x433a>
000042eb: dc 01 5a 40                                    ADDW3 &0x1,(%ap),%r0
000042ef: 3b 50 5f 80 00                                 BITB (%r0),&0x80
000042f4: 7f 46                                          BEB &0x46 <0x433a>
000042f6: dc 02 5a 40                                    ADDW3 &0x2,(%ap),%r0
000042fa: 87 6f 40 50                                    MOVB &0x40,(%r0)
000042fe: 70                                             NOP
000042ff: dc 02 5a 40                                    ADDW3 &0x2,(%ap),%r0
00004303: 87 6f 50 50                                    MOVB &0x50,(%r0)
00004307: 70                                             NOP
00004308: dc 03 5a 40                                    ADDW3 &0x3,(%ap),%r0
0000430c: 87 50 59                                       MOVB (%r0),(%fp)
0000430f: 70                                             NOP
00004310: 7b 1c                                          BRB &0x1c <0x432c>
00004312: dc 02 5a 40                                    ADDW3 &0x2,(%ap),%r0
00004316: 87 6f 40 50                                    MOVB &0x40,(%r0)
0000431a: 70                                             NOP
0000431b: dc 02 5a 40                                    ADDW3 &0x2,(%ap),%r0
0000431f: 87 6f 50 50                                    MOVB &0x50,(%r0)
00004323: 70                                             NOP
00004324: dc 03 5a 40                                    ADDW3 &0x3,(%ap),%r0
00004328: 87 50 59                                       MOVB (%r0),(%fp)
0000432b: 70                                             NOP
0000432c: dc 01 5a 40                                    ADDW3 &0x1,(%ap),%r0
00004330: 3b 50 01                                       BITB (%r0),&0x1
00004333: 77 df                                          BNEB &0xdf <0x4312>
00004335: 84 ff 40                                       MOVW &-1,%r0
00004338: 7b 20                                          BRB &0x20 <0x4358>
0000433a: dc 03 5a 40                                    ADDW3 &0x3,(%ap),%r0
0000433e: 87 50 59                                       MOVB (%r0),(%fp)
00004341: 70                                             NOP
00004342: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004346: 7b 12                                          BRB &0x12 <0x4358>
00004348: a0 00                                          PUSHW &0x0
0000434a: 2c cc fc 7f f8 56 00 00                        CALL -4(%sp),$0x56f8
00004352: 86 40 e4 40                                    MOVH %r0,{word}%r0
00004356: 7b 02                                          BRB &0x2 <0x4358>
00004358: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
0000435c: 20 49                                          POPW %fp
0000435e: 08                                             RET
0000435f: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'gets' Routine
;;

00004360: 10 47                                          SAVE %r7
00004362: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00004369: 2b ef c4 04 00 00                              TSTB *$0x4c4
0000436f: 77 11                                          BNEB &0x11 <0x4380>
00004371: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00004378: 80 40                                          CLRW %r0
0000437a: 24 7f 78 44 00 00                              JMP $0x4478
00004380: 84 5a 48                                       MOVW (%ap),%r8
00004383: 24 7f 55 44 00 00                              JMP $0x4455
00004389: a0 7f e8 11 00 02                              PUSHW $0x20011e8
0000438f: 2c cc fc 7f a0 42 00 00                        CALL -4(%sp),$0x42a0
00004397: 84 40 47                                       MOVW %r0,%r7
0000439a: 43 0b                                          BGEB &0xb <0x43a5>
0000439c: 84 ff 40                                       MOVW &-1,%r0
0000439f: 24 7f 78 44 00 00                              JMP $0x4478
000043a5: f8 5f ff 00 47 e3 40                           ANDW3 &0xff,%r7,{ubyte}%r0
000043ac: 87 40 da 00                                    MOVB %r0,*0(%ap)
000043b0: 70                                             NOP
000043b1: 3f 0a da 00                                    CMPB &0xa,*0(%ap)
000043b5: 7f 08                                          BEB &0x8 <0x43bd>
000043b7: 3f 0d da 00                                    CMPB &0xd,*0(%ap)
000043bb: 77 2c                                          BNEB &0x2c <0x43e7>
000043bd: 83 da 00                                       CLRB *0(%ap)
000043c0: 70                                             NOP
000043c1: a0 0a                                          PUSHW &0xa
000043c3: a0 7f e8 11 00 02                              PUSHW $0x20011e8
000043c9: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
000043d1: 28 40                                          TSTW %r0
000043d3: 43 0b                                          BGEB &0xb <0x43de>
000043d5: 84 ff 40                                       MOVW &-1,%r0
000043d8: 24 7f 78 44 00 00                              JMP $0x4478
000043de: 84 01 40                                       MOVW &0x1,%r0
000043e1: 24 7f 78 44 00 00                              JMP $0x4478
000043e7: 87 da 00 e0 40                                 MOVB *0(%ap),{uword}%r0
000043ec: a0 40                                          PUSHW %r0
000043ee: a0 7f e8 11 00 02                              PUSHW $0x20011e8
000043f4: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
000043fc: 28 40                                          TSTW %r0
000043fe: 43 07                                          BGEB &0x7 <0x4405>
00004400: 84 ff 40                                       MOVW &-1,%r0
00004403: 7b 75                                          BRB &0x75 <0x4478>
00004405: 3f 08 da 00                                    CMPB &0x8,*0(%ap)
00004409: 77 23                                          BNEB &0x23 <0x442c>
0000440b: 3c 48 5a                                       CMPW %r8,(%ap)
0000440e: 7f 1c                                          BEB &0x1c <0x442a>
00004410: a0 4f 24 0b 00 00                              PUSHW &0xb24
00004416: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
0000441e: 28 40                                          TSTW %r0
00004420: 43 07                                          BGEB &0x7 <0x4427>
00004422: 84 ff 40                                       MOVW &-1,%r0
00004425: 7b 53                                          BRB &0x53 <0x4478>
00004427: 94 5a                                          DECW (%ap)
00004429: 70                                             NOP
0000442a: 7b 2b                                          BRB &0x2b <0x4455>
0000442c: 3f 6f 40 da 00                                 CMPB &0x40,*0(%ap)
00004431: 77 21                                          BNEB &0x21 <0x4452>
00004433: 84 48 5a                                       MOVW %r8,(%ap)
00004436: 70                                             NOP
00004437: a0 0a                                          PUSHW &0xa
00004439: a0 7f e8 11 00 02                              PUSHW $0x20011e8
0000443f: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
00004447: 28 40                                          TSTW %r0
00004449: 43 07                                          BGEB &0x7 <0x4450>
0000444b: 84 ff 40                                       MOVW &-1,%r0
0000444e: 7b 2a                                          BRB &0x2a <0x4478>
00004450: 7b 05                                          BRB &0x5 <0x4455>
00004452: 90 5a                                          INCW (%ap)
00004454: 70                                             NOP
00004455: fc 48 5a 40                                    SUBW3 %r8,(%ap),%r0
00004459: 3c 6f 50 40                                    CMPW &0x50,%r0
0000445d: 4a 2c ff                                       BLH &0xff2c <0x4389>
00004460: a0 4f 27 0b 00 00                              PUSHW &0xb27
00004466: a0 6f 50                                       PUSHW &0x50
00004469: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00004471: 84 48 5a                                       MOVW %r8,(%ap)
00004474: 70                                             NOP
00004475: 7a 0e ff                                       BRH &0xff0e <0x4383>
00004478: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
0000447c: 20 48                                          POPW %r8
0000447e: 20 47                                          POPW %r7
00004480: 20 49                                          POPW %fp
00004482: 08                                             RET
00004483: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'getstat' - Routine to check console for character present
;;

00004484: 10 49                                          SAVE %fp
00004486: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp

;; Call soft-power inhibit/timer function.
0000448d: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00004494: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
0000449c: 2b 50                                          TSTB (%r0)
0000449e: 7f 0f                                          BEB &0xf <0x44ad>
000044a0: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
000044a8: 3f 01 50                                       CMPB &0x1,(%r0)
000044ab: 7f 21                                          BEB &0x21 <0x44cc>

;; R0 = 0x49001 (UART port A status)
000044ad: dc 01 7f e8 11 00 02 40                        ADDW3 &0x1,$0x20011e8,%r0
;; If BIT 1 (RxRDY) is set, jump to 44C8
000044b5: 3b 50 01                                       BITB (%r0),&0x1
000044b8: 7f 10                                          BEB &0x10 <0x44c8>

;; If not, grab the data in 49003
;; R0 = 0x49004 (UART port A data)
000044ba: dc 03 7f e8 11 00 02 40                        ADDW3 &0x3,$0x20011e8,%r0
000044c2: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
000044c6: 7b 16                                          BRB &0x16 <0x44dc>

000044c8: 80 40                                          CLRW %r0
000044ca: 7b 12                                          BRB &0x12 <0x44dc>
000044cc: a0 01                                          PUSHW &0x1

000044ce: 2c cc fc 7f f8 56 00 00                        CALL -4(%sp),$0x56f8
000044d6: 87 40 e0 40                                    MOVB %r0,{uword}%r0
000044da: 7b 02                                          BRB &0x2 <0x44dc>
000044dc: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000044e0: 20 49                                          POPW %fp
000044e2: 08                                             RET
000044e3: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'printf' Routine
;;

000044e4: 10 49                                          SAVE %fp
000044e6: 9c 4f 38 00 00 00 4c                           ADDW2 &0x38,%sp
000044ed: 2b ef c4 04 00 00                              TSTB *$0x4c4
000044f3: 77 11                                          BNEB &0x11 <0x4504>
000044f5: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
000044fc: 80 40                                          CLRW %r0
000044fe: 24 7f ae 48 00 00                              JMP $0x48ae
00004504: dc 02 7f e8 11 00 02 40                        ADDW3 &0x2,$0x20011e8,%r0
0000450c: 87 15 50                                       MOVB &0x15,(%r0)
0000450f: 70                                             NOP
00004510: 80 c9 28                                       CLRW 40(%fp)
00004513: 70                                             NOP
00004514: 04 74 59                                       MOVAW 4(%ap),(%fp)
00004517: 70                                             NOP
00004518: 24 7f 88 48 00 00                              JMP $0x4888
0000451e: 3f 25 da 00                                    CMPB &0x25,*0(%ap)
00004522: 7f 08                                          BEB &0x8 <0x452a>
00004524: 24 7f 67 48 00 00                              JMP $0x4867
0000452a: 84 20 68                                       MOVW &0x20,8(%fp)
0000452d: 70                                             NOP
0000452e: 80 64                                          CLRW 4(%fp)
00004530: 70                                             NOP
00004531: 80 c9 18                                       CLRW 24(%fp)
00004534: 70                                             NOP
00004535: 80 c9 1c                                       CLRW 28(%fp)
00004538: 70                                             NOP
00004539: 90 5a                                          INCW (%ap)
0000453b: 70                                             NOP
0000453c: 3f 2d da 00                                    CMPB &0x2d,*0(%ap)
00004540: 77 09                                          BNEB &0x9 <0x4549>
00004542: 84 01 64                                       MOVW &0x1,4(%fp)
00004545: 70                                             NOP
00004546: 90 5a                                          INCW (%ap)
00004548: 70                                             NOP
00004549: 3f 30 da 00                                    CMPB &0x30,*0(%ap)
0000454d: 77 0d                                          BNEB &0xd <0x455a>
0000454f: 28 64                                          TSTW 4(%fp)
00004551: 77 06                                          BNEB &0x6 <0x4557>
00004553: 84 30 68                                       MOVW &0x30,8(%fp)
00004556: 70                                             NOP
00004557: 90 5a                                          INCW (%ap)
00004559: 70                                             NOP
0000455a: 7b 17                                          BRB &0x17 <0x4571>
0000455c: e8 0a c9 1c 40                                 MULW3 &0xa,28(%fp),%r0
00004561: ff 30 da 00 41                                 SUBB3 &0x30,*0(%ap),%r1
00004566: 9c 41 40                                       ADDW2 %r1,%r0
00004569: 84 40 c9 1c                                    MOVW %r0,28(%fp)
0000456d: 70                                             NOP
0000456e: 90 5a                                          INCW (%ap)
00004570: 70                                             NOP
00004571: 3f 30 da 00                                    CMPB &0x30,*0(%ap)
00004575: 4b 08                                          BLB &0x8 <0x457d>
00004577: 3f 39 da 00                                    CMPB &0x39,*0(%ap)
0000457b: 4f e1                                          BLEB &0xe1 <0x455c>
0000457d: 3f 6f 6c da 00                                 CMPB &0x6c,*0(%ap)
00004582: 7f 09                                          BEB &0x9 <0x458b>
00004584: 3f 6f 68 da 00                                 CMPB &0x68,*0(%ap)
00004589: 77 05                                          BNEB &0x5 <0x458e>
0000458b: 90 5a                                          INCW (%ap)
0000458d: 70                                             NOP
0000458e: 87 da 00 e0 40                                 MOVB *0(%ap),{uword}%r0
00004593: 24 7f 12 48 00 00                              JMP $0x4812
00004599: dc 03 59 40                                    ADDW3 &0x3,(%fp),%r0
0000459d: 87 50 c9 10                                    MOVB (%r0),16(%fp)
000045a1: 70                                             NOP
000045a2: 9c 04 59                                       ADDW2 &0x4,(%fp)
000045a5: 70                                             NOP
000045a6: 2b c9 10                                       TSTB 16(%fp)
000045a9: 7f 20                                          BEB &0x20 <0x45c9>
000045ab: 87 c9 10 e0 40                                 MOVB 16(%fp),{uword}%r0
000045b0: a0 40                                          PUSHW %r0
000045b2: a0 7f e8 11 00 02                              PUSHW $0x20011e8
000045b8: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
000045c0: 28 40                                          TSTW %r0
000045c2: 43 07                                          BGEB &0x7 <0x45c9>
000045c4: 84 01 c9 28                                    MOVW &0x1,40(%fp)
000045c8: 70                                             NOP
000045c9: 24 7f 65 48 00 00                              JMP $0x4865
000045cf: 84 d9 00 c9 14                                 MOVW *0(%fp),20(%fp)
000045d4: 70                                             NOP
000045d5: 9c 04 59                                       ADDW2 &0x4,(%fp)
000045d8: 70                                             NOP
000045d9: 28 c9 14                                       TSTW 20(%fp)
000045dc: 77 0b                                          BNEB &0xb <0x45e7>
000045de: 84 4f 70 0b 00 00 c9 14                        MOVW &0xb70,20(%fp)
000045e6: 70                                             NOP
000045e7: 80 6c                                          CLRW 12(%fp)
000045e9: 70                                             NOP
000045ea: 7b 2a                                          BRB &0x2a <0x4614>
000045ec: 90 6c                                          INCW 12(%fp)
000045ee: 70                                             NOP
000045ef: 84 c9 14 40                                    MOVW 20(%fp),%r0
000045f3: 90 c9 14                                       INCW 20(%fp)
000045f6: 70                                             NOP
000045f7: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
000045fb: a0 40                                          PUSHW %r0
000045fd: a0 7f e8 11 00 02                              PUSHW $0x20011e8
00004603: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
0000460b: 28 40                                          TSTW %r0
0000460d: 43 07                                          BGEB &0x7 <0x4614>
0000460f: 84 01 c9 28                                    MOVW &0x1,40(%fp)
00004613: 70                                             NOP
00004614: 2b d9 14                                       TSTB *20(%fp)
00004617: 77 d5                                          BNEB &0xd5 <0x45ec>
00004619: 7b 1b                                          BRB &0x1b <0x4634>
0000461b: a0 20                                          PUSHW &0x20
0000461d: a0 7f e8 11 00 02                              PUSHW $0x20011e8
00004623: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
0000462b: 28 40                                          TSTW %r0
0000462d: 43 07                                          BGEB &0x7 <0x4634>
0000462f: 84 01 c9 28                                    MOVW &0x1,40(%fp)
00004633: 70                                             NOP
00004634: 84 6c 40                                       MOVW 12(%fp),%r0
00004637: 90 6c                                          INCW 12(%fp)
00004639: 70                                             NOP
0000463a: 3c c9 1c 40                                    CMPW 28(%fp),%r0
0000463e: 4b dd                                          BLB &0xdd <0x461b>
00004640: 24 7f 65 48 00 00                              JMP $0x4865
00004646: 84 10 c9 24                                    MOVW &0x10,36(%fp)
0000464a: 70                                             NOP
0000464b: 7b 13                                          BRB &0x13 <0x465e>
0000464d: 84 01 c9 18                                    MOVW &0x1,24(%fp)
00004651: 70                                             NOP
00004652: 84 0a c9 24                                    MOVW &0xa,36(%fp)
00004656: 70                                             NOP
00004657: 7b 07                                          BRB &0x7 <0x465e>
00004659: 84 08 c9 24                                    MOVW &0x8,36(%fp)
0000465d: 70                                             NOP
0000465e: 84 d9 00 c9 20                                 MOVW *0(%fp),32(%fp)
00004663: 70                                             NOP
00004664: 9c 04 59                                       ADDW2 &0x4,(%fp)
00004667: 70                                             NOP
00004668: 28 c9 20                                       TSTW 32(%fp)
0000466b: 77 15                                          BNEB &0x15 <0x4680>
0000466d: 84 01 6c                                       MOVW &0x1,12(%fp)
00004670: 70                                             NOP
00004671: 87 7f 5c 0b 00 00 c9 2c                        MOVB $0xb5c,44(%fp)
00004679: 70                                             NOP
0000467a: 80 c9 18                                       CLRW 24(%fp)
0000467d: 70                                             NOP
0000467e: 7b 74                                          BRB &0x74 <0x46f2>
00004680: 3c 01 c9 18                                    CMPW &0x1,24(%fp)
00004684: 77 17                                          BNEB &0x17 <0x469b>
00004686: d4 1f c9 20 40                                 LRSW3 &0x1f,32(%fp),%r0
0000468b: 7f 10                                          BEB &0x10 <0x469b>
0000468d: 88 c9 20 40                                    MCOMW 32(%fp),%r0
00004691: 9c 01 40                                       ADDW2 &0x1,%r0
00004694: 84 40 c9 20                                    MOVW %r0,32(%fp)
00004698: 70                                             NOP
00004699: 7b 06                                          BRB &0x6 <0x469f>
0000469b: 80 c9 18                                       CLRW 24(%fp)
0000469e: 70                                             NOP
0000469f: 80 6c                                          CLRW 12(%fp)
000046a1: 70                                             NOP
000046a2: 7b 22                                          BRB &0x22 <0x46c4>
000046a4: 04 c9 2c 40                                    MOVAW 44(%fp),%r0
000046a8: 9c 6c 40                                       ADDW2 12(%fp),%r0
000046ab: e4 e0 c9 24 c9 20 41                           MODW3 {uword}36(%fp),32(%fp),%r1
000046b2: 87 81 5c 0b 00 00 50                           MOVB 0xb5c(%r1),(%r0)
000046b9: 70                                             NOP
000046ba: ac e0 c9 24 c9 20                              DIVW2 {uword}36(%fp),32(%fp)
000046c0: 70                                             NOP
000046c1: 90 6c                                          INCW 12(%fp)
000046c3: 70                                             NOP
000046c4: 28 c9 20                                       TSTW 32(%fp)
000046c7: 7f 07                                          BEB &0x7 <0x46ce>
000046c9: 3c 0c 6c                                       CMPW &0xc,12(%fp)
000046cc: 4b d8                                          BLB &0xd8 <0x46a4>
000046ce: 3c 0c 6c                                       CMPW &0xc,12(%fp)
000046d1: 4b 21                                          BLB &0x21 <0x46f2>
000046d3: a0 3f                                          PUSHW &0x3f
000046d5: a0 7f e8 11 00 02                              PUSHW $0x20011e8
000046db: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
000046e3: 28 40                                          TSTW %r0
000046e5: 43 07                                          BGEB &0x7 <0x46ec>
000046e7: 84 01 c9 28                                    MOVW &0x1,40(%fp)
000046eb: 70                                             NOP
000046ec: 24 7f 65 48 00 00                              JMP $0x4865
000046f2: 28 64                                          TSTW 4(%fp)
000046f4: 77 78                                          BNEB &0x78 <0x476c>
000046f6: 3c 01 c9 18                                    CMPW &0x1,24(%fp)
000046fa: 77 24                                          BNEB &0x24 <0x471e>
000046fc: 94 c9 1c                                       DECW 28(%fp)
000046ff: 70                                             NOP
00004700: 3c 30 68                                       CMPW &0x30,8(%fp)
00004703: 77 1b                                          BNEB &0x1b <0x471e>
00004705: a0 2d                                          PUSHW &0x2d
00004707: a0 7f e8 11 00 02                              PUSHW $0x20011e8
0000470d: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
00004715: 28 40                                          TSTW %r0
00004717: 43 07                                          BGEB &0x7 <0x471e>
00004719: 84 01 c9 28                                    MOVW &0x1,40(%fp)
0000471d: 70                                             NOP
0000471e: 7b 1b                                          BRB &0x1b <0x4739>
00004720: a0 68                                          PUSHW 8(%fp)
00004722: a0 7f e8 11 00 02                              PUSHW $0x20011e8
00004728: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
00004730: 28 40                                          TSTW %r0
00004732: 43 07                                          BGEB &0x7 <0x4739>
00004734: 84 01 c9 28                                    MOVW &0x1,40(%fp)
00004738: 70                                             NOP
00004739: 84 c9 1c 40                                    MOVW 28(%fp),%r0
0000473d: 94 c9 1c                                       DECW 28(%fp)
00004740: 70                                             NOP
00004741: 3c 6c 40                                       CMPW 12(%fp),%r0
00004744: 47 dc                                          BGB &0xdc <0x4720>
00004746: 3c 01 c9 18                                    CMPW &0x1,24(%fp)
0000474a: 77 20                                          BNEB &0x20 <0x476a>
0000474c: 3c 20 68                                       CMPW &0x20,8(%fp)
0000474f: 77 1b                                          BNEB &0x1b <0x476a>
00004751: a0 2d                                          PUSHW &0x2d
00004753: a0 7f e8 11 00 02                              PUSHW $0x20011e8
00004759: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
00004761: 28 40                                          TSTW %r0
00004763: 43 07                                          BGEB &0x7 <0x476a>
00004765: 84 01 c9 28                                    MOVW &0x1,40(%fp)
00004769: 70                                             NOP
0000476a: 7b 2a                                          BRB &0x2a <0x4794>
0000476c: 3c 01 c9 18                                    CMPW &0x1,24(%fp)
00004770: 77 1f                                          BNEB &0x1f <0x478f>
00004772: 94 c9 1c                                       DECW 28(%fp)
00004775: 70                                             NOP
00004776: a0 2d                                          PUSHW &0x2d
00004778: a0 7f e8 11 00 02                              PUSHW $0x20011e8
0000477e: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
00004786: 28 40                                          TSTW %r0
00004788: 43 07                                          BGEB &0x7 <0x478f>
0000478a: 84 01 c9 28                                    MOVW &0x1,40(%fp)
0000478e: 70                                             NOP
0000478f: bc 6c c9 1c                                    SUBW2 12(%fp),28(%fp)
00004793: 70                                             NOP
00004794: 7b 26                                          BRB &0x26 <0x47ba>
00004796: 04 c9 2c 40                                    MOVAW 44(%fp),%r0
0000479a: 9c 6c 40                                       ADDW2 12(%fp),%r0
0000479d: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
000047a1: a0 40                                          PUSHW %r0
000047a3: a0 7f e8 11 00 02                              PUSHW $0x20011e8
000047a9: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
000047b1: 28 40                                          TSTW %r0
000047b3: 43 07                                          BGEB &0x7 <0x47ba>
000047b5: 84 01 c9 28                                    MOVW &0x1,40(%fp)
000047b9: 70                                             NOP
000047ba: 94 6c                                          DECW 12(%fp)
000047bc: 70                                             NOP
000047bd: 43 d9                                          BGEB &0xd9 <0x4796>
000047bf: 3c 01 64                                       CMPW &0x1,4(%fp)
000047c2: 77 2e                                          BNEB &0x2e <0x47f0>
000047c4: 7b 1b                                          BRB &0x1b <0x47df>
000047c6: a0 68                                          PUSHW 8(%fp)
000047c8: a0 7f e8 11 00 02                              PUSHW $0x20011e8
000047ce: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
000047d6: 28 40                                          TSTW %r0
000047d8: 43 07                                          BGEB &0x7 <0x47df>
000047da: 84 01 c9 28                                    MOVW &0x1,40(%fp)
000047de: 70                                             NOP
000047df: 84 c9 1c 40                                    MOVW 28(%fp),%r0
000047e3: 94 c9 1c                                       DECW 28(%fp)
000047e6: 70                                             NOP
000047e7: dc 01 6c 41                                    ADDW3 &0x1,12(%fp),%r1
000047eb: 3c 41 40                                       CMPW %r1,%r0
000047ee: 47 d8                                          BGB &0xd8 <0x47c6>
000047f0: 7b 75                                          BRB &0x75 <0x4865>
000047f2: 87 da 00 e0 40                                 MOVB *0(%ap),{uword}%r0
000047f7: a0 40                                          PUSHW %r0
000047f9: a0 7f e8 11 00 02                              PUSHW $0x20011e8
000047ff: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
00004807: 28 40                                          TSTW %r0
00004809: 43 07                                          BGEB &0x7 <0x4810>
0000480b: 84 01 c9 28                                    MOVW &0x1,40(%fp)
0000480f: 70                                             NOP
00004810: 7b 55                                          BRB &0x55 <0x4865>
00004812: 3c 6f 6f 40                                    CMPW &0x6f,%r0
00004816: 7e 43 fe                                       BEH &0xfe43 <0x4659>
00004819: 47 2f                                          BGB &0x2f <0x4848>
0000481b: 3c 6f 63 40                                    CMPW &0x63,%r0
0000481f: 7e 7a fd                                       BEH &0xfd7a <0x4599>
00004822: 47 1d                                          BGB &0x1d <0x483f>
00004824: 3c 6f 4f 40                                    CMPW &0x4f,%r0
00004828: 7e 31 fe                                       BEH &0xfe31 <0x4659>
0000482b: 47 0b                                          BGB &0xb <0x4836>
0000482d: 3c 6f 44 40                                    CMPW &0x44,%r0
00004831: 7e 1c fe                                       BEH &0xfe1c <0x464d>
00004834: 7b be                                          BRB &0xbe <0x47f2>
00004836: 3c 6f 58 40                                    CMPW &0x58,%r0
0000483a: 7e 0c fe                                       BEH &0xfe0c <0x4646>
0000483d: 7b b5                                          BRB &0xb5 <0x47f2>
0000483f: 3c 6f 64 40                                    CMPW &0x64,%r0
00004843: 7e 0a fe                                       BEH &0xfe0a <0x464d>
00004846: 7b ac                                          BRB &0xac <0x47f2>
00004848: 3c 6f 75 40                                    CMPW &0x75,%r0
0000484c: 7e 06 fe                                       BEH &0xfe06 <0x4652>
0000484f: 47 0b                                          BGB &0xb <0x485a>
00004851: 3c 6f 73 40                                    CMPW &0x73,%r0
00004855: 7e 7a fd                                       BEH &0xfd7a <0x45cf>
00004858: 7b 9a                                          BRB &0x9a <0x47f2>
0000485a: 3c 6f 78 40                                    CMPW &0x78,%r0
0000485e: 7e e8 fd                                       BEH &0xfde8 <0x4646>
00004861: 7b 91                                          BRB &0x91 <0x47f2>
00004863: 7b 8f                                          BRB &0x8f <0x47f2>
00004865: 7b 20                                          BRB &0x20 <0x4885>
00004867: 87 da 00 e0 40                                 MOVB *0(%ap),{uword}%r0
0000486c: a0 40                                          PUSHW %r0
0000486e: a0 7f e8 11 00 02                              PUSHW $0x20011e8
00004874: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
0000487c: 28 40                                          TSTW %r0
0000487e: 43 07                                          BGEB &0x7 <0x4885>
00004880: 84 01 c9 28                                    MOVW &0x1,40(%fp)
00004884: 70                                             NOP
00004885: 90 5a                                          INCW (%ap)
00004887: 70                                             NOP
00004888: 2b da 00                                       TSTB *0(%ap)
0000488b: 76 93 fc                                       BNEH &0xfc93 <0x451e>
0000488e: 3c 01 c9 28                                    CMPW &0x1,40(%fp)
00004892: 77 17                                          BNEB &0x17 <0x48a9>
00004894: a0 0a                                          PUSHW &0xa
00004896: a0 7f e8 11 00 02                              PUSHW $0x20011e8
0000489c: 2c cc f8 7f b8 48 00 00                        CALL -8(%sp),$0x48b8
000048a4: 84 ff 40                                       MOVW &-1,%r0
000048a7: 7b 07                                          BRB &0x7 <0x48ae>
000048a9: 84 01 40                                       MOVW &0x1,%r0
000048ac: 7b 02                                          BRB &0x2 <0x48ae>
000048ae: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000048b2: 20 49                                          POPW %fp
000048b4: 08                                             RET
000048b5: 70                                             NOP
000048b6: 70                                             NOP
000048b7: 70                                             NOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown routine, but used by 'printf'
;;
000048b8: 10 49                                          SAVE %fp
000048ba: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
000048c1: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
000048c8: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
000048d0: 2b 50                                          TSTB (%r0)
000048d2: 7f 15                                          BEB &0x15 <0x48e7>
000048d4: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
000048dc: 3f 01 50                                       CMPB &0x1,(%r0)
000048df: 77 08                                          BNEB &0x8 <0x48e7>
000048e1: 24 7f 63 4a 00 00                              JMP $0x4a63
000048e7: 87 73 e2 40                                    MOVB 3(%ap),{uhalf}%r0
000048eb: 86 40 62                                       MOVH %r0,2(%fp)
000048ee: 70                                             NOP
000048ef: 3c 7f e8 11 00 02 74                           CMPW $0x20011e8,4(%ap)
000048f6: 7f 08                                          BEB &0x8 <0x48fe>
000048f8: 24 7f f0 49 00 00                              JMP $0x49f0
000048fe: 2b 7f 68 08 00 02                              TSTB $0x2000868
00004904: 7f 08                                          BEB &0x8 <0x490c>
00004906: 24 7f f0 49 00 00                              JMP $0x49f0
0000490c: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
00004910: 3b 50 01                                       BITB (%r0),&0x1
00004913: 77 08                                          BNEB &0x8 <0x491b>
00004915: 24 7f f0 49 00 00                              JMP $0x49f0
0000491b: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
0000491f: 3b 50 5f 80 00                                 BITB (%r0),&0x80
00004924: 7f 4f                                          BEB &0x4f <0x4973>
00004926: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
0000492a: 87 6f 40 50                                    MOVB &0x40,(%r0)
0000492e: 70                                             NOP
0000492f: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
00004933: 87 6f 50 50                                    MOVB &0x50,(%r0)
00004937: 70                                             NOP
00004938: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
0000493c: 87 50 e2 40                                    MOVB (%r0),{uhalf}%r0
00004940: 86 40 59                                       MOVH %r0,(%fp)
00004943: 70                                             NOP
00004944: 7b 20                                          BRB &0x20 <0x4964>
00004946: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
0000494a: 87 6f 40 50                                    MOVB &0x40,(%r0)
0000494e: 70                                             NOP
0000494f: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
00004953: 87 6f 50 50                                    MOVB &0x50,(%r0)
00004957: 70                                             NOP
00004958: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
0000495c: 87 50 e2 40                                    MOVB (%r0),{uhalf}%r0
00004960: 86 40 59                                       MOVH %r0,(%fp)
00004963: 70                                             NOP
00004964: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
00004968: 3b 50 01                                       BITB (%r0),&0x1
0000496b: 77 db                                          BNEB &0xdb <0x4946>
0000496d: 86 ff 62                                       MOVH &-1,2(%fp)
00004970: 70                                             NOP
00004971: 7b 7f                                          BRB &0x7f <0x49f0>
00004973: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
00004977: 3f 13 50                                       CMPB &0x13,(%r0)
0000497a: 77 76                                          BNEB &0x76 <0x49f0>
0000497c: 7b 09                                          BRB &0x9 <0x4985>
0000497e: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00004985: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
00004989: 3b 50 01                                       BITB (%r0),&0x1
0000498c: 7f f2                                          BEB &0xf2 <0x497e>
0000498e: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
00004992: 3b 50 5f 80 00                                 BITB (%r0),&0x80
00004997: 7f 4d                                          BEB &0x4d <0x49e4>
00004999: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
0000499d: 87 6f 40 50                                    MOVB &0x40,(%r0)
000049a1: 70                                             NOP
000049a2: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
000049a6: 87 6f 50 50                                    MOVB &0x50,(%r0)
000049aa: 70                                             NOP
000049ab: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
000049af: 87 50 e2 40                                    MOVB (%r0),{uhalf}%r0
000049b3: 86 40 59                                       MOVH %r0,(%fp)
000049b6: 70                                             NOP
000049b7: 7b 20                                          BRB &0x20 <0x49d7>
000049b9: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
000049bd: 87 6f 40 50                                    MOVB &0x40,(%r0)
000049c1: 70                                             NOP
000049c2: dc 02 74 40                                    ADDW3 &0x2,4(%ap),%r0
000049c6: 87 6f 50 50                                    MOVB &0x50,(%r0)
000049ca: 70                                             NOP
000049cb: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
000049cf: 87 50 e2 40                                    MOVB (%r0),{uhalf}%r0
000049d3: 86 40 59                                       MOVH %r0,(%fp)
000049d6: 70                                             NOP
000049d7: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
000049db: 3b 50 01                                       BITB (%r0),&0x1
000049de: 77 db                                          BNEB &0xdb <0x49b9>
000049e0: 86 ff 62                                       MOVH &-1,2(%fp)
000049e3: 70                                             NOP
000049e4: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
000049e8: 87 50 e2 40                                    MOVB (%r0),{uhalf}%r0
000049ec: 86 40 59                                       MOVH %r0,(%fp)
000049ef: 70                                             NOP
000049f0: 7b 09                                          BRB &0x9 <0x49f9>
000049f2: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
000049f9: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
000049fd: 3b 50 04                                       BITB (%r0),&0x4

00004a00: 7f f2                                          BEB &0xf2 <0x49f2>
00004a02: 3c 7f e8 11 00 02 74                           CMPW $0x20011e8,4(%ap)
00004a09: 77 2b                                          BNEB &0x2b <0x4a34>
00004a0b: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0

;; Write a single character out (R0 here contains address 49003)
00004a0f: 87 73 50                                       MOVB 3(%ap),(%r0)
00004a12: 70                                             NOP
00004a13: 3f 0a 73                                       CMPB &0xa,3(%ap)
00004a16: 77 1c                                          BNEB &0x1c <0x4a32>
00004a18: 7b 09                                          BRB &0x9 <0x4a21>
00004a1a: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00004a21: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
00004a25: 3b 50 04                                       BITB (%r0),&0x4
00004a28: 7f f2                                          BEB &0xf2 <0x4a1a>
00004a2a: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
00004a2e: 87 0d 50                                       MOVB &0xd,(%r0)
00004a31: 70                                             NOP
00004a32: 7b 19                                          BRB &0x19 <0x4a4b>
00004a34: 3f 0a 73                                       CMPB &0xa,3(%ap)
00004a37: 77 0c                                          BNEB &0xc <0x4a43>
00004a39: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
00004a3d: 87 0d 50                                       MOVB &0xd,(%r0)
00004a40: 70                                             NOP
00004a41: 7b 0a                                          BRB &0xa <0x4a4b>
00004a43: dc 03 74 40                                    ADDW3 &0x3,4(%ap),%r0
00004a47: 87 73 50                                       MOVB 3(%ap),(%r0)
00004a4a: 70                                             NOP
00004a4b: 7b 09                                          BRB &0x9 <0x4a54>
00004a4d: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00004a54: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
00004a58: 3b 50 04                                       BITB (%r0),&0x4
00004a5b: 7f f2                                          BEB &0xf2 <0x4a4d>
00004a5d: 86 62 e4 40                                    MOVH 2(%fp),{word}%r0
00004a61: 7b 7b                                          BRB &0x7b <0x4adc>
00004a63: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00004a67: a0 40                                          PUSHW %r0
00004a69: 2c cc fc 7f 6a 58 00 00                        CALL -4(%sp),$0x586a
00004a71: 86 40 59                                       MOVH %r0,(%fp)
00004a74: 70                                             NOP
00004a75: 3e ff 59                                       CMPH &-1,(%fp)
00004a78: 77 08                                          BNEB &0x8 <0x4a80>
00004a7a: 86 59 e4 40                                    MOVH (%fp),{word}%r0
00004a7e: 7b 5e                                          BRB &0x5e <0x4adc>
00004a80: 3e 13 59                                       CMPH &0x13,(%fp)
00004a83: 77 19                                          BNEB &0x19 <0x4a9c>
00004a85: 7b 09                                          BRB &0x9 <0x4a8e>
00004a87: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00004a8e: a0 01                                          PUSHW &0x1
00004a90: 2c cc fc 7f f8 56 00 00                        CALL -4(%sp),$0x56f8
00004a98: 28 40                                          TSTW %r0
00004a9a: 7f ed                                          BEB &0xed <0x4a87>
00004a9c: 3f 0a 73                                       CMPB &0xa,3(%ap)
00004a9f: 77 37                                          BNEB &0x37 <0x4ad6>
00004aa1: a0 0d                                          PUSHW &0xd
00004aa3: 2c cc fc 7f 6a 58 00 00                        CALL -4(%sp),$0x586a
00004aab: 86 40 59                                       MOVH %r0,(%fp)
00004aae: 70                                             NOP
00004aaf: 3e ff 59                                       CMPH &-1,(%fp)
00004ab2: 77 08                                          BNEB &0x8 <0x4aba>
00004ab4: 86 59 e4 40                                    MOVH (%fp),{word}%r0
00004ab8: 7b 24                                          BRB &0x24 <0x4adc>
00004aba: 3e 13 59                                       CMPH &0x13,(%fp)
00004abd: 77 19                                          BNEB &0x19 <0x4ad6>
00004abf: 7b 09                                          BRB &0x9 <0x4ac8>
00004ac1: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00004ac8: a0 01                                          PUSHW &0x1
00004aca: 2c cc fc 7f f8 56 00 00                        CALL -4(%sp),$0x56f8
00004ad2: 28 40                                          TSTW %r0
00004ad4: 7f ed                                          BEB &0xed <0x4ac1>
00004ad6: 86 59 e4 40                                    MOVH (%fp),{word}%r0
00004ada: 7b 02                                          BRB &0x2 <0x4adc>
00004adc: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00004ae0: 20 49                                          POPW %fp
00004ae2: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'sscanf' Routine
;;

00004ae3: 70                                             NOP
00004ae4: 10 45                                          SAVE %r5
00004ae6: 9c 4f 1c 00 00 00 4c                           ADDW2 &0x1c,%sp
00004aed: 04 78 68                                       MOVAW 8(%ap),8(%fp)
00004af0: 70                                             NOP
00004af1: 24 7f c4 4c 00 00                              JMP $0x4cc4
00004af7: 80 46                                          CLRW %r6
00004af9: 7b 0f                                          BRB &0xf <0x4b08>
00004afb: 2b da 04                                       TSTB *4(%ap)
00004afe: 77 07                                          BNEB &0x7 <0x4b05>
00004b00: 84 01 46                                       MOVW &0x1,%r6
00004b03: 7b 0b                                          BRB &0xb <0x4b0e>
00004b05: 90 74                                          INCW 4(%ap)
00004b07: 70                                             NOP
00004b08: 3f 25 da 04                                    CMPB &0x25,*4(%ap)
00004b0c: 77 ef                                          BNEB &0xef <0x4afb>
00004b0e: 28 46                                          TSTW %r6
00004b10: 7f 08                                          BEB &0x8 <0x4b18>
00004b12: 24 7f ca 4c 00 00                              JMP $0x4cca
00004b18: 7b 05                                          BRB &0x5 <0x4b1d>
00004b1a: 90 5a                                          INCW (%ap)
00004b1c: 70                                             NOP
00004b1d: 3f 20 da 00                                    CMPB &0x20,*0(%ap)
00004b21: 77 07                                          BNEB &0x7 <0x4b28>
00004b23: 84 01 40                                       MOVW &0x1,%r0
00004b26: 7b 04                                          BRB &0x4 <0x4b2a>
00004b28: 80 40                                          CLRW %r0
00004b2a: 84 40 6c                                       MOVW %r0,12(%fp)
00004b2d: 70                                             NOP
00004b2e: 3f 09 da 00                                    CMPB &0x9,*0(%ap)
00004b32: 77 07                                          BNEB &0x7 <0x4b39>
00004b34: 84 01 40                                       MOVW &0x1,%r0
00004b37: 7b 04                                          BRB &0x4 <0x4b3b>
00004b39: 80 40                                          CLRW %r0
00004b3b: 84 40 c9 10                                    MOVW %r0,16(%fp)
00004b3f: 70                                             NOP
00004b40: 3f 2d da 00                                    CMPB &0x2d,*0(%ap)
00004b44: 77 07                                          BNEB &0x7 <0x4b4b>
00004b46: 84 01 40                                       MOVW &0x1,%r0
00004b49: 7b 04                                          BRB &0x4 <0x4b4d>
00004b4b: 80 40                                          CLRW %r0
00004b4d: 84 40 c9 14                                    MOVW %r0,20(%fp)
00004b51: 70                                             NOP
00004b52: 3f 2c da 00                                    CMPB &0x2c,*0(%ap)
00004b56: 77 07                                          BNEB &0x7 <0x4b5d>
00004b58: 84 01 40                                       MOVW &0x1,%r0
00004b5b: 7b 04                                          BRB &0x4 <0x4b5f>
00004b5d: 80 40                                          CLRW %r0
00004b5f: 84 40 c9 18                                    MOVW %r0,24(%fp)
00004b63: 70                                             NOP
00004b64: 3f 3d da 00                                    CMPB &0x3d,*0(%ap)
00004b68: 77 07                                          BNEB &0x7 <0x4b6f>
00004b6a: 84 01 40                                       MOVW &0x1,%r0
00004b6d: 7b 04                                          BRB &0x4 <0x4b71>
00004b6f: 80 40                                          CLRW %r0
00004b71: f0 c9 10 6c 41                                 ORW3 16(%fp),12(%fp),%r1
00004b76: b0 c9 14 41                                    ORW2 20(%fp),%r1
00004b7a: b0 c9 18 41                                    ORW2 24(%fp),%r1
00004b7e: b0 41 40                                       ORW2 %r1,%r0
00004b81: 77 99                                          BNEB &0x99 <0x4b1a>
00004b83: 90 74                                          INCW 4(%ap)
00004b85: 70                                             NOP
00004b86: 87 da 04 e0 40                                 MOVB *4(%ap),{uword}%r0
00004b8b: 24 7f 96 4c 00 00                              JMP $0x4c96
00004b91: 84 5a 48                                       MOVW (%ap),%r8
00004b94: e0 5a                                          PUSHAW (%ap)
00004b96: 2c cc fc af 46 01                              CALL -4(%sp),0x146(%pc)
00004b9c: 7b 14                                          BRB &0x14 <0x4bb0>
00004b9e: 84 d9 08 40                                    MOVW *8(%fp),%r0
00004ba2: 70                                             NOP
00004ba3: 84 48 41                                       MOVW %r8,%r1
00004ba6: 90 48                                          INCW %r8
00004ba8: 87 51 50                                       MOVB (%r1),(%r0)
00004bab: 70                                             NOP
00004bac: 90 d9 08                                       INCW *8(%fp)
00004baf: 70                                             NOP
00004bb0: 3c 5a 48                                       CMPW (%ap),%r8
00004bb3: 77 eb                                          BNEB &0xeb <0x4b9e>
00004bb5: 84 d9 08 40                                    MOVW *8(%fp),%r0
00004bb9: 83 50                                          CLRB (%r0)
00004bbb: 70                                             NOP
00004bbc: 24 7f c0 4c 00 00                              JMP $0x4cc0
00004bc2: 84 d9 08 40                                    MOVW *8(%fp),%r0
00004bc6: 87 da 00 50                                    MOVB *0(%ap),(%r0)
00004bca: 70                                             NOP
00004bcb: 90 5a                                          INCW (%ap)
00004bcd: 70                                             NOP
00004bce: 24 7f c0 4c 00 00                              JMP $0x4cc0
00004bd4: 84 07 46                                       MOVW &0x7,%r6
00004bd7: 7b 0e                                          BRB &0xe <0x4be5>
00004bd9: 04 59 40                                       MOVAW (%fp),%r0
00004bdc: 9c 46 40                                       ADDW2 %r6,%r0
00004bdf: 87 30 50                                       MOVB &0x30,(%r0)
00004be2: 70                                             NOP
00004be3: 94 46                                          DECW %r6
00004be5: 28 46                                          TSTW %r6
00004be7: 43 f2                                          BGEB &0xf2 <0x4bd9>
00004be9: 84 5a 48                                       MOVW (%ap),%r8
00004bec: 04 67 47                                       MOVAW 7(%fp),%r7
00004bef: e0 5a                                          PUSHAW (%ap)
00004bf1: 2c cc fc af eb 00                              CALL -4(%sp),0xeb(%pc)
00004bf7: 94 5a                                          DECW (%ap)
00004bf9: 70                                             NOP
00004bfa: 87 da 00 57                                    MOVB *0(%ap),(%r7)
00004bfe: 70                                             NOP
00004bff: 3c 48 5a                                       CMPW %r8,(%ap)
00004c02: 77 04                                          BNEB &0x4 <0x4c06>
00004c04: 7b 09                                          BRB &0x9 <0x4c0d>
00004c06: 94 47                                          DECW %r7
00004c08: 94 5a                                          DECW (%ap)
00004c0a: 70                                             NOP
00004c0b: 7b ef                                          BRB &0xef <0x4bfa>
00004c0d: 80 45                                          CLRW %r5
00004c0f: 04 59 47                                       MOVAW (%fp),%r7
00004c12: 84 07 46                                       MOVW &0x7,%r6
00004c15: 7b 1d                                          BRB &0x1d <0x4c32>
00004c17: 87 57 e0 40                                    MOVB (%r7),{uword}%r0
00004c1b: a0 40                                          PUSHW %r0
00004c1d: 2c cc fc af 5f 01                              CALL -4(%sp),0x15f(%pc)
00004c23: d0 02 46 41                                    LLSW3 &0x2,%r6,%r1
00004c27: d0 41 40 40                                    LLSW3 %r1,%r0,%r0
00004c2b: b0 40 45                                       ORW2 %r0,%r5
00004c2e: 90 47                                          INCW %r7
00004c30: 94 46                                          DECW %r6
00004c32: 28 46                                          TSTW %r6
00004c34: 43 e3                                          BGEB &0xe3 <0x4c17>
00004c36: e0 5a                                          PUSHAW (%ap)
00004c38: 2c cc fc af a4 00                              CALL -4(%sp),0xa4(%pc)
00004c3e: 3f 6f 78 da 04                                 CMPB &0x78,*4(%ap)
00004c43: 77 12                                          BNEB &0x12 <0x4c55>
00004c45: 84 d9 08 40                                    MOVW *8(%fp),%r0
00004c49: 84 45 41                                       MOVW %r5,%r1
00004c4c: 86 41 41                                       MOVH %r1,%r1
00004c4f: 86 41 50                                       MOVH %r1,(%r0)
00004c52: 70                                             NOP
00004c53: 7b 0a                                          BRB &0xa <0x4c5d>
00004c55: 84 d9 08 40                                    MOVW *8(%fp),%r0
00004c59: 84 45 50                                       MOVW %r5,(%r0)
00004c5c: 70                                             NOP
00004c5d: 7b 63                                          BRB &0x63 <0x4cc0>
00004c5f: 3f 6f 64 da 04                                 CMPB &0x64,*4(%ap)
00004c64: 77 16                                          BNEB &0x16 <0x4c7a>
00004c66: a0 5a                                          PUSHW (%ap)
00004c68: 2c cc fc 7f d0 7e 00 00                        CALL -4(%sp),$0x7ed0
00004c70: 84 d9 08 41                                    MOVW *8(%fp),%r1
00004c74: 86 40 51                                       MOVH %r0,(%r1)
00004c77: 70                                             NOP
00004c78: 7b 14                                          BRB &0x14 <0x4c8c>
00004c7a: a0 5a                                          PUSHW (%ap)
00004c7c: 2c cc fc 7f 38 7e 00 00                        CALL -4(%sp),$0x7e38
00004c84: 84 d9 08 41                                    MOVW *8(%fp),%r1
00004c88: 84 40 51                                       MOVW %r0,(%r1)
00004c8b: 70                                             NOP
00004c8c: e0 5a                                          PUSHAW (%ap)
00004c8e: 2c cc fc af 4e 00                              CALL -4(%sp),0x4e(%pc)
00004c94: 7b 2c                                          BRB &0x2c <0x4cc0>
00004c96: 3c 40 6f 44                                    CMPW %r0,&0x44
00004c9a: 7f c5                                          BEB &0xc5 <0x4c5f>
00004c9c: 3c 40 6f 58                                    CMPW %r0,&0x58
00004ca0: 7e 34 ff                                       BEH &0xff34 <0x4bd4>
00004ca3: 3c 40 6f 63                                    CMPW %r0,&0x63
00004ca7: 7e 1b ff                                       BEH &0xff1b <0x4bc2>
00004caa: 3c 40 6f 64                                    CMPW %r0,&0x64
00004cae: 7f b1                                          BEB &0xb1 <0x4c5f>
00004cb0: 3c 40 6f 73                                    CMPW %r0,&0x73
00004cb4: 7e dd fe                                       BEH &0xfedd <0x4b91>
00004cb7: 3c 40 6f 78                                    CMPW %r0,&0x78
00004cbb: 7e 19 ff                                       BEH &0xff19 <0x4bd4>
00004cbe: 7b d6                                          BRB &0xd6 <0x4c94>
00004cc0: 9c 04 68                                       ADDW2 &0x4,8(%fp)
00004cc3: 70                                             NOP
00004cc4: 2b da 04                                       TSTB *4(%ap)
00004cc7: 76 30 fe                                       BNEH &0xfe30 <0x4af7>
00004cca: 04 c9 f8 4c                                    MOVAW -8(%fp),%sp
00004cce: 20 48                                          POPW %r8
00004cd0: 20 47                                          POPW %r7
00004cd2: 20 46                                          POPW %r6
00004cd4: 20 45                                          POPW %r5
00004cd6: 20 49                                          POPW %fp
00004cd8: 08                                             RET
00004cd9: 70                                             NOP
00004cda: 70                                             NOP
00004cdb: 70                                             NOP
00004cdc: 10 49                                          SAVE %fp
00004cde: 9c 4f 14 00 00 00 4c                           ADDW2 &0x14,%sp
00004ce5: 7b 06                                          BRB &0x6 <0x4ceb>
00004ce7: 90 da 00                                       INCW *0(%ap)
00004cea: 70                                             NOP
00004ceb: 84 da 00 40                                    MOVW *0(%ap),%r0
00004cef: 3f 20 50                                       CMPB &0x20,(%r0)
00004cf2: 7f 07                                          BEB &0x7 <0x4cf9>
00004cf4: 84 01 40                                       MOVW &0x1,%r0
00004cf7: 7b 04                                          BRB &0x4 <0x4cfb>
00004cf9: 80 40                                          CLRW %r0
00004cfb: 84 40 59                                       MOVW %r0,(%fp)
00004cfe: 70                                             NOP
00004cff: 84 da 00 40                                    MOVW *0(%ap),%r0
00004d03: 3f 09 50                                       CMPB &0x9,(%r0)
00004d06: 7f 07                                          BEB &0x7 <0x4d0d>
00004d08: 84 01 40                                       MOVW &0x1,%r0
00004d0b: 7b 04                                          BRB &0x4 <0x4d0f>
00004d0d: 80 40                                          CLRW %r0
00004d0f: 84 40 64                                       MOVW %r0,4(%fp)
00004d12: 70                                             NOP
00004d13: 84 da 00 40                                    MOVW *0(%ap),%r0
00004d17: 3f 2d 50                                       CMPB &0x2d,(%r0)
00004d1a: 7f 07                                          BEB &0x7 <0x4d21>
00004d1c: 84 01 40                                       MOVW &0x1,%r0
00004d1f: 7b 04                                          BRB &0x4 <0x4d23>
00004d21: 80 40                                          CLRW %r0
00004d23: 84 40 68                                       MOVW %r0,8(%fp)
00004d26: 70                                             NOP
00004d27: 84 da 00 40                                    MOVW *0(%ap),%r0
00004d2b: 3f 2c 50                                       CMPB &0x2c,(%r0)
00004d2e: 7f 07                                          BEB &0x7 <0x4d35>
00004d30: 84 01 40                                       MOVW &0x1,%r0
00004d33: 7b 04                                          BRB &0x4 <0x4d37>
00004d35: 80 40                                          CLRW %r0
00004d37: 84 40 6c                                       MOVW %r0,12(%fp)
00004d3a: 70                                             NOP
00004d3b: 84 da 00 40                                    MOVW *0(%ap),%r0
00004d3f: 2b 50                                          TSTB (%r0)
00004d41: 7f 07                                          BEB &0x7 <0x4d48>
00004d43: 84 01 40                                       MOVW &0x1,%r0
00004d46: 7b 04                                          BRB &0x4 <0x4d4a>
00004d48: 80 40                                          CLRW %r0
00004d4a: 84 40 c9 10                                    MOVW %r0,16(%fp)
00004d4e: 70                                             NOP
00004d4f: 84 da 00 40                                    MOVW *0(%ap),%r0
00004d53: 3f 3d 50                                       CMPB &0x3d,(%r0)
00004d56: 7f 07                                          BEB &0x7 <0x4d5d>
00004d58: 84 01 40                                       MOVW &0x1,%r0
00004d5b: 7b 04                                          BRB &0x4 <0x4d5f>
00004d5d: 80 40                                          CLRW %r0
00004d5f: f8 64 59 41                                    ANDW3 4(%fp),(%fp),%r1
00004d63: b8 68 41                                       ANDW2 8(%fp),%r1
00004d66: b8 6c 41                                       ANDW2 12(%fp),%r1
00004d69: b8 c9 10 41                                    ANDW2 16(%fp),%r1
00004d6d: 38 41 40                                       BITW %r1,%r0
00004d70: 76 77 ff                                       BNEH &0xff77 <0x4ce7>
00004d73: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00004d77: 20 49                                          POPW %fp
00004d79: 08                                             RET
00004d7a: 70                                             NOP
00004d7b: 70                                             NOP
00004d7c: 10 49                                          SAVE %fp
00004d7e: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00004d85: 3f 39 73                                       CMPB &0x39,3(%ap)
00004d88: 57 07                                          BGUB &0x7 <0x4d8f>
00004d8a: 84 01 40                                       MOVW &0x1,%r0
00004d8d: 7b 04                                          BRB &0x4 <0x4d91>
00004d8f: 80 40                                          CLRW %r0
00004d91: 84 40 59                                       MOVW %r0,(%fp)
00004d94: 70                                             NOP
00004d95: 3f 30 73                                       CMPB &0x30,3(%ap)
00004d98: 5b 07                                          BLUB &0x7 <0x4d9f>
00004d9a: 84 01 40                                       MOVW &0x1,%r0
00004d9d: 7b 04                                          BRB &0x4 <0x4da1>
00004d9f: 80 40                                          CLRW %r0
00004da1: 38 40 59                                       BITW %r0,(%fp)
00004da4: 7f 0c                                          BEB &0xc <0x4db0>
00004da6: ff 30 73 40                                    SUBB3 &0x30,3(%ap),%r0
00004daa: 87 40 e0 40                                    MOVB %r0,{uword}%r0
00004dae: 7b 1d                                          BRB &0x1d <0x4dcb>
00004db0: 3f 6f 61 73                                    CMPB &0x61,3(%ap)
00004db4: 5b 0d                                          BLUB &0xd <0x4dc1>
00004db6: ff 6f 57 73 40                                 SUBB3 &0x57,3(%ap),%r0
00004dbb: 87 40 e0 40                                    MOVB %r0,{uword}%r0
00004dbf: 7b 0c                                          BRB &0xc <0x4dcb>
00004dc1: ff 37 73 40                                    SUBB3 &0x37,3(%ap),%r0
00004dc5: 87 40 e0 40                                    MOVB %r0,{uword}%r0
00004dc9: 7b 02                                          BRB &0x2 <0x4dcb>
00004dcb: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00004dcf: 20 49                                          POPW %fp
00004dd1: 08                                             RET
00004dd2: 70                                             NOP
00004dd3: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'getedt' Routine
;;

00004dd4: 10 49                                          SAVE %fp
00004dd6: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
00004ddd: 87 77 e0 40                                    MOVB 7(%ap),{uword}%r0
00004de1: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004de5: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004dec: 84 40 64                                       MOVW %r0,4(%fp)
00004def: 70                                             NOP
00004df0: 80 59                                          CLRW (%fp)
00004df2: 70                                             NOP
00004df3: 7b 15                                          BRB &0x15 <0x4e08>
00004df5: 84 5a 40                                       MOVW (%ap),%r0
00004df8: 90 5a                                          INCW (%ap)
00004dfa: 70                                             NOP
00004dfb: 84 64 41                                       MOVW 4(%fp),%r1
00004dfe: 90 64                                          INCW 4(%fp)
00004e00: 70                                             NOP
00004e01: 87 51 50                                       MOVB (%r1),(%r0)
00004e04: 70                                             NOP
00004e05: 90 59                                          INCW (%fp)
00004e07: 70                                             NOP
00004e08: 3c 20 59                                       CMPW &0x20,(%fp)
00004e0b: 5b ea                                          BLUB &0xea <0x4df5>
00004e0d: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00004e11: 20 49                                          POPW %fp
00004e13: 08                                             RET
00004e14: 10 49                                          SAVE %fp
00004e16: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
00004e1d: a0 00                                          PUSHW &0x0
00004e1f: 2c cc fc af b3 03                              CALL -4(%sp),0x3b3(%pc)
00004e25: a0 4f 80 0b 00 00                              PUSHW &0xb80
00004e2b: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00004e33: 28 40                                          TSTW %r0
00004e35: 43 08                                          BGEB &0x8 <0x4e3d>
00004e37: 24 7f c0 51 00 00                              JMP $0x51c0
00004e3d: 84 ef e4 04 00 00 64                           MOVW *$0x4e4,4(%fp)
00004e44: 70                                             NOP
00004e45: a0 4f a1 0b 00 00                              PUSHW &0xba1
00004e4b: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00004e53: 28 40                                          TSTW %r0
00004e55: 43 08                                          BGEB &0x8 <0x4e5d>
00004e57: 24 7f c0 51 00 00                              JMP $0x51c0
00004e5d: 3c 4f 00 00 10 00 64                           CMPW &0x100000,4(%fp)
00004e64: 4b 26                                          BLB &0x26 <0x4e8a>
00004e66: a0 4f bc 0b 00 00                              PUSHW &0xbbc
00004e6c: d4 14 ef e4 04 00 00 40                        LRSW3 &0x14,*$0x4e4,%r0
00004e74: a0 40                                          PUSHW %r0
00004e76: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00004e7e: 28 40                                          TSTW %r0
00004e80: 43 08                                          BGEB &0x8 <0x4e88>
00004e82: 24 7f c0 51 00 00                              JMP $0x51c0
00004e88: 7b 24                                          BRB &0x24 <0x4eac>
00004e8a: a0 4f cb 0b 00 00                              PUSHW &0xbcb
00004e90: d4 0a ef e4 04 00 00 40                        LRSW3 &0xa,*$0x4e4,%r0
00004e98: a0 40                                          PUSHW %r0
00004e9a: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00004ea2: 28 40                                          TSTW %r0
00004ea4: 43 08                                          BGEB &0x8 <0x4eac>
00004ea6: 24 7f c0 51 00 00                              JMP $0x51c0
00004eac: 83 59                                          CLRB (%fp)
00004eae: 70                                             NOP
00004eaf: 24 7f a8 51 00 00                              JMP $0x51a8
00004eb5: a0 4f d8 0b 00 00                              PUSHW &0xbd8
00004ebb: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004ebf: a0 40                                          PUSHW %r0
00004ec1: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004ec5: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004ec9: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004ed0: 9c 0c 40                                       ADDW2 &0xc,%r0
00004ed3: a0 40                                          PUSHW %r0
00004ed5: 2c cc f4 7f e4 44 00 00                        CALL -12(%sp),$0x44e4
00004edd: 28 40                                          TSTW %r0
00004edf: 43 08                                          BGEB &0x8 <0x4ee7>
00004ee1: 24 7f c0 51 00 00                              JMP $0x51c0
00004ee7: a0 4f f6 0b 00 00                              PUSHW &0xbf6
00004eed: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004ef1: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004ef5: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004efc: cc 03 08 50 40                                 EXTFW &0x3,&0x8,(%r0),%r0
00004f01: a0 40                                          PUSHW %r0
00004f03: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004f07: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004f0b: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004f12: cc 03 0c 50 40                                 EXTFW &0x3,&0xc,(%r0),%r0
00004f17: a0 40                                          PUSHW %r0
00004f19: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004f1d: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004f21: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004f28: cc 0f 10 50 40                                 EXTFW &0xf,&0x10,(%r0),%r0
00004f2d: a0 40                                          PUSHW %r0
00004f2f: 2c cc f0 7f e4 44 00 00                        CALL -16(%sp),$0x44e4
00004f37: 28 40                                          TSTW %r0
00004f39: 43 08                                          BGEB &0x8 <0x4f41>
00004f3b: 24 7f c0 51 00 00                              JMP $0x51c0
00004f41: a0 4f 27 0c 00 00                              PUSHW &0xc27
00004f47: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004f4b: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004f4f: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004f56: cc 00 07 c0 04 40                              EXTFW &0x0,&0x7,4(%r0),%r0
00004f5c: 3c 00 40                                       CMPW &0x0,%r0
00004f5f: 7f 08                                          BEB &0x8 <0x4f67>
00004f61: 84 6f 79 40                                    MOVW &0x79,%r0
00004f65: 7b 06                                          BRB &0x6 <0x4f6b>
00004f67: 84 6f 6e 40                                    MOVW &0x6e,%r0
00004f6b: a0 40                                          PUSHW %r0
00004f6d: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004f71: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004f75: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004f7c: cc 00 05 c0 04 40                              EXTFW &0x0,&0x5,4(%r0),%r0
00004f82: 3c 00 40                                       CMPW &0x0,%r0
00004f85: 7f 0b                                          BEB &0xb <0x4f90>
00004f87: 84 4f 6a 0c 00 00 40                           MOVW &0xc6a,%r0
00004f8e: 7b 09                                          BRB &0x9 <0x4f97>
00004f90: 84 4f 71 0c 00 00 40                           MOVW &0xc71,%r0
00004f97: a0 40                                          PUSHW %r0
00004f99: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004f9d: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004fa1: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004fa8: cc 00 06 c0 04 40                              EXTFW &0x0,&0x6,4(%r0),%r0
00004fae: 9c 01 40                                       ADDW2 &0x1,%r0
00004fb1: a0 40                                          PUSHW %r0
00004fb3: 2c cc f0 7f e4 44 00 00                        CALL -16(%sp),$0x44e4
00004fbb: 28 40                                          TSTW %r0
00004fbd: 43 08                                          BGEB &0x8 <0x4fc5>
00004fbf: 24 7f c0 51 00 00                              JMP $0x51c0
00004fc5: a0 4f 78 0c 00 00                              PUSHW &0xc78
00004fcb: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004fcf: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004fd3: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004fda: cc 07 00 50 40                                 EXTFW &0x7,&0x0,(%r0),%r0
00004fdf: a0 40                                          PUSHW %r0
00004fe1: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00004fe5: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00004fe9: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00004ff0: cc 07 18 c0 04 40                              EXTFW &0x7,&0x18,4(%r0),%r0
00004ff6: a0 40                                          PUSHW %r0
00004ff8: 2c cc f4 7f e4 44 00 00                        CALL -12(%sp),$0x44e4
00005000: 28 40                                          TSTW %r0
00005002: 43 08                                          BGEB &0x8 <0x500a>
00005004: 24 7f c0 51 00 00                              JMP $0x51c0
0000500a: a0 4f a9 0c 00 00                              PUSHW &0xca9
00005010: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00005014: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00005018: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
0000501f: cc 00 09 c0 04 40                              EXTFW &0x0,&0x9,4(%r0),%r0
00005025: 3c 00 40                                       CMPW &0x0,%r0
00005028: 7f 08                                          BEB &0x8 <0x5030>
0000502a: 84 6f 79 40                                    MOVW &0x79,%r0
0000502e: 7b 06                                          BRB &0x6 <0x5034>
00005030: 84 6f 6e 40                                    MOVW &0x6e,%r0
00005034: a0 40                                          PUSHW %r0
00005036: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
0000503e: 28 40                                          TSTW %r0
00005040: 43 08                                          BGEB &0x8 <0x5048>
00005042: 24 7f c0 51 00 00                              JMP $0x51c0
00005048: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
0000504c: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00005050: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00005057: cc 00 09 c0 04 40                              EXTFW &0x0,&0x9,4(%r0),%r0
0000505d: 3c 00 40                                       CMPW &0x0,%r0
00005060: 7f 42                                          BEB &0x42 <0x50a2>
00005062: a0 4f be 0c 00 00                              PUSHW &0xcbe
00005068: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
0000506c: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
00005070: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00005077: cc 00 08 c0 04 40                              EXTFW &0x0,&0x8,4(%r0),%r0
0000507d: 3c 00 40                                       CMPW &0x0,%r0
00005080: 7f 08                                          BEB &0x8 <0x5088>
00005082: 84 6f 79 40                                    MOVW &0x79,%r0
00005086: 7b 06                                          BRB &0x6 <0x508c>
00005088: 84 6f 6e 40                                    MOVW &0x6e,%r0
0000508c: a0 40                                          PUSHW %r0
0000508e: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00005096: 28 40                                          TSTW %r0
00005098: 43 08                                          BGEB &0x8 <0x50a0>
0000509a: 24 7f c0 51 00 00                              JMP $0x51c0
000050a0: 7b 1a                                          BRB &0x1a <0x50ba>
000050a2: a0 4f cf 0c 00 00                              PUSHW &0xccf
000050a8: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000050b0: 28 40                                          TSTW %r0
000050b2: 43 08                                          BGEB &0x8 <0x50ba>
000050b4: 24 7f c0 51 00 00                              JMP $0x51c0
000050ba: 83 61                                          CLRB 1(%fp)
000050bc: 70                                             NOP
000050bd: 24 7f 54 51 00 00                              JMP $0x5154
000050c3: 2b 61                                          TSTB 1(%fp)
000050c5: 77 1a                                          BNEB &0x1a <0x50df>
000050c7: a0 4f df 0c 00 00                              PUSHW &0xcdf
000050cd: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000050d5: 28 40                                          TSTW %r0
000050d7: 43 08                                          BGEB &0x8 <0x50df>
000050d9: 24 7f c0 51 00 00                              JMP $0x51c0
000050df: a0 4f f2 0c 00 00                              PUSHW &0xcf2
000050e5: 87 61 e0 40                                    MOVB 1(%fp),{uword}%r0
000050e9: a4 e0 02 40                                    MODW2 {uword}&0x2,%r0
000050ed: 77 0b                                          BNEB &0xb <0x50f8>
000050ef: 84 4f 13 0d 00 00 40                           MOVW &0xd13,%r0
000050f6: 7b 09                                          BRB &0x9 <0x50ff>
000050f8: 84 4f 1a 0d 00 00 40                           MOVW &0xd1a,%r0
000050ff: a0 40                                          PUSHW %r0
00005101: 87 61 e0 40                                    MOVB 1(%fp),{uword}%r0
00005105: a0 40                                          PUSHW %r0
00005107: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
0000510b: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
0000510f: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00005116: eb 0c 61 41                                    MULB3 &0xc,1(%fp),%r1
0000511a: dc 41 c0 08 40                                 ADDW3 %r1,8(%r0),%r0
0000511f: 9c 02 40                                       ADDW2 &0x2,%r0
00005122: a0 40                                          PUSHW %r0
00005124: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00005128: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
0000512c: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
00005133: eb 0c 61 41                                    MULB3 &0xc,1(%fp),%r1
00005137: dc 41 c0 08 40                                 ADDW3 %r1,8(%r0),%r0
0000513c: 86 e2 50 e0 40                                 MOVH {uhalf}(%r0),{uword}%r0
00005141: a0 40                                          PUSHW %r0
00005143: 2c cc ec 7f e4 44 00 00                        CALL -20(%sp),$0x44e4
0000514b: 28 40                                          TSTW %r0
0000514d: 43 04                                          BGEB &0x4 <0x5151>
0000514f: 7b 71                                          BRB &0x71 <0x51c0>
00005151: 93 61                                          INCB 1(%fp)
00005153: 70                                             NOP
00005154: 87 61 e0 40                                    MOVB 1(%fp),{uword}%r0
00005158: 87 59 e0 41                                    MOVB (%fp),{uword}%r1
0000515c: d0 05 41 41                                    LLSW3 &0x5,%r1,%r1
00005160: 9c 7f 90 04 00 00 41                           ADDW2 $0x490,%r1
00005167: cc 03 00 c1 04 41                              EXTFW &0x3,&0x0,4(%r1),%r1
0000516d: 3c 41 40                                       CMPW %r1,%r0
00005170: 5a 53 ff                                       BLUH &0xff53 <0x50c3>
00005173: 87 59 e0 40                                    MOVB (%fp),{uword}%r0
00005177: ff 01 ef e0 04 00 00 41                        SUBB3 &0x1,*$0x4e0,%r1
0000517f: 3c 41 40                                       CMPW %r1,%r0
00005182: 53 23                                          BGEUB &0x23 <0x51a5>
00005184: a0 4f 1d 0d 00 00                              PUSHW &0xd1d
0000518a: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00005192: 28 40                                          TSTW %r0
00005194: 43 04                                          BGEB &0x4 <0x5198>
00005196: 7b 2a                                          BRB &0x2a <0x51c0>
00005198: 7b 02                                          BRB &0x2 <0x519a>
0000519a: 2c 5c ef c8 04 00 00                           CALL (%sp),*$0x4c8
000051a1: 28 40                                          TSTW %r0
000051a3: 7f f7                                          BEB &0xf7 <0x519a>
000051a5: 93 59                                          INCB (%fp)
000051a7: 70                                             NOP
000051a8: 3f ef e0 04 00 00 59                           CMPB *$0x4e0,(%fp)
000051af: 5a 06 fd                                       BLUH &0xfd06 <0x4eb5>
000051b2: a0 4f 3a 0d 00 00                              PUSHW &0xd3a
000051b8: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000051c0: a0 01                                          PUSHW &0x1
000051c2: 2c cc fc af 10 00                              CALL -4(%sp),0x10(%pc)
000051c8: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000051cc: 20 49                                          POPW %fp
000051ce: 08                                             RET
000051cf: 70                                             NOP
000051d0: 70                                             NOP
000051d1: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'brkinh' - Break Inhibit routine
;;

000051d2: 10 49                                          SAVE %fp
000051d4: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
000051db: 87 73 7f 68 08 00 02                           MOVB 3(%ap),$0x2000868
000051e2: 70                                             NOP
000051e3: 2b 73                                          TSTB 3(%ap)
000051e5: 77 37                                          BNEB &0x37 <0x521c>
000051e7: 7b 28                                          BRB &0x28 <0x520f>
000051e9: dc 02 7f e8 11 00 02 40                        ADDW3 &0x2,$0x20011e8,%r0
000051f1: 87 6f 40 50                                    MOVB &0x40,(%r0)
000051f5: 70                                             NOP
000051f6: dc 02 7f e8 11 00 02 40                        ADDW3 &0x2,$0x20011e8,%r0
000051fe: 87 6f 50 50                                    MOVB &0x50,(%r0)
00005202: 70                                             NOP
00005203: dc 03 7f e8 11 00 02 40                        ADDW3 &0x3,$0x20011e8,%r0
0000520b: 87 50 59                                       MOVB (%r0),(%fp)
0000520e: 70                                             NOP
0000520f: dc 01 7f e8 11 00 02 40                        ADDW3 &0x1,$0x20011e8,%r0
00005217: 3b 50 01                                       BITB (%r0),&0x1
0000521a: 77 cf                                          BNEB &0xcf <0x51e9>
0000521c: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005220: 20 49                                          POPW %fp
00005222: 08                                             RET
00005223: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'rnvram' - Routine to read NVRAM
;;
;;  (%ap) = NVRAM address to read from
;; 4(%ap) = Address to write to
;; 8(%ap) = Length

00005224: 10 48                                          SAVE %r8
00005226: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
0000522d: f8 5f 00 f0 5a 40                              ANDW3 &0xf000,(%ap),%r0
00005233: f8 5f ff 0f 5a 41                              ANDW3 &0xfff,(%ap),%r1
00005239: d0 03 41 41                                    LLSW3 &0x3,%r1,%r1
0000523d: 9c 41 40                                       ADDW2 %r1,%r0
00005240: 84 40 48                                       MOVW %r0,%r8
00005243: 7b 2a                                          BRB &0x2a <0x526d>
00005245: 84 48 40                                       MOVW %r8,%r0
00005248: 9c 04 48                                       ADDW2 &0x4,%r8
0000524b: fb 0f c0 03 40                                 ANDB3 &0xf,3(%r0),%r0
00005250: 87 40 da 04                                    MOVB %r0,*4(%ap)
00005254: 70                                             NOP
00005255: 84 74 40                                       MOVW 4(%ap),%r0
00005258: 90 74                                          INCW 4(%ap)
0000525a: 70                                             NOP
0000525b: 84 48 41                                       MOVW %r8,%r1
0000525e: 9c 04 48                                       ADDW2 &0x4,%r8
00005261: f8 0f 51 41                                    ANDW3 &0xf,(%r1),%r1
00005265: d0 04 41 41                                    LLSW3 &0x4,%r1,%r1
00005269: b3 41 50                                       ORB2 %r1,(%r0)
0000526c: 70                                             NOP
0000526d: 86 7a 40                                       MOVH 10(%ap),%r0
00005270: 96 7a                                          DECH 10(%ap)
00005272: 70                                             NOP
00005273: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
00005278: 77 cd                                          BNEB &0xcd <0x5245>
0000527a: 80 7f 70 12 00 02                              CLRW $0x2001270
00005280: 70                                             NOP
00005281: a0 7f 70 12 00 02                              PUSHW $0x2001270
00005287: 37 04                                          BSBB &0x4 <0x528b>
00005289: 7b 0b                                          BRB &0xb <0x5294>
0000528b: a0 4a                                          PUSHW %ap
0000528d: fc 0c 4c 4a                                    SUBW3 &0xc,%sp,%ap
;; Call "chknvram"
00005291: 7a 8f 00                                       BRH &0x8f <0x5320>
00005294: 7b 02                                          BRB &0x2 <0x5296>
00005296: 04 c9 ec 4c                                    MOVAW -20(%fp),%sp
0000529a: 20 48                                          POPW %r8
0000529c: 20 49                                          POPW %fp
0000529e: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'wnvram' - Routine to write NVRAM
;;

0000529f: 70                                             NOP
000052a0: 10 48                                          SAVE %r8
000052a2: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
000052a9: f8 5f 00 f0 74 40                              ANDW3 &0xf000,4(%ap),%r0
000052af: f8 5f ff 0f 74 41                              ANDW3 &0xfff,4(%ap),%r1
000052b5: d0 03 41 41                                    LLSW3 &0x3,%r1,%r1
000052b9: 9c 41 40                                       ADDW2 %r1,%r0
000052bc: 84 40 48                                       MOVW %r0,%r8
000052bf: 7b 2b                                          BRB &0x2b <0x52ea>
000052c1: 84 48 40                                       MOVW %r8,%r0
000052c4: 9c 04 48                                       ADDW2 &0x4,%r8
000052c7: fb 0f da 00 41                                 ANDB3 &0xf,*0(%ap),%r1
000052cc: 84 41 50                                       MOVW %r1,(%r0)
000052cf: 70                                             NOP
000052d0: 84 48 40                                       MOVW %r8,%r0
000052d3: 9c 04 48                                       ADDW2 &0x4,%r8
000052d6: 84 5a 41                                       MOVW (%ap),%r1
000052d9: 90 5a                                          INCW (%ap)
000052db: 70                                             NOP
000052dc: fb 5f f0 00 51 41                              ANDB3 &0xf0,(%r1),%r1
000052e2: d4 04 41 41                                    LRSW3 &0x4,%r1,%r1
000052e6: 84 41 50                                       MOVW %r1,(%r0)
000052e9: 70                                             NOP
000052ea: 86 7a 40                                       MOVH 10(%ap),%r0
000052ed: 96 7a                                          DECH 10(%ap)
000052ef: 70                                             NOP
000052f0: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
000052f5: 77 cc                                          BNEB &0xcc <0x52c1>
000052f7: 84 01 7f 70 12 00 02                           MOVW &0x1,$0x2001270
000052fe: 70                                             NOP
000052ff: a0 7f 70 12 00 02                              PUSHW $0x2001270
00005305: 37 04                                          BSBB &0x4 <0x5309>
00005307: 7b 0b                                          BRB &0xb <0x5312>
00005309: a0 4a                                          PUSHW %ap
0000530b: fc 0c 4c 4a                                    SUBW3 &0xc,%sp,%ap
0000530f: 7a 11 00                                       BRH &0x11 <0x5320>
00005312: 7b 02                                          BRB &0x2 <0x5314>
00005314: 04 c9 ec 4c                                    MOVAW -20(%fp),%sp
00005318: 20 48                                          POPW %r8
0000531a: 20 49                                          POPW %fp
0000531c: 08                                             RET
0000531d: 70                                             NOP
0000531e: 70                                             NOP
0000531f: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'chknvram' - Routine to check NVRAM
;;
;; This appears to be called only from 'rnvram' and 'wnvram'
;;

00005320: 10 47                                          SAVE %r7
00005322: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00005329: 82 48                                          CLRH %r8
0000532b: 84 4f 00 30 04 00 47                           MOVW &0x43000,%r7
00005332: 7b 40                                          BRB &0x40 <0x5372>
00005334: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00005339: 86 e2 c7 02 e0 41                              MOVH {uhalf}2(%r7),{uword}%r1
0000533f: ba 0f 41                                       ANDH2 &0xf,%r1
00005342: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00005347: 9c 41 40                                       ADDW2 %r1,%r0
0000534a: 86 40 48                                       MOVH %r0,%r8
0000534d: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00005352: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00005356: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
0000535b: 86 e2 48 e0 41                                 MOVH {uhalf}%r8,{uword}%r1
00005360: d4 0f 41 41                                    LRSW3 &0xf,%r1,%r1
00005364: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00005369: b0 41 40                                       ORW2 %r1,%r0
0000536c: 86 40 48                                       MOVH %r0,%r8
0000536f: 9c 04 47                                       ADDW2 &0x4,%r7
00005372: 3c 4f 00 38 04 00 47                           CMPW &0x43800,%r7
00005379: 5b bb                                          BLUB &0xbb <0x5334>
0000537b: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00005380: 88 40 40                                       MCOMW %r0,%r0
00005383: 86 40 48                                       MOVH %r0,%r8
00005386: 3f 01 73                                       CMPB &0x1,3(%ap)
00005389: 77 41                                          BNEB &0x41 <0x53ca>
0000538b: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
00005390: b8 0f 40                                       ANDW2 &0xf,%r0
00005393: 84 40 57                                       MOVW %r0,(%r7)
00005396: 70                                             NOP
00005397: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
0000539c: d4 04 40 40                                    LRSW3 &0x4,%r0,%r0
000053a0: b8 0f 40                                       ANDW2 &0xf,%r0
000053a3: 84 40 c7 04                                    MOVW %r0,4(%r7)
000053a7: 70                                             NOP
000053a8: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000053ad: d4 08 40 40                                    LRSW3 &0x8,%r0,%r0
000053b1: b8 0f 40                                       ANDW2 &0xf,%r0
000053b4: 84 40 c7 08                                    MOVW %r0,8(%r7)
000053b8: 70                                             NOP
000053b9: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000053be: d4 0c 40 40                                    LRSW3 &0xc,%r0,%r0
000053c2: b8 0f 40                                       ANDW2 &0xf,%r0
000053c5: 84 40 c7 0c                                    MOVW %r0,12(%r7)
000053c9: 70                                             NOP
000053ca: 86 e2 48 e0 40                                 MOVH {uhalf}%r8,{uword}%r0
000053cf: 86 e2 c7 02 e0 41                              MOVH {uhalf}2(%r7),{uword}%r1
000053d5: ba 0f 41                                       ANDH2 &0xf,%r1
000053d8: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
000053dd: f8 0f c7 04 42                                 ANDW3 &0xf,4(%r7),%r2
000053e2: d0 04 42 42                                    LLSW3 &0x4,%r2,%r2
000053e6: 86 e2 42 e0 42                                 MOVH {uhalf}%r2,{uword}%r2
000053eb: b0 42 41                                       ORW2 %r2,%r1
000053ee: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
000053f3: f8 0f c7 08 42                                 ANDW3 &0xf,8(%r7),%r2
000053f8: d0 08 42 42                                    LLSW3 &0x8,%r2,%r2
000053fc: 86 e2 42 e0 42                                 MOVH {uhalf}%r2,{uword}%r2
00005401: b0 42 41                                       ORW2 %r2,%r1
00005404: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
00005409: f8 0f c7 0c 42                                 ANDW3 &0xf,12(%r7),%r2
0000540e: d0 0c 42 42                                    LLSW3 &0xc,%r2,%r2
00005412: 86 e2 42 e0 42                                 MOVH {uhalf}%r2,{uword}%r2
00005417: b0 42 41                                       ORW2 %r2,%r1
0000541a: 86 e2 41 e0 41                                 MOVH {uhalf}%r1,{uword}%r1
0000541f: 3c 41 40                                       CMPW %r1,%r0
00005422: 77 07                                          BNEB &0x7 <0x5429>
00005424: 84 01 40                                       MOVW &0x1,%r0
00005427: 7b 06                                          BRB &0x6 <0x542d>
00005429: 80 40                                          CLRW %r0
0000542b: 7b 02                                          BRB &0x2 <0x542d>
0000542d: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00005431: 20 48                                          POPW %r8
00005433: 20 47                                          POPW %r7
00005435: 20 49                                          POPW %fp
00005437: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'bzero' - Routine to zero memory
;;

00005438: 84 5a 40                                       MOVW (%ap),%r0
0000543b: 84 74 42                                       MOVW 4(%ap),%r2
0000543e: c4 02 42 42                                    ARSW3 &0x2,%r2,%r2
00005442: 80 50                                          CLRW (%r0)
00005444: 70                                             NOP
00005445: 94 42                                          DECW %r2
00005447: 4f 08                                          BLEB &0x8 <0x544f>
00005449: 04 c0 04 41                                    MOVAW 4(%r0),%r1
0000544d: 30 19                                          MOVBLW
0000544f: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'setjmp' Routine
;;

00005450: 84 5a 40                                       MOVW (%ap),%r0
00005453: 70                                             NOP
00005454: 28 40                                          TSTW %r0
00005456: 77 09                                          BNEB &0x9 <0x545f>
00005458: 04 7f 74 12 00 02 40                           MOVAW $0x2001274,%r0
0000545f: 84 43 50                                       MOVW %r3,(%r0)
00005462: 70                                             NOP
00005463: 84 44 c0 04                                    MOVW %r4,4(%r0)
00005467: 70                                             NOP
00005468: 84 45 c0 08                                    MOVW %r5,8(%r0)
0000546c: 70                                             NOP
0000546d: 84 46 c0 0c                                    MOVW %r6,12(%r0)
00005471: 70                                             NOP
00005472: 84 47 c0 10                                    MOVW %r7,16(%r0)
00005476: 70                                             NOP
00005477: 84 48 c0 14                                    MOVW %r8,20(%r0)
0000547b: 70                                             NOP
0000547c: 84 cc fc c0 18                                 MOVW -4(%sp),24(%r0)
00005481: 70                                             NOP
00005482: 84 cc f8 c0 1c                                 MOVW -8(%sp),28(%r0)
00005487: 70                                             NOP
00005488: 84 4a c0 20                                    MOVW %ap,32(%r0)
0000548c: 70                                             NOP
0000548d: 84 49 c0 24                                    MOVW %fp,36(%r0)
00005491: 70                                             NOP
00005492: 84 cd 0c c0 28                                 MOVW 12(%pcbp),40(%r0)
00005497: 70                                             NOP
00005498: 84 cd 10 c0 2c                                 MOVW 16(%pcbp),44(%r0)
0000549d: 70                                             NOP
0000549e: 80 40                                          CLRW %r0
000054a0: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'longjmp' Routine
;;

000054a1: 84 5a 40                                       MOVW (%ap),%r0
000054a4: 70                                             NOP
000054a5: 28 40                                          TSTW %r0
000054a7: 77 09                                          BNEB &0x9 <0x54b0>
000054a9: 04 7f 74 12 00 02 40                           MOVAW $0x2001274,%r0
000054b0: 84 50 43                                       MOVW (%r0),%r3
000054b3: 84 c0 04 44                                    MOVW 4(%r0),%r4
000054b7: 84 c0 08 45                                    MOVW 8(%r0),%r5
000054bb: 84 c0 0c 46                                    MOVW 12(%r0),%r6
000054bf: 84 c0 10 47                                    MOVW 16(%r0),%r7
000054c3: 84 c0 14 48                                    MOVW 20(%r0),%r8
000054c7: 84 c0 18 4a                                    MOVW 24(%r0),%ap
000054cb: 84 c0 1c 41                                    MOVW 28(%r0),%r1
000054cf: 84 c0 20 4c                                    MOVW 32(%r0),%sp
000054d3: 84 c0 24 49                                    MOVW 36(%r0),%fp
000054d7: 84 c0 28 cd 0c                                 MOVW 40(%r0),12(%pcbp)
000054dc: 70                                             NOP
000054dd: 84 c0 2c cd 10                                 MOVW 44(%r0),16(%pcbp)
000054e2: 70                                             NOP
000054e3: 80 40                                          CLRW %r0
000054e5: 90 40                                          INCW %r0
000054e7: 24 51                                          JMP (%r1)
000054e9: 70                                             NOP
000054ea: 70                                             NOP
000054eb: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt handler inserted by the UART delay routine
;; at 0x552c.  If interrupted, put 1 into 20012a4

000054ec: 10 49                                          SAVE %fp
000054ee: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
000054f5: 87 01 7f a4 12 00 02                           MOVB &0x1,$0x20012a4
000054fc: 70                                             NOP
000054fd: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005501: 20 49                                          POPW %fp
00005503: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'hwcntr' - DUART Delay Routine
;; Vector address for this is *$0x528
;;

00005504: 10 49                                          SAVE %fp
00005506: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
0000550d: 86 e2 72 e0 40                                 MOVH {uhalf}2(%ap),{uword}%r0
00005512: a0 40                                          PUSHW %r0
00005514: a0 5f ff 08                                    PUSHW &0x8ff
00005518: 2c cc f8 af 14 00                              CALL -8(%sp),0x14(%pc)
0000551e: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
00005523: 7b 02                                          BRB &0x2 <0x5525>
00005525: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005529: 20 49                                          POPW %fp
0000552b: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Run the UART counter for a specific delay, waiting for an interrupt.
;;
;; On interrupt, transfer control to the routine pointed at by the
;; pointer held in 0x494 (i.e., 0x494 is a pointer-to-a-pointer)
;;

0000552c: 10 49                                          SAVE %fp
;; Increment stack pointer by 2 words.
0000552e: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
;; Clear the byte at 0x20012a4
00005535: 83 7f a4 12 00 02                              CLRB $0x20012a4
0000553b: 70                                             NOP
;; Move current interrupt handler to fp + 1 word
0000553c: 84 ef 94 04 00 00 64                           MOVW *$0x494,4(%fp)
00005543: 70                                             NOP
;; Set interrupt handler to 0x54ec
00005544: 84 4f ec 54 00 00 ef 94 04 00 00               MOVW &0x54ec,*$0x494
0000554f: 70                                             NOP

;; 2001254
;; R0 = (*0x2001254 | 0x30) (setting bits 5 & 6)
00005550: f3 30 7f 54 12 00 02 40                        ORB3 &0x30,$0x2001254,%r0

;; Put a word into the auxiliary control register of the UART.
;; Assuming this value is 0x30, that means we're asking the
;; counter/timer to be a counter with an external source,
;; divided by 16.
00005558: 87 40 7f 04 90 04 00                           MOVB %r0,$0x49004
0000555f: 70                                             NOP

;;
00005560: 7b 62                                          BRB &0x62 <0x55c2>
;; Stop the UART timer (read from reg 15 = "Stop Counter"
00005562: 87 7f 0f 90 04 00 59                           MOVB $0x4900f,(%fp)
00005569: 70                                             NOP

;;
;; The next block of code sets the UART counter value to 0x8ff
;;

;; Put the argument (0x8ff) into r0
0000556a: 86 e2 76 e0 40                                 MOVH {uhalf}6(%ap),{uword}%r0
;; Shift it right by 8 bits (get the high byte)
0000556f: d4 08 40 40                                    LRSW3 &0x8,%r0,%r0
;; Write it to the upper-value of the timer (it gets 0x8)
00005573: 87 40 7f 06 90 04 00                           MOVB %r0,$0x49006
0000557a: 70                                             NOP
;; Mask the lower byte of the timer (0xff)
0000557b: fb 5f ff 00 77 40                              ANDB3 &0xff,7(%ap),%r0
;; Write it to the lower-value of the timer
00005581: 87 40 7f 07 90 04 00                           MOVB %r0,$0x49007
00005588: 70                                             NOP
;; Start the timer again (write to register 14 = "Start Counter")
00005589: 87 7f 0e 90 04 00 59                           MOVB $0x4900e,(%fp)
00005590: 70                                             NOP
;; Go off to check the timer interrupt status
00005591: 7b 28                                          BRB &0x28 <0x55b9>

;; Jump point. Calls our mysterious timer / soft power inhibit routine 0x62de
00005593: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
;; Set Z and N based on contents of 0x20012a4
0000559a: 2b 7f a4 12 00 02                              TSTB $0x20012a4
;; If 20012a4 == 0, jump to 0x55b9
000055a0: 7f 19                                          BEB &0x19 <0x55b9>
;; On the other hand, if it's not 0, start the counter
000055a2: 87 7f 0f 90 04 00 59                           MOVB $0x4900f,(%fp)
000055a9: 70                                             NOP
;; Write the new interrupt handler
000055aa: 84 64 ef 94 04 00 00                           MOVW 4(%fp),*$0x494
000055b1: 70                                             NOP
;; Store the argument into R0
000055b2: 86 e2 72 e0 40                                 MOVH {uhalf}2(%ap),{uword}%r0
;; Branch to 0x55e3 and return.
000055b7: 7b 2c                                          BRB &0x2c <0x55e3>

;; See if bit 3 ("Counter Ready") is set in the UART's interrupt
;; status register.
000055b9: 3b 7f 05 90 04 00 08                           BITB $0x49005,&0x8

;; If it isn't, jump back to 0x5593
000055c0: 7f d3                                          BEB &0xd3 <0x5593>

;; If it's not, it means the timer is expired....
000055c2: 86 72 40                                       MOVH 2(%ap),%r0
000055c5: 96 72                                          DECH 2(%ap)
000055c7: 70                                             NOP
;; Check the value of R0.
000055c8: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
;; If R0 != 0, jump back to 5562
000055cd: 77 95                                          BNEB &0x95 <0x5562>
;; On the other hand, if R0 == 0, we return.
000055cf: 87 7f 0f 90 04 00 59                           MOVB $0x4900f,(%fp)
000055d6: 70                                             NOP
000055d7: 84 64 ef 94 04 00 00                           MOVW 4(%fp),*$0x494
000055de: 70                                             NOP
000055df: 80 40                                          CLRW %r0
000055e1: 7b 02                                          BRB &0x2 <0x55e3>
000055e3: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000055e7: 20 49                                          POPW %fp
000055e9: 08                                             RET
000055ea: 70                                             NOP
000055eb: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'fw_sysgen' - Generic 'sysgen' routine
;;

000055ec: 10 49                                          SAVE %fp
000055ee: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
000055f5: 83 64                                          CLRB 4(%fp)
000055f7: 70                                             NOP
;; Store the current interrupt handling routine in $0x20012c8
000055f8: 84 ef 94 04 00 00 7f c8 12 00 02               MOVW *$0x494,$0x20012c8
00005603: 70                                             NOP
;; Install a new interrupt handling routine (0x5d00)
00005604: 84 4f 00 5d 00 00 ef 94 04 00 00               MOVW &0x5d00,*$0x494
0000560f: 70                                             NOP
00005610: 70                                             NOP
;; Save the current IPL in 0x20012c4
00005611: cc 03 0d 4b 7f c4 12 00 02                     EXTFW &0x3,&0xd,%psw,$0x20012c4
0000561a: 70                                             NOP
;; Set our IPL to 15 (NO INTERRUPTS)
0000561b: c8 03 0d 0f 4b                                 INSFW &0x3,&0xd,&0xf,%psw

;; Set the sysgen block pointer to 0x20012b8
00005620: 84 4f b8 12 00 02 7f 00 00 00 02               MOVW &0x20012b8,$0x2000000
0000562b: 70                                             NOP

;; We create a sysgen block with:
;;   1. Request Queue at 0x20037f4
;;   2. Completion Queue at 0x20037ec
;;   3. Request Queue size of 2
;;   4. Completion Queue size of 2
;;   5. Interrupt Vector of 1
0000562c: 84 4f f4 37 00 02 7f b8 12 00 02               MOVW &0x20037f4,$0x20012b8
00005637: 70                                             NOP
00005638: 84 4f ec 37 00 02 7f bc 12 00 02               MOVW &0x20037ec,$0x20012bc
00005643: 70                                             NOP
00005644: 87 02 7f c0 12 00 02                           MOVB &0x2,$0x20012c0
0000564b: 70                                             NOP
0000564c: 87 02 7f c1 12 00 02                           MOVB &0x2,$0x20012c1
00005653: 70                                             NOP
00005654: 87 01 7f c3 12 00 02                           MOVB &0x1,$0x20012c3
0000565b: 70                                             NOP

;; Call 'bzero' to zero 0x814 bytes of RAM starting at 0x20037ec (completion queue)
0000565c: a0 4f ec 37 00 02                              PUSHW &0x20037ec
00005662: a0 5f 14 08                                    PUSHW &0x814
00005666: 2c cc f8 ef 18 05 00 00                        CALL -8(%sp),*$0x518

;; Call 'hwcntr' with a delay of 0x14.
0000566e: a0 14                                          PUSHW &0x14
00005670: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528


00005678: d0 15 5a 40                                    LLSW3 &0x15,(%ap),%r0
0000567c: 87 c0 01 e0 59                                 MOVB 1(%r0),{uword}(%fp)
00005681: 70                                             NOP
;; Call hwcntr with a delay of 0x14. 
00005682: a0 14                                          PUSHW &0x14
00005684: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
0000568c: d0 15 5a 40                                    LLSW3 &0x15,(%ap),%r0
00005690: 87 c0 03 e0 59                                 MOVB 3(%r0),{uword}(%fp)
00005695: 70                                             NOP
00005696: 80 59                                          CLRW (%fp)
00005698: 70                                             NOP
00005699: 7b 1e                                          BRB &0x1e <0x56b7>
0000569b: 3f 03 7f ef 37 00 02                           CMPB &0x3,$0x20037ef
000056a2: 77 08                                          BNEB &0x8 <0x56aa>
000056a4: 87 01 64                                       MOVB &0x1,4(%fp)
000056a7: 70                                             NOP
000056a8: 7b 15                                          BRB &0x15 <0x56bd>
;; Call hwcntr with a delay of 0x1 
000056aa: a0 01                                          PUSHW &0x1
000056ac: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
000056b4: 90 59                                          INCW (%fp)
000056b6: 70                                             NOP
000056b7: 3c 6f 64 59                                    CMPW &0x64,(%fp)
000056bb: 5b e0                                          BLUB &0xe0 <0x569b>
000056bd: 3c 6f 64 59                                    CMPW &0x64,(%fp)
000056c1: 5b 1b                                          BLUB &0x1b <0x56dc>
000056c3: d0 15 5a 40                                    LLSW3 &0x15,(%ap),%r0
000056c7: 87 01 c0 05                                    MOVB &0x1,5(%r0)
000056cb: 70                                             NOP
;; Call hwcntr with a delay of 0x14
000056cc: a0 14                                          PUSHW &0x14
000056ce: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
000056d6: 87 64 e0 40                                    MOVB 4(%fp),{uword}%r0
000056da: 7b 15                                          BRB &0x15 <0x56ef>
;; Call the error printing routine.
000056dc: 2c 5c af 62 06                                 CALL (%sp),0x662(%pc)
000056e1: 3c 01 40                                       CMPW &0x1,%r0
000056e4: 7f 05                                          BEB &0x5 <0x56e9>
000056e6: 83 64                                          CLRB 4(%fp)
000056e8: 70                                             NOP
000056e9: 87 64 e0 40                                    MOVB 4(%fp),{uword}%r0
000056ed: 7b 02                                          BRB &0x2 <0x56ef>
000056ef: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000056f3: 20 49                                          POPW %fp
000056f5: 08                                             RET
000056f6: 70                                             NOP
000056f7: 70                                             NOP


000056f8: 10 49                                          SAVE %fp
000056fa: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00005701: 84 ef 94 04 00 00 7f c8 12 00 02               MOVW *$0x494,$0x20012c8
0000570c: 70                                             NOP
0000570d: 84 4f 00 5d 00 00 ef 94 04 00 00               MOVW &0x5d00,*$0x494
00005718: 70                                             NOP
00005719: 70                                             NOP
0000571a: cc 03 0d 4b 7f c4 12 00 02                     EXTFW &0x3,&0xd,%psw,$0x20012c4
00005723: 70                                             NOP
00005724: c8 03 0d 0f 4b                                 INSFW &0x3,&0xd,&0xf,%psw
00005729: 87 08 7f f7 37 00 02                           MOVB &0x8,$0x20037f7
00005730: 70                                             NOP
00005731: 3f 01 73                                       CMPB &0x1,3(%ap)
00005734: 77 18                                          BNEB &0x18 <0x574c>
00005736: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
0000573e: f3 20 50 40                                    ORB3 &0x20,(%r0),%r0
00005742: 87 40 7f f6 37 00 02                           MOVB %r0,$0x20037f6
00005749: 70                                             NOP
0000574a: 7b 19                                          BRB &0x19 <0x5763>
0000574c: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00005754: 87 50 7f f6 37 00 02                           MOVB (%r0),$0x20037f6
0000575b: 70                                             NOP
0000575c: 87 7f f6 37 00 02 40                           MOVB $0x20037f6,%r0
00005763: 87 7f 68 08 00 02 e0 7f f8 37 00 02            MOVB $0x2000868,{uword}$0x20037f8
0000576f: 70                                             NOP
00005770: 87 5f ff 00 7f ef 37 00 02                     MOVB &0xff,$0x20037ef
00005779: 70                                             NOP
0000577a: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00005782: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
00005786: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
0000578a: 87 c0 01 e2 40                                 MOVB 1(%r0),{uhalf}%r0
0000578f: 86 40 59                                       MOVH %r0,(%fp)
00005792: 70                                             NOP
00005793: 82 59                                          CLRH (%fp)
00005795: 70                                             NOP
00005796: 24 7f 56 58 00 00                              JMP $0x5856
0000579c: a0 01                                          PUSHW &0x1
0000579e: a0 5f e6 00                                    PUSHW &0xe6
000057a2: 2c cc f8 7f 2c 55 00 00                        CALL -8(%sp),$0x552c
000057aa: 3f 5f ff 00 7f ef 37 00 02                     CMPB &0xff,$0x20037ef
000057b3: 7f 6a                                          BEB &0x6a <0x581d>
000057b5: 2b 7f ef 37 00 02                              TSTB $0x20037ef
000057bb: 77 4c                                          BNEB &0x4c <0x5807>
000057bd: 2c 5c af 81 05                                 CALL (%sp),0x581(%pc)
000057c2: 3c 01 40                                       CMPW &0x1,%r0
000057c5: 7f 18                                          BEB &0x18 <0x57dd>
000057c7: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
000057d2: 70                                             NOP
000057d3: 87 01 7f 0b 40 04 00                           MOVB &0x1,$0x4400b
000057da: 70                                             NOP
000057db: 7b 00                                          BRB &0x0 <0x57db>
000057dd: 86 e2 7f ec 37 00 02 e0 40                     MOVH {uhalf}$0x20037ec,{uword}%r0
000057e6: ba 5f ff 00 40                                 ANDH2 &0xff,%r0
000057eb: 86 40 62                                       MOVH %r0,2(%fp)
000057ee: 70                                             NOP
000057ef: 86 e2 62 e0 40                                 MOVH {uhalf}2(%fp),{uword}%r0
000057f4: 3c 5f ff 00 40                                 CMPW &0xff,%r0
000057f9: 77 07                                          BNEB &0x7 <0x5800>
000057fb: 84 ff 40                                       MOVW &-1,%r0
000057fe: 7b 07                                          BRB &0x7 <0x5805>
00005800: 86 e2 62 e0 40                                 MOVH {uhalf}2(%fp),{uword}%r0
00005805: 7b 5d                                          BRB &0x5d <0x5862>
00005807: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00005812: 70                                             NOP
00005813: 87 01 7f 0b 40 04 00                           MOVB &0x1,$0x4400b
0000581a: 70                                             NOP
0000581b: 7b 00                                          BRB &0x0 <0x581b>
0000581d: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00005822: 3c 6f 64 40                                    CMPW &0x64,%r0
00005826: 5b 1f                                          BLUB &0x1f <0x5845>
00005828: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
0000582f: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
0000583a: 70                                             NOP
0000583b: 87 01 7f 0b 40 04 00                           MOVB &0x1,$0x4400b
00005842: 70                                             NOP
00005843: 7b 00                                          BRB &0x0 <0x5843>
00005845: 3f 01 73                                       CMPB &0x1,3(%ap)
00005848: 77 07                                          BNEB &0x7 <0x584f>
0000584a: 92 59                                          INCH (%fp)
0000584c: 70                                             NOP
0000584d: 7b 09                                          BRB &0x9 <0x5856>
0000584f: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00005856: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
0000585b: 3c 6f 64 40                                    CMPW &0x64,%r0
0000585f: 5a 3d ff                                       BLUH &0xff3d <0x579c>
00005862: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005866: 20 49                                          POPW %fp
00005868: 08                                             RET
00005869: 70                                             NOP


0000586a: 10 49                                          SAVE %fp
0000586c: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00005873: 84 ef 94 04 00 00 7f c8 12 00 02               MOVW *$0x494,$0x20012c8
0000587e: 70                                             NOP
0000587f: 84 4f 00 5d 00 00 ef 94 04 00 00               MOVW &0x5d00,*$0x494
0000588a: 70                                             NOP
0000588b: 70                                             NOP
0000588c: cc 03 0d 4b 7f c4 12 00 02                     EXTFW &0x3,&0xd,%psw,$0x20012c4
00005895: 70                                             NOP
00005896: c8 03 0d 0f 4b                                 INSFW &0x3,&0xd,&0xf,%psw
0000589b: 87 09 7f f7 37 00 02                           MOVB &0x9,$0x20037f7
000058a2: 70                                             NOP
000058a3: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
000058ab: 87 50 7f f6 37 00 02                           MOVB (%r0),$0x20037f6
000058b2: 70                                             NOP
000058b3: 87 73 e2 40                                    MOVB 3(%ap),{uhalf}%r0
000058b7: 86 40 7f f4 37 00 02                           MOVH %r0,$0x20037f4
000058be: 70                                             NOP
000058bf: 87 5f ff 00 7f ef 37 00 02                     MOVB &0xff,$0x20037ef
000058c8: 70                                             NOP
000058c9: 87 7f 68 08 00 02 e0 7f f8 37 00 02            MOVB $0x2000868,{uword}$0x20037f8
000058d5: 70                                             NOP
000058d6: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
000058de: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
000058e2: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
000058e6: 87 c0 01 e2 40                                 MOVB 1(%r0),{uhalf}%r0
000058eb: 86 40 59                                       MOVH %r0,(%fp)
000058ee: 70                                             NOP
000058ef: 82 59                                          CLRH (%fp)
000058f1: 70                                             NOP
000058f2: 24 7f b2 59 00 00                              JMP $0x59b2
000058f8: a0 01                                          PUSHW &0x1
000058fa: a0 5f e6 00                                    PUSHW &0xe6
000058fe: 2c cc f8 7f 2c 55 00 00                        CALL -8(%sp),$0x552c
00005906: 3f 5f ff 00 7f ef 37 00 02                     CMPB &0xff,$0x20037ef
0000590f: 7f 78                                          BEB &0x78 <0x5987>
00005911: 2b 7f ef 37 00 02                              TSTB $0x20037ef
00005917: 77 53                                          BNEB &0x53 <0x596a>
00005919: 2c 5c af 25 04                                 CALL (%sp),0x425(%pc)
0000591e: 3c 01 40                                       CMPW &0x1,%r0
00005921: 7f 1f                                          BEB &0x1f <0x5940>
00005923: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
0000592a: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00005935: 70                                             NOP
00005936: 87 01 7f 0b 40 04 00                           MOVB &0x1,$0x4400b
0000593d: 70                                             NOP
0000593e: 7b 00                                          BRB &0x0 <0x593e>
00005940: 86 e2 7f ec 37 00 02 e0 40                     MOVH {uhalf}$0x20037ec,{uword}%r0
00005949: ba 5f ff 00 40                                 ANDH2 &0xff,%r0
0000594e: 86 40 62                                       MOVH %r0,2(%fp)
00005951: 70                                             NOP
00005952: 86 e2 62 e0 40                                 MOVH {uhalf}2(%fp),{uword}%r0
00005957: 3c 5f ff 00 40                                 CMPW &0xff,%r0
0000595c: 77 07                                          BNEB &0x7 <0x5963>
0000595e: 84 ff 40                                       MOVW &-1,%r0
00005961: 7b 07                                          BRB &0x7 <0x5968>
00005963: 86 e2 62 e0 40                                 MOVH {uhalf}2(%fp),{uword}%r0
00005968: 7b 56                                          BRB &0x56 <0x59be>
0000596a: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00005971: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
0000597c: 70                                             NOP
0000597d: 87 01 7f 0b 40 04 00                           MOVB &0x1,$0x4400b
00005984: 70                                             NOP
00005985: 7b 00                                          BRB &0x0 <0x5985>
00005987: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
0000598c: 3c 6f 64 40                                    CMPW &0x64,%r0
00005990: 5b 1f                                          BLUB &0x1f <0x59af>
00005992: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00005999: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
000059a4: 70                                             NOP
000059a5: 87 01 7f 0b 40 04 00                           MOVB &0x1,$0x4400b
000059ac: 70                                             NOP
000059ad: 7b 00                                          BRB &0x0 <0x59ad>
000059af: 92 59                                          INCH (%fp)
000059b1: 70                                             NOP
000059b2: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
000059b7: 3c 6f 64 40                                    CMPW &0x64,%r0
000059bb: 5a 3d ff                                       BLUH &0xff3d <0x58f8>
000059be: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000059c2: 20 49                                          POPW %fp
000059c4: 08                                             RET
000059c5: 70                                             NOP


000059c6: 10 49                                          SAVE %fp
000059c8: 9c 4f 10 00 00 00 4c                           ADDW2 &0x10,%sp
000059cf: 83 64                                          CLRB 4(%fp)
000059d1: 70                                             NOP
000059d2: 84 ef 94 04 00 00 7f c8 12 00 02               MOVW *$0x494,$0x20012c8
000059dd: 70                                             NOP
000059de: 84 4f 00 5d 00 00 ef 94 04 00 00               MOVW &0x5d00,*$0x494
000059e9: 70                                             NOP
000059ea: 70                                             NOP
000059eb: cc 03 0d 4b 7f c4 12 00 02                     EXTFW &0x3,&0xd,%psw,$0x20012c4
000059f4: 70                                             NOP
000059f5: c8 03 0d 0f 4b                                 INSFW &0x3,&0xd,&0xf,%psw
000059fa: 87 07 7f f7 37 00 02                           MOVB &0x7,$0x20037f7
00005a01: 70                                             NOP
00005a02: 87 77 7f f6 37 00 02                           MOVB 7(%ap),$0x20037f6
00005a09: 70                                             NOP
00005a0a: 87 5f ff 00 7f ef 37 00 02                     MOVB &0xff,$0x20037ef
00005a13: 70                                             NOP
00005a14: 04 68 7f f8 37 00 02                           MOVAW 8(%fp),$0x20037f8
00005a1b: 70                                             NOP
00005a1c: 86 ef a4 04 00 00 68                           MOVH *$0x4a4,8(%fp)
00005a23: 70                                             NOP
00005a24: 83 6c                                          CLRB 12(%fp)
00005a26: 70                                             NOP
00005a27: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00005a2b: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00005a2f: 87 c0 01 e0 59                                 MOVB 1(%r0),{uword}(%fp)
00005a34: 70                                             NOP
00005a35: 80 59                                          CLRW (%fp)
00005a37: 70                                             NOP
00005a38: 7b 5d                                          BRB &0x5d <0x5a95>
00005a3a: a0 01                                          PUSHW &0x1
00005a3c: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00005a44: 2b 7f ef 37 00 02                              TSTB $0x20037ef
00005a4a: 77 28                                          BNEB &0x28 <0x5a72>
00005a4c: 87 01 64                                       MOVB &0x1,4(%fp)
00005a4f: 70                                             NOP
00005a50: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00005a58: 87 6b 50                                       MOVB 11(%fp),(%r0)
00005a5b: 70                                             NOP
00005a5c: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
00005a64: 87 01 50                                       MOVB &0x1,(%r0)
00005a67: 70                                             NOP
00005a68: 86 68 ef a4 04 00 00                           MOVH 8(%fp),*$0x4a4
00005a6f: 70                                             NOP
00005a70: 7b 2b                                          BRB &0x2b <0x5a9b>
00005a72: 3c 6f 64 59                                    CMPW &0x64,(%fp)
00005a76: 5b 1c                                          BLUB &0x1c <0x5a92>
00005a78: 83 64                                          CLRB 4(%fp)
00005a7a: 70                                             NOP
00005a7b: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00005a7f: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00005a83: 87 01 c0 05                                    MOVB &0x1,5(%r0)
00005a87: 70                                             NOP
00005a88: a0 14                                          PUSHW &0x14
00005a8a: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00005a92: 90 59                                          INCW (%fp)
00005a94: 70                                             NOP
00005a95: 3c 6f 64 59                                    CMPW &0x64,(%fp)
00005a99: 5b a1                                          BLUB &0xa1 <0x5a3a>
00005a9b: 2c 5c af a3 02                                 CALL (%sp),0x2a3(%pc)
00005aa0: 3c 01 40                                       CMPW &0x1,%r0
00005aa3: 7f 1c                                          BEB &0x1c <0x5abf>
00005aa5: 83 64                                          CLRB 4(%fp)
00005aa7: 70                                             NOP
00005aa8: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00005aac: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00005ab0: 87 01 c0 05                                    MOVB &0x1,5(%r0)
00005ab4: 70                                             NOP
00005ab5: a0 14                                          PUSHW &0x14
00005ab7: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00005abf: 87 64 e0 40                                    MOVB 4(%fp),{uword}%r0
00005ac3: 7b 02                                          BRB &0x2 <0x5ac5>
00005ac5: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005ac9: 20 49                                          POPW %fp
00005acb: 08                                             RET
00005acc: 70                                             NOP
00005acd: 70                                             NOP


00005ace: 10 49                                          SAVE %fp
00005ad0: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
00005ad7: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00005adb: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00005adf: 87 01 c0 05                                    MOVB &0x1,5(%r0)
00005ae3: 70                                             NOP
00005ae4: a0 14                                          PUSHW &0x14
00005ae6: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00005aee: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00005af2: a0 40                                          PUSHW %r0
00005af4: 2c cc fc af f8 fa                              CALL -4(%sp),0x..faf8(%pc)
00005afa: 28 40                                          TSTW %r0
00005afc: 77 0a                                          BNEB &0xa <0x5b06>
00005afe: 80 40                                          CLRW %r0
00005b00: 24 7f a3 5b 00 00                              JMP $0x5ba3
00005b06: 84 ef 94 04 00 00 7f c8 12 00 02               MOVW *$0x494,$0x20012c8
00005b11: 70                                             NOP
00005b12: 84 4f 00 5d 00 00 ef 94 04 00 00               MOVW &0x5d00,*$0x494
00005b1d: 70                                             NOP
00005b1e: 70                                             NOP
00005b1f: cc 03 0d 4b 7f c4 12 00 02                     EXTFW &0x3,&0xd,%psw,$0x20012c4
00005b28: 70                                             NOP
00005b29: c8 03 0d 0f 4b                                 INSFW &0x3,&0xd,&0xf,%psw
00005b2e: 87 0a 7f f7 37 00 02                           MOVB &0xa,$0x20037f7
00005b35: 70                                             NOP
00005b36: 87 77 7f f6 37 00 02                           MOVB 7(%ap),$0x20037f6
00005b3d: 70                                             NOP
00005b3e: 87 5f ff 00 7f ef 37 00 02                     MOVB &0xff,$0x20037ef
00005b47: 70                                             NOP
00005b48: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00005b4c: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00005b50: 87 c0 01 e0 64                                 MOVB 1(%r0),{uword}4(%fp)
00005b55: 70                                             NOP
00005b56: 80 64                                          CLRW 4(%fp)
00005b58: 70                                             NOP
00005b59: 7b 31                                          BRB &0x31 <0x5b8a>
00005b5b: a0 01                                          PUSHW &0x1
00005b5d: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00005b65: 3f 5f ff 00 7f ef 37 00 02                     CMPB &0xff,$0x20037ef
00005b6e: 7f 19                                          BEB &0x19 <0x5b87>
00005b70: 2b 7f ef 37 00 02                              TSTB $0x20037ef
00005b76: 77 0c                                          BNEB &0xc <0x5b82>
00005b78: 84 7f f0 37 00 02 59                           MOVW $0x20037f0,(%fp)
00005b7f: 70                                             NOP
00005b80: 7b 11                                          BRB &0x11 <0x5b91>
00005b82: 80 59                                          CLRW (%fp)
00005b84: 70                                             NOP
00005b85: 7b 0c                                          BRB &0xc <0x5b91>
00005b87: 90 64                                          INCW 4(%fp)
00005b89: 70                                             NOP
00005b8a: 3c 5f 30 75 64                                 CMPW &0x7530,4(%fp)
00005b8f: 4b cc                                          BLB &0xcc <0x5b5b>
00005b91: 2c 5c af ad 01                                 CALL (%sp),0x1ad(%pc)
00005b96: 28 40                                          TSTW %r0
00005b98: 7f 07                                          BEB &0x7 <0x5b9f>
00005b9a: 84 59 40                                       MOVW (%fp),%r0
00005b9d: 7b 06                                          BRB &0x6 <0x5ba3>
00005b9f: 80 40                                          CLRW %r0
00005ba1: 7b 02                                          BRB &0x2 <0x5ba3>
00005ba3: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005ba7: 20 49                                          POPW %fp
00005ba9: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'ioblk_acs' Routine
;;

00005baa: 10 49                                          SAVE %fp
00005bac: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
00005bb3: 70                                             NOP
00005bb4: cc 03 0d 4b 7f c4 12 00 02                     EXTFW &0x3,&0xd,%psw,$0x20012c4
00005bbd: 70                                             NOP
00005bbe: c8 03 0d 0f 4b                                 INSFW &0x3,&0xd,&0xf,%psw
00005bc3: 84 ef 94 04 00 00 7f c8 12 00 02               MOVW *$0x494,$0x20012c8
00005bce: 70                                             NOP
00005bcf: 84 4f 00 5d 00 00 ef 94 04 00 00               MOVW &0x5d00,*$0x494
00005bda: 70                                             NOP
00005bdb: 83 59                                          CLRB (%fp)
00005bdd: 70                                             NOP
00005bde: 84 74 7f b0 12 00 02                           MOVW 4(%ap),$0x20012b0
00005be5: 70                                             NOP
00005be6: 84 78 7f b4 12 00 02                           MOVW 8(%ap),$0x20012b4
00005bed: 70                                             NOP
00005bee: 3f 01 ca 0f                                    CMPB &0x1,15(%ap)
00005bf2: 77 0c                                          BNEB &0xc <0x5bfe>
00005bf4: 87 0c 7f f7 37 00 02                           MOVB &0xc,$0x20037f7
00005bfb: 70                                             NOP
00005bfc: 7b 2f                                          BRB &0x2f <0x5c2b>
00005bfe: 2b ca 0f                                       TSTB 15(%ap)
00005c01: 77 0c                                          BNEB &0xc <0x5c0d>
00005c03: 87 0b 7f f7 37 00 02                           MOVB &0xb,$0x20037f7
00005c0a: 70                                             NOP
00005c0b: 7b 20                                          BRB &0x20 <0x5c2b>
00005c0d: 84 7f c8 12 00 02 ef 94 04 00 00               MOVW $0x20012c8,*$0x494
00005c18: 70                                             NOP
00005c19: c8 03 0d 7f c4 12 00 02 4b                     INSFW &0x3,&0xd,$0x20012c4,%psw
00005c22: 84 00 40                                       MOVW &0x0,%r0
00005c25: 24 7f f9 5c 00 00                              JMP $0x5cf9
00005c2b: fb 5f f0 00 73 40                              ANDB3 &0xf0,3(%ap),%r0
00005c31: d4 04 40 40                                    LRSW3 &0x4,%r0,%r0
00005c35: 87 40 62                                       MOVB %r0,2(%fp)
00005c38: 70                                             NOP
00005c39: 2b 62                                          TSTB 2(%fp)
00005c3b: 77 0a                                          BNEB &0xa <0x5c45>
00005c3d: 80 40                                          CLRW %r0
00005c3f: 24 7f f9 5c 00 00                              JMP $0x5cf9
00005c45: fb 0f 73 40                                    ANDB3 &0xf,3(%ap),%r0
00005c49: 87 40 61                                       MOVB %r0,1(%fp)
00005c4c: 70                                             NOP
00005c4d: 87 61 7f f6 37 00 02                           MOVB 1(%fp),$0x20037f6
00005c54: 70                                             NOP
00005c55: 84 4f b0 12 00 02 7f f8 37 00 02               MOVW &0x20012b0,$0x20037f8
00005c60: 70                                             NOP
00005c61: 87 5f ff 00 7f ef 37 00 02                     MOVB &0xff,$0x20037ef
00005c6a: 70                                             NOP
00005c6b: 87 62 e0 40                                    MOVB 2(%fp),{uword}%r0
00005c6f: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00005c73: 87 c0 01 e0 64                                 MOVB 1(%r0),{uword}4(%fp)
00005c78: 70                                             NOP
00005c79: 80 64                                          CLRW 4(%fp)
00005c7b: 70                                             NOP
00005c7c: 7b 2d                                          BRB &0x2d <0x5ca9>
00005c7e: a0 01                                          PUSHW &0x1
00005c80: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00005c88: 3f 5f ff 00 7f ef 37 00 02                     CMPB &0xff,$0x20037ef
00005c91: 7f 15                                          BEB &0x15 <0x5ca6>
00005c93: 2b 7f ef 37 00 02                              TSTB $0x20037ef
00005c99: 77 08                                          BNEB &0x8 <0x5ca1>
00005c9b: 87 01 59                                       MOVB &0x1,(%fp)
00005c9e: 70                                             NOP
00005c9f: 7b 11                                          BRB &0x11 <0x5cb0>
00005ca1: 83 59                                          CLRB (%fp)
00005ca3: 70                                             NOP
00005ca4: 7b 0c                                          BRB &0xc <0x5cb0>
00005ca6: 90 64                                          INCW 4(%fp)
00005ca8: 70                                             NOP
00005ca9: 3c 5f 28 23 64                                 CMPW &0x2328,4(%fp)
00005cae: 4b d0                                          BLB &0xd0 <0x5c7e>
00005cb0: 2c 5c af 8e 00                                 CALL (%sp),0x8e(%pc)
00005cb5: 28 40                                          TSTW %r0
00005cb7: 7f 06                                          BEB &0x6 <0x5cbd>
00005cb9: 2b 59                                          TSTB (%fp)
00005cbb: 77 39                                          BNEB &0x39 <0x5cf4>
00005cbd: a0 4f 44 0d 00 00                              PUSHW &0xd44
00005cc3: 2b ca 0f                                       TSTB 15(%ap)
00005cc6: 77 0b                                          BNEB &0xb <0x5cd1>
00005cc8: 84 4f 80 0d 00 00 40                           MOVW &0xd80,%r0
00005ccf: 7b 09                                          BRB &0x9 <0x5cd8>
00005cd1: 84 4f 85 0d 00 00 40                           MOVW &0xd85,%r0
00005cd8: a0 40                                          PUSHW %r0
00005cda: a0 74                                          PUSHW 4(%ap)
00005cdc: 87 61 e0 40                                    MOVB 1(%fp),{uword}%r0
00005ce0: a0 40                                          PUSHW %r0
00005ce2: 87 62 e0 40                                    MOVB 2(%fp),{uword}%r0
00005ce6: a0 40                                          PUSHW %r0
00005ce8: 2c cc ec 7f e4 44 00 00                        CALL -20(%sp),$0x44e4
00005cf0: 80 40                                          CLRW %r0
00005cf2: 7b 07                                          BRB &0x7 <0x5cf9>
00005cf4: 84 01 40                                       MOVW &0x1,%r0
00005cf7: 7b 02                                          BRB &0x2 <0x5cf9>
00005cf9: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005cfd: 20 49                                          POPW %fp
00005cff: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt handler used during sysgen
;; 
;;
00005d00: 10 49                                          SAVE %fp
00005d02: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00005d09: c8 03 0d 0f 4b                                 INSFW &0x3,&0xd,&0xf,%psw
00005d0e: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
;; Read the CSR
00005d15: 86 e2 7f 02 40 04 00 e0 40                     MOVH {uhalf}$0x44002,{uword}%r0
;; Mask bits 0x8000 and 0x0001 (check for CSRTIMO and CSRIOF)
00005d1e: 38 40 6f 7e                                    BITW %r0,&0x7e
00005d22: 7f 0c                                          BEB &0xc <0x5d2e>
00005d24: 86 01 7f ce 12 00 02                           MOVH &0x1,$0x20012ce
00005d2b: 70                                             NOP
00005d2c: 7b 09                                          BRB &0x9 <0x5d35>
00005d2e: 82 7f cc 12 00 02                              CLRH $0x20012cc
00005d34: 70                                             NOP
00005d35: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005d39: 20 49                                          POPW %fp
00005d3b: 08                                             RET
00005d3c: 70                                             NOP
00005d3d: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Routine that appears to print error messages during sysgen.
;; Called by: 0x56DC (fw_sysgen)
00005d3e: 10 49                                          SAVE %fp
00005d40: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00005d47: 86 01 7f cc 12 00 02                           MOVH &0x1,$0x20012cc
00005d4e: 70                                             NOP
00005d4f: 80 59                                          CLRW (%fp)
00005d51: 70                                             NOP
00005d52: 82 7f ce 12 00 02                              CLRH $0x20012ce
00005d58: 70                                             NOP
00005d59: c8 03 0d 00 4b                                 INSFW &0x3,&0xd,&0x0,%psw
00005d5e: 70                                             NOP
00005d5f: 70                                             NOP
00005d60: 70                                             NOP
00005d61: 70                                             NOP
00005d62: c8 03 0d 0f 4b                                 INSFW &0x3,&0xd,&0xf,%psw
00005d67: 86 e2 7f cc 12 00 02 e0 40                     MOVH {uhalf}$0x20012cc,{uword}%r0
00005d70: 77 1c                                          BNEB &0x1c <0x5d8c>
00005d72: 84 7f c8 12 00 02 ef 94 04 00 00               MOVW $0x20012c8,*$0x494
00005d7d: 70                                             NOP
00005d7e: c8 03 0d 7f c4 12 00 02 4b                     INSFW &0x3,&0xd,$0x20012c4,%psw
00005d87: 84 01 40                                       MOVW &0x1,%r0
00005d8a: 7b 4d                                          BRB &0x4d <0x5dd7>
00005d8c: 3c 5f ff 00 59                                 CMPW &0xff,(%fp)
00005d91: 4f 1c                                          BLEB &0x1c <0x5dad>
00005d93: 84 7f c8 12 00 02 ef 94 04 00 00               MOVW $0x20012c8,*$0x494
00005d9e: 70                                             NOP
00005d9f: c8 03 0d 7f c4 12 00 02 4b                     INSFW &0x3,&0xd,$0x20012c4,%psw
00005da8: 84 00 40                                       MOVW &0x0,%r0
00005dab: 7b 2c                                          BRB &0x2c <0x5dd7>
00005dad: 86 e2 7f ce 12 00 02 e0 40                     MOVH {uhalf}$0x20012ce,{uword}%r0
00005db6: 7f 1c                                          BEB &0x1c <0x5dd2>
00005db8: 84 7f c8 12 00 02 ef 94 04 00 00               MOVW $0x20012c8,*$0x494
00005dc3: 70                                             NOP
00005dc4: c8 03 0d 7f c4 12 00 02 4b                     INSFW &0x3,&0xd,$0x20012c4,%psw
00005dcd: 84 00 40                                       MOVW &0x0,%r0
00005dd0: 7b 07                                          BRB &0x7 <0x5dd7>
00005dd2: 90 59                                          INCW (%fp)
00005dd4: 70                                             NOP
00005dd5: 7b 84                                          BRB &0x84 <0x5d59>
00005dd7: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005ddb: 20 49                                          POPW %fp
00005ddd: 08                                             RET
00005dde: 70                                             NOP
00005ddf: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine
;;
00005de0: 10 49                                          SAVE %fp
00005de2: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00005de9: 2c 5c af 89 01                                 CALL (%sp),0x189(%pc)
00005dee: 87 01 ef c4 04 00 00                           MOVB &0x1,*$0x4c4
00005df5: 70                                             NOP
00005df6: 38 7f 5c 08 00 02 4f 00 00 00 20               BITW $0x200085c,&0x20000000
00005e01: 7f 24                                          BEB &0x24 <0x5e25>
;; Print "FW ERROR 1-01: NVRAM SANITY FAILURE"
00005e03: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
00005e09: a0 4f c0 0d 00 00                              PUSHW &0xdc0
00005e0f: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
;; Print "[...]DEFAULT VALUES ASSUMED\n[...]IF REPEATED, CHECK THE BATTERY"
00005e17: a0 4f d9 0d 00 00                              PUSHW &0xdd9
00005e1d: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00005e25: 38 7f 5c 08 00 02 4f 00 00 00 40               BITW $0x200085c,&0x40000000
00005e30: 7f 10                                          BEB &0x10 <0x5e40>
;; Print "FW WARNING: NVRAM DEFAULT VALUES ASSUMED\n\n"
00005e32: a0 4f 2e 0e 00 00                              PUSHW &0xe2e
00005e38: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00005e40: 38 7f 5c 08 00 02 02                           BITW $0x200085c,&0x2
00005e47: 7f 16                                          BEB &0x16 <0x5e5d>
;; Print "FW ERROR 1-02: DISK SANITY FAILURE"
00005e49: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
00005e4f: a0 4f 5a 0e 00 00                              PUSHW &0xe5a
00005e55: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00005e5d: 38 7f 5c 08 00 02 01                           BITW $0x200085c,&0x1
00005e64: 7f 16                                          BEB &0x16 <0x5e7a>
;; Print "FW ERROR 1-05: SELF-CONFIGURATION FAILURE"
00005e66: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
00005e6c: a0 4f 72 0e 00 00                              PUSHW &0xe72
00005e72: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00005e7a: 38 7f 5c 08 00 02 04                           BITW $0x200085c,&0x4
00005e81: 7f 16                                          BEB &0x16 <0x5e97>
;; Print "FW-ERROR 1-06: BOOT FAILURE"
00005e83: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
00005e89: a0 4f 91 0e 00 00                              PUSHW &0xe91
00005e8f: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00005e97: 38 7f 5c 08 00 02 20                           BITW $0x200085c,&0x20
00005e9e: 7f 16                                          BEB &0x16 <0x5eb4>
;; Print "FW-ERROR 1-07: FLOPPY KEY CREATE FAILURE"
00005ea0: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
00005ea6: a0 4f a2 0e 00 00                              PUSHW &0xea2
00005eac: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00005eb4: 38 7f 5c 08 00 02 08                           BITW $0x200085c,&0x8
00005ebb: 7f 16                                          BEB &0x16 <0x5ed1>
;; Print "FW-ERROR 1-08: MEMORY TEST FAILURE"
00005ebd: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
00005ec3: a0 4f c0 0e 00 00                              PUSHW &0xec0
00005ec9: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00005ed1: 38 7f 5c 08 00 02 10                           BITW $0x200085c,&0x10
00005ed8: 7f 16                                          BEB &0x16 <0x5eee>
;; Print "FW-ERROR 1-09: DISK FORMAT NOT COMPATIBLE WITH SYSTEM"
00005eda: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
00005ee0: a0 4f d8 0e 00 00                              PUSHW &0xed8
00005ee6: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00005eee: 28 7f 5c 08 00 02                              TSTW $0x200085c
00005ef4: 7f 23                                          BEB &0x23 <0x5f17>
00005ef6: 3c 4f 00 00 00 01 7f 5c 08 00 02               CMPW &0x1000000,$0x200085c
00005f01: 53 16                                          BGEUB &0x16 <0x5f17>
;; Print string "EXECUTION HALTED"
00005f03: a0 4f 03 0f 00 00                              PUSHW &0xf03
00005f09: a0 4f 9c 0d 00 00                              PUSHW &0xd9c
00005f0f: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
00005f17: 3c 4f 00 00 00 80 7f 5c 08 00 02               CMPW &0x80000000,$0x200085c
00005f22: 77 29                                          BNEB &0x29 <0x5f4b>
00005f24: 3c 4f ef be ed fe 7f 64 08 00 02               CMPW &0xfeedbeef,$0x2000864
00005f2f: 7f 1c                                          BEB &0x1c <0x5f4b>
00005f31: a0 4f 06 0f 00 00                              PUSHW &0xf06
00005f37: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00005f3f: b8 4f ff ff ff 7f 7f 5c 08 00 02               ANDW2 &0x7fffffff,$0x200085c
00005f4a: 70                                             NOP
00005f4b: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
00005f53: 3f 01 50                                       CMPB &0x1,(%r0)
00005f56: 77 09                                          BNEB &0x9 <0x5f5f>
00005f58: 80 7f 5c 08 00 02                              CLRW $0x200085c
00005f5e: 70                                             NOP
00005f5f: a0 01                                          PUSHW &0x1
00005f61: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00005f69: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005f6d: 20 49                                          POPW %fp
00005f6f: 08                                             RET
00005f70: 70                                             NOP
00005f71: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine
;;
00005f72: 10 49                                          SAVE %fp
00005f74: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00005f7b: 87 01 7f 03 40 04 00                           MOVB &0x1,$0x44003
00005f82: 70                                             NOP
00005f83: 87 01 7f 07 40 04 00                           MOVB &0x1,$0x44007
00005f8a: 70                                             NOP
00005f8b: 87 01 7f 0f 40 04 00                           MOVB &0x1,$0x4400f
00005f92: 70                                             NOP
00005f93: 87 01 7f 3f 40 04 00                           MOVB &0x1,$0x4403f
00005f9a: 70                                             NOP
00005f9b: 87 01 7f 37 40 04 00                           MOVB &0x1,$0x44037
00005fa2: 70                                             NOP
00005fa3: 87 01 7f 0d 80 04 00                           MOVB &0x1,$0x4800d
00005faa: 70                                             NOP
00005fab: 87 7f 11 90 04 00 59                           MOVB $0x49011,(%fp)
00005fb2: 70                                             NOP
00005fb3: 87 7f 00 d0 04 00 59                           MOVB $0x4d000,(%fp)
00005fba: 70                                             NOP
00005fbb: 87 6f 56 7f 0f 20 04 00                        MOVB &0x56,$0x4200f
00005fc3: 70                                             NOP
00005fc4: 87 7f 13 20 04 00 59                           MOVB $0x42013,(%fp)
00005fcb: 70                                             NOP
00005fcc: 87 01 7f 27 40 04 00                           MOVB &0x1,$0x44027
00005fd3: 70                                             NOP
00005fd4: 87 01 7f 2f 40 04 00                           MOVB &0x1,$0x4402f
00005fdb: 70                                             NOP
00005fdc: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00005fe0: 20 49                                          POPW %fp
00005fe2: 08                                             RET
00005fe3: 70                                             NOP
00005fe4: 70                                             NOP
00005fe5: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine
;;
00005fe6: 10 49                                          SAVE %fp
00005fe8: 9c 4f 10 00 00 00 4c                           ADDW2 &0x10,%sp
00005fef: a0 4f ec 31 04 00                              PUSHW &0x431ec
00005ff5: e0 59                                          PUSHAW (%fp)
00005ff7: a0 04                                          PUSHW &0x4
00005ff9: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00006001: 3c 4f ef be 0d 60 59                           CMPW &0x600dbeef,(%fp)
00006008: 7f 08                                          BEB &0x8 <0x6010>
0000600a: 24 7f 4e 61 00 00                              JMP $0x614e
00006010: a0 4f f0 31 04 00                              PUSHW &0x431f0
00006016: e0 59                                          PUSHAW (%fp)
00006018: a0 04                                          PUSHW &0x4
0000601a: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00006022: 28 59                                          TSTW (%fp)
00006024: 77 16                                          BNEB &0x16 <0x603a>
00006026: a0 4f 14 0f 00 00                              PUSHW &0xf14
0000602c: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
00006034: 24 7f b9 61 00 00                              JMP $0x61b9
0000603a: 38 59 6f 40                                    BITW (%fp),&0x40
0000603e: 77 0f                                          BNEB &0xf <0x604d>
00006040: 38 59 5f 80 00                                 BITW (%fp),&0x80
00006045: 77 08                                          BNEB &0x8 <0x604d>
00006047: 24 7f d0 60 00 00                              JMP $0x60d0
0000604d: a0 4f f4 31 04 00                              PUSHW &0x431f4
00006053: e0 68                                          PUSHAW 8(%fp)
00006055: a0 04                                          PUSHW &0x4
00006057: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
0000605f: a0 4f f8 31 04 00                              PUSHW &0x431f8
00006065: e0 64                                          PUSHAW 4(%fp)
00006067: a0 04                                          PUSHW &0x4
00006069: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00006071: a0 4f fc 31 04 00                              PUSHW &0x431fc
00006077: e0 6c                                          PUSHAW 12(%fp)
00006079: a0 04                                          PUSHW &0x4
0000607b: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00006083: 38 59 6f 40                                    BITW (%fp),&0x40
00006087: 7f 20                                          BEB &0x20 <0x60a7>
00006089: a0 4f 1c 0f 00 00                              PUSHW &0xf1c
0000608f: a0 64                                          PUSHW 4(%fp)
00006091: a0 68                                          PUSHW 8(%fp)
00006093: f8 4f ff ff 00 00 6c 40                        ANDW3 &0xffff,12(%fp),%r0
0000609b: a0 40                                          PUSHW %r0
0000609d: 2c cc f0 7f e4 44 00 00                        CALL -16(%sp),$0x44e4
000060a5: 7b 29                                          BRB &0x29 <0x60ce>
000060a7: a0 4f 52 0f 00 00                              PUSHW &0xf52
000060ad: a0 64                                          PUSHW 4(%fp)
000060af: a0 68                                          PUSHW 8(%fp)
000060b1: f8 4f ff ff 00 00 6c 40                        ANDW3 &0xffff,12(%fp),%r0
000060b9: a0 40                                          PUSHW %r0
000060bb: d4 10 6c 40                                    LRSW3 &0x10,12(%fp),%r0
000060bf: b8 5f ff 00 40                                 ANDW2 &0xff,%r0
000060c4: a0 40                                          PUSHW %r0
000060c6: 2c cc ec 7f e4 44 00 00                        CALL -20(%sp),$0x44e4
000060ce: 7b 7e                                          BRB &0x7e <0x614c>
000060d0: 38 59 02                                       BITW (%fp),&0x2
000060d3: 7f 79                                          BEB &0x79 <0x614c>
000060d5: a0 4f 92 0f 00 00                              PUSHW &0xf92
000060db: d4 17 59 40                                    LRSW3 &0x17,(%fp),%r0
000060df: b8 01 40                                       ANDW2 &0x1,%r0
000060e2: a0 40                                          PUSHW %r0
000060e4: d4 10 59 40                                    LRSW3 &0x10,(%fp),%r0
000060e8: b8 6f 7f 40                                    ANDW2 &0x7f,%r0
000060ec: a0 40                                          PUSHW %r0
000060ee: 2c cc f4 7f e4 44 00 00                        CALL -12(%sp),$0x44e4
000060f6: a0 4f fc 31 04 00                              PUSHW &0x431fc
000060fc: e0 6c                                          PUSHAW 12(%fp)
000060fe: a0 04                                          PUSHW &0x4
00006100: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00006108: 28 6c                                          TSTW 12(%fp)
0000610a: 7f 34                                          BEB &0x34 <0x613e>
0000610c: a0 4f b0 0f 00 00                              PUSHW &0xfb0
00006112: d4 18 6c 40                                    LRSW3 &0x18,12(%fp),%r0
00006116: a0 40                                          PUSHW %r0
00006118: d4 10 6c 40                                    LRSW3 &0x10,12(%fp),%r0
0000611c: b8 5f ff 00 40                                 ANDW2 &0xff,%r0
00006121: a0 40                                          PUSHW %r0
00006123: d4 08 6c 40                                    LRSW3 &0x8,12(%fp),%r0
00006127: b8 5f ff 00 40                                 ANDW2 &0xff,%r0
0000612c: a0 40                                          PUSHW %r0
0000612e: f8 5f ff 00 6c 40                              ANDW3 &0xff,12(%fp),%r0
00006134: a0 40                                          PUSHW %r0
00006136: 2c cc ec 7f e4 44 00 00                        CALL -20(%sp),$0x44e4
0000613e: a0 4f ff 0f 00 00                              PUSHW &0xfff
00006144: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
0000614c: 7b 10                                          BRB &0x10 <0x615c>
0000614e: a0 4f 02 10 00 00                              PUSHW &0x1002
00006154: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
0000615c: 80 59                                          CLRW (%fp)
0000615e: 70                                             NOP
0000615f: e0 59                                          PUSHAW (%fp)
00006161: a0 4f f0 31 04 00                              PUSHW &0x431f0
00006167: a0 04                                          PUSHW &0x4
00006169: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00006171: e0 59                                          PUSHAW (%fp)
00006173: a0 4f f4 31 04 00                              PUSHW &0x431f4
00006179: a0 04                                          PUSHW &0x4
0000617b: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00006183: e0 59                                          PUSHAW (%fp)
00006185: a0 4f f8 31 04 00                              PUSHW &0x431f8
0000618b: a0 04                                          PUSHW &0x4
0000618d: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00006195: e0 59                                          PUSHAW (%fp)
00006197: a0 4f fc 31 04 00                              PUSHW &0x431fc
0000619d: a0 04                                          PUSHW &0x4
0000619f: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
000061a7: e0 59                                          PUSHAW (%fp)
000061a9: a0 4f ec 31 04 00                              PUSHW &0x431ec
000061af: a0 04                                          PUSHW &0x4
000061b1: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
000061b9: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000061bd: 20 49                                          POPW %fp
000061bf: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine
;;

;; We're called with the flag for "DISK SANITY FAILURE" (0x10000) already
;; set in %ap. Seems to get set at 0x6e93
;;
000061c0: 10 49                                          SAVE %fp
000061c2: 9c 4f 0c 00 00 00 4c                           ADDW2 &0xc,%sp
000061c9: a0 4f ec 31 04 00                              PUSHW &0x431ec
000061cf: e0 64                                          PUSHAW 4(%fp)
000061d1: a0 04                                          PUSHW &0x4
000061d3: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
000061db: 3c 4f ef be 0d 60 64                           CMPW &0x600dbeef,4(%fp)
000061e2: 77 16                                          BNEB &0x16 <0x61f8>
000061e4: a0 4f f0 31 04 00                              PUSHW &0x431f0
000061ea: e0 59                                          PUSHAW (%fp)
000061ec: a0 04                                          PUSHW &0x4
000061ee: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
000061f6: 7b 0a                                          BRB &0xa <0x6200>
000061f8: 84 7f 5c 08 00 02 59                           MOVW $0x200085c,(%fp)
000061ff: 70                                             NOP
00006200: 80 64                                          CLRW 4(%fp)
00006202: 70                                             NOP
00006203: e0 64                                          PUSHAW 4(%fp)
00006205: a0 4f ec 31 04 00                              PUSHW &0x431ec
0000620b: a0 04                                          PUSHW &0x4
0000620d: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00006215: b0 5a 59                                       ORW2 (%ap),(%fp)
00006218: 70                                             NOP
00006219: 84 59 7f 5c 08 00 02                           MOVW (%fp),$0x200085c
00006220: 70                                             NOP
00006221: e0 59                                          PUSHAW (%fp)
00006223: a0 4f f0 31 04 00                              PUSHW &0x431f0
00006229: a0 04                                          PUSHW &0x4
0000622b: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00006233: 38 5a 6f 40                                    BITW (%ap),&0x40
00006237: 77 09                                          BNEB &0x9 <0x6240>
00006239: 38 5a 5f 80 00                                 BITW (%ap),&0x80
0000623e: 7f 63                                          BEB &0x63 <0x62a1>
00006240: a0 4f 58 12 00 02                              PUSHW &0x2001258
00006246: a0 4f f4 31 04 00                              PUSHW &0x431f4
0000624c: a0 04                                          PUSHW &0x4
0000624e: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00006256: a0 4f 5c 12 00 02                              PUSHW &0x200125c
0000625c: a0 4f f8 31 04 00                              PUSHW &0x431f8
00006262: a0 04                                          PUSHW &0x4
00006264: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
0000626c: 86 e2 7f 02 40 04 00 e0 68                     MOVH {uhalf}$0x44002,{uword}8(%fp)
00006275: 70                                             NOP
00006276: 38 5a 5f 80 00                                 BITW (%ap),&0x80
0000627b: 7f 12                                          BEB &0x12 <0x628d>
0000627d: 87 7f 60 12 00 02 e0 40                        MOVB $0x2001260,{uword}%r0
00006285: d0 10 40 40                                    LLSW3 &0x10,%r0,%r0
00006289: b0 40 68                                       ORW2 %r0,8(%fp)
0000628c: 70                                             NOP
0000628d: e0 68                                          PUSHAW 8(%fp)
0000628f: a0 4f fc 31 04 00                              PUSHW &0x431fc
00006295: a0 04                                          PUSHW &0x4
00006297: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
0000629f: 7b 1d                                          BRB &0x1d <0x62bc>
000062a1: 38 5a 02                                       BITW (%ap),&0x2
000062a4: 7f 18                                          BEB &0x18 <0x62bc>
000062a6: a0 4f d4 12 00 02                              PUSHW &0x20012d4
000062ac: a0 4f fc 31 04 00                              PUSHW &0x431fc
000062b2: a0 04                                          PUSHW &0x4
000062b4: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
000062bc: 84 4f ef be 0d 60 64                           MOVW &0x600dbeef,4(%fp)
000062c3: 70                                             NOP
000062c4: e0 64                                          PUSHAW 4(%fp)
000062c6: a0 4f ec 31 04 00                              PUSHW &0x431ec
000062cc: a0 04                                          PUSHW &0x4
000062ce: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
000062d6: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000062da: 20 49                                          POPW %fp
000062dc: 08                                             RET
000062dd: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine -- checks interval timer and soft power inhibit.
;;

000062de: 10 49                                          SAVE %fp
000062e0: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp

;; Check soft power inhibit (*510 = 020012d0)
000062e7: 3f 01 ef 10 05 00 00                           CMPB &0x1,*$0x510
000062ee: 7f 2b                                          BEB &0x2b <0x6319>

;; Check programmable interval timer (8253)
000062f0: 3f 6f 64 7f 03 20 04 00                        CMPB &0x64,$0x42003
;; Interval timer is OK, skip terminal condition and return.
000062f8: 7f 21                                          BEB &0x21 <0x6319>

;; Clear some state and enter a terminal condition
000062fa: 80 ef 8c 04 00 00                              CLRW *$0x48c
00006300: 70                                             NOP
00006301: 80 ef 14 05 00 00                              CLRW *$0x514
00006307: 70                                             NOP
00006308: 83 7f 0d 90 04 00                              CLRB $0x4900d
0000630e: 70                                             NOP
0000630f: 87 04 7f 0e 90 04 00                           MOVB &0x4,$0x4900e
00006316: 70                                             NOP
;; Terminal condition - infinite loop
00006317: 7b 00                                          BRB &0x0 <0x6317>

;; Return
00006319: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
0000631d: 20 49                                          POPW %fp
0000631f: 08                                             RET
00006320: 70                                             NOP
00006321: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Terminal Halt. Enter an infinite loop on 0x633F.
;;

00006322: 10 49                                          SAVE %fp
00006324: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
0000632b: 2c 5c cf b3                                    CALL (%sp),-77(%pc)
0000632f: 84 5a ef 8c 04 00 00                           MOVW (%ap),*$0x48c
00006336: 70                                             NOP
00006337: 87 01 7f 0b 40 04 00                           MOVB &0x1,$0x4400b
0000633e: 70                                             NOP
0000633f: 7b 00                                          BRB &0x0 <0x633f>
00006341: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00006345: 20 49                                          POPW %fp
00006347: 08                                             RET
00006348: 70                                             NOP
00006349: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Terminal Halt. Enter an infinite loop on 0x6363.
;;

0000634a: 10 49                                          SAVE %fp
0000634c: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00006353: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
0000635e: 70                                             NOP
0000635f: 2c 5c af 81 fa                                 CALL (%sp),0x..fa81(%pc)
00006364: 87 01 7f 0b 40 04 00                           MOVB &0x1,$0x4400b
0000636b: 70                                             NOP
0000636c: 7b 00                                          BRB &0x0 <0x636c>
0000636e: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00006372: 20 49                                          POPW %fp
00006374: 08                                             RET
00006375: 70                                             NOP
00006376: 70                                             NOP
00006377: 70                                             NOP


00006378: 10 49                                          SAVE %fp
0000637a: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00006381: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00006389: 2b 50                                          TSTB (%r0)
0000638b: 77 0b                                          BNEB &0xb <0x6396>
0000638d: 84 01 40                                       MOVW &0x1,%r0
00006390: 24 7f e5 64 00 00                              JMP $0x64e5
00006396: 86 01 59                                       MOVH &0x1,(%fp)
00006399: 70                                             NOP
0000639a: 7b 2d                                          BRB &0x2d <0x63c7>
0000639c: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
000063a1: d0 05 40 40                                    LLSW3 &0x5,%r0,%r0
000063a5: 9c 7f 90 04 00 00 40                           ADDW2 $0x490,%r0
000063ac: cc 03 0c 50 40                                 EXTFW &0x3,&0xc,(%r0),%r0
000063b1: dc 02 7f a4 04 00 00 41                        ADDW3 &0x2,$0x4a4,%r1
000063b9: 87 51 e0 41                                    MOVB (%r1),{uword}%r1
000063bd: 3c 41 40                                       CMPW %r1,%r0
000063c0: 77 04                                          BNEB &0x4 <0x63c4>
000063c2: 7b 17                                          BRB &0x17 <0x63d9>
000063c4: 92 59                                          INCH (%fp)
000063c6: 70                                             NOP
000063c7: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
000063cc: 87 ef e0 04 00 00 e0 41                        MOVB *$0x4e0,{uword}%r1
000063d4: 3c 41 40                                       CMPW %r1,%r0
000063d7: 5b c5                                          BLUB &0xc5 <0x639c>
000063d9: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
000063de: 87 ef e0 04 00 00 e0 41                        MOVB *$0x4e0,{uword}%r1
000063e6: 3c 41 40                                       CMPW %r1,%r0
000063e9: 5b 2a                                          BLUB &0x2a <0x6413>
000063eb: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
000063f3: 83 50                                          CLRB (%r0)
000063f5: 70                                             NOP
000063f6: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
000063fe: 83 50                                          CLRB (%r0)
00006400: 70                                             NOP
00006401: 86 5f bd 04 ef a4 04 00 00                     MOVH &0x4bd,*$0x4a4
0000640a: 70                                             NOP
0000640b: 80 40                                          CLRW %r0
0000640d: 24 7f e5 64 00 00                              JMP $0x64e5
00006413: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
0000641b: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
0000641f: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00006423: 87 01 c0 05                                    MOVB &0x1,5(%r0)
00006427: 70                                             NOP

;; Hardware delay of 0x14
00006428: a0 14                                          PUSHW &0x14
0000642a: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528

;; Sysgen the system board.
00006432: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
0000643a: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
0000643e: a0 40                                          PUSHW %r0

;; call fw_sysgen
00006440: 2c cc fc 7f ec 55 00 00                        CALL -4(%sp),$0x55ec
00006448: 3c 01 40                                       CMPW &0x1,%r0
0000644b: 7f 08                                          BEB &0x8 <0x6453>
0000644d: 24 7f e1 64 00 00                              JMP $0x64e1
00006453: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
0000645b: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
0000645f: a0 40                                          PUSHW %r0
00006461: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00006469: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
0000646d: a0 40                                          PUSHW %r0
0000646f: 2c cc f8 7f c6 59 00 00                        CALL -8(%sp),$0x59c6
00006477: 3c 01 40                                       CMPW &0x1,%r0
0000647a: 77 67                                          BNEB &0x67 <0x64e1>
0000647c: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
00006484: 87 01 50                                       MOVB &0x1,(%r0)
00006487: 70                                             NOP
00006488: 86 ef a4 04 00 00 59                           MOVH *$0x4a4,(%fp)
0000648f: 70                                             NOP
00006490: e0 59                                          PUSHAW (%fp)
00006492: a0 4f 80 30 04 00                              PUSHW &0x43080
00006498: a0 02                                          PUSHW &0x2
0000649a: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
000064a2: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
000064aa: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
000064ae: d0 04 40 40                                    LLSW3 &0x4,%r0,%r0
000064b2: bb 5f f0 00 40                                 ANDB2 &0xf0,%r0
000064b7: dc 03 7f a4 04 00 00 41                        ADDW3 &0x3,$0x4a4,%r1
000064bf: fb 0f 51 41                                    ANDB3 &0xf,(%r1),%r1
000064c3: b3 41 40                                       ORB2 %r1,%r0
000064c6: 87 40 62                                       MOVB %r0,2(%fp)
000064c9: 70                                             NOP
000064ca: e0 62                                          PUSHAW 2(%fp)
000064cc: a0 4f 09 30 04 00                              PUSHW &0x43009
000064d2: a0 01                                          PUSHW &0x1
000064d4: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
000064dc: 84 01 40                                       MOVW &0x1,%r0
000064df: 7b 06                                          BRB &0x6 <0x64e5>
000064e1: 80 40                                          CLRW %r0
000064e3: 7b 02                                          BRB &0x2 <0x64e5>
000064e5: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000064e9: 20 49                                          POPW %fp
000064eb: 08                                             RET


000064ec: 10 49                                          SAVE %fp
000064ee: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
000064f5: 2c 5c ef f8 11 00 02                           CALL (%sp),*$0x20011f8
000064fc: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00006500: 20 49                                          POPW %fp
00006502: 08                                             RET
00006503: 70                                             NOP


00006504: 10 49                                          SAVE %fp
00006506: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
0000650d: a0 5f 80 00                                    PUSHW &0x80
00006511: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
;; Print the string "FW-ERROR 1-%s"
00006519: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
;; Print the string "UNEXPECTED INTERRUPT"
0000651f: a0 4f 0c 10 00 00                              PUSHW &0x100c
00006525: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
; Print the string "EXECUTION HALTED"
0000652d: a0 4f 9c 0d 00 00                              PUSHW &0xd9c
00006533: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
0000653b: a0 4f ef be ed fe                              PUSHW &0xfeedbeef
00006541: 2c cc fc 7f 22 63 00 00                        CALL -4(%sp),$0x6322
00006549: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
0000654d: 20 49                                          POPW %fp
0000654f: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown procedure. Currently of interest becuase it is called by
;; the only 100% confirmed interrupt handler, "demon", at 0x421f.
;;
00006550: 10 49                                          SAVE %fp
00006552: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00006559: f8 03 7f 58 12 00 02 40                        ANDW3 &0x3,$0x2001258,%r0
00006561: 3c 03 40                                       CMPW &0x3,%r0
00006564: 77 31                                          BNEB &0x31 <0x6595>
00006566: f8 6f 78 7f 58 12 00 02 40                     ANDW3 &0x78,$0x2001258,%r0
0000656f: 3c 6f 70 40                                    CMPW &0x70,%r0
00006573: 7f 10                                          BEB &0x10 <0x6583>
00006575: f8 6f 78 7f 58 12 00 02 40                     ANDW3 &0x78,$0x2001258,%r0
0000657e: 3c 08 40                                       CMPW &0x8,%r0
00006581: 77 0b                                          BNEB &0xb <0x658c>
00006583: 2c 5c ef d8 12 00 02                           CALL (%sp),*$0x20012d8
0000658a: 7b 09                                          BRB &0x9 <0x6593>
0000658c: 2c 5c ef f4 11 00 02                           CALL (%sp),*$0x20011f4
00006593: 7b 09                                          BRB &0x9 <0x659c>
00006595: 2c 5c ef f4 11 00 02                           CALL (%sp),*$0x20011f4
0000659c: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000065a0: 20 49                                          POPW %fp
000065a2: 08                                             RET
000065a3: 70                                             NOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Exception Handler
;;
000065a4: 10 49                                          SAVE %fp
000065a6: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
000065ad: a0 6f 40                                       PUSHW &0x40
000065b0: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
000065b8: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
000065be: a0 4f 28 10 00 00                              PUSHW &0x1028
;; Print the string "03: UNEXPECTED FAULT"
000065c4: 2c cc f8 7f e4 44 00 00                        CALL -8(%sp),$0x44e4
;; Print the string "EXECUTION HALTED"
000065cc: a0 4f 9c 0d 00 00                              PUSHW &0xd9c
000065d2: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000065da: a0 4f ef be ed fe                              PUSHW &0xfeedbeef
000065e0: 2c cc fc 7f 22 63 00 00                        CALL -4(%sp),$0x6322
000065e8: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000065ec: 20 49                                          POPW %fp
000065ee: 08                                             RET
000065ef: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
000065f0: 10 48                                          SAVE %r8
000065f2: 9c 4f 74 00 00 00 4c                           ADDW2 &0x74,%sp
000065f9: 87 01 ef c4 04 00 00                           MOVB &0x1,*$0x4c4
00006600: 70                                             NOP
00006601: 84 4f 04 65 00 00 7f f8 11 00 02               MOVW &0x6504,$0x20011f8
0000660c: 70                                             NOP
0000660d: 84 4f a4 65 00 00 7f f4 11 00 02               MOVW &0x65a4,$0x20011f4
00006618: 70                                             NOP
00006619: 84 7f f4 11 00 02 7f d8 12 00 02               MOVW $0x20011f4,$0x20012d8
00006624: 70                                             NOP
00006625: 3c 4f ef be ed fe 7f 64 08 00 02               CMPW &0xfeedbeef,$0x2000864
00006630: 7f 09                                          BEB &0x9 <0x6639>
00006632: 84 4f 00 00 80 00 4b                           MOVW &0x800000,%psw
00006639: 84 7f 64 08 00 02 48                           MOVW $0x2000864,%r8
00006640: 3c 4f ef be ed fe 7f 64 08 00 02               CMPW &0xfeedbeef,$0x2000864
0000664b: 7f 15                                          BEB &0x15 <0x6660>
0000664d: 3c 4f 1e ac eb ad 7f 64 08 00 02               CMPW &0xadebac1e,$0x2000864
00006658: 7f 08                                          BEB &0x8 <0x6660>
0000665a: 24 7f 38 68 00 00                              JMP $0x6838
00006660: 84 4f d0 f1 02 3b 7f 64 08 00 02               MOVW &0x3b02f1d0,$0x2000864
0000666b: 70                                             NOP
0000666c: a0 4f 00 30 04 00                              PUSHW &0x43000
00006672: e0 c9 64                                       PUSHAW 100(%fp)
00006675: a0 09                                          PUSHW &0x9
;; Call 'rnvram'
00006677: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
0000667f: 2b c9 64                                       TSTB 100(%fp)
00006682: 77 26                                          BNEB &0x26 <0x66a8>
00006684: e0 c9 64                                       PUSHAW 100(%fp)
;; This is the pointer to the default password, 'mcp'
00006687: a0 4f 40 10 00 00                              PUSHW &0x1040
0000668d: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
00006695: e0 c9 64                                       PUSHAW 100(%fp)
00006698: a0 4f 00 30 04 00                              PUSHW &0x43000
0000669e: a0 09                                          PUSHW &0x9
000066a0: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
;; Jumped back to this point from 0x6835
000066a8: 3c 4f 0d f0 ad 8b 48                           CMPW &0x8badf00d,%r8
000066af: 77 08                                          BNEB &0x8 <0x66b7>
000066b1: 24 7f 3c 67 00 00                              JMP $0x673c
000066b7: 3c 4f ef be ed fe 48                           CMPW &0xfeedbeef,%r8
000066be: 7f 7e                                          BEB &0x7e <0x673c>
000066c0: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
000066c8: 2b 50                                          TSTB (%r0)
000066ca: 77 72                                          BNEB &0x72 <0x673c>
000066cc: a0 4f 0c 30 04 00                              PUSHW &0x4300c
000066d2: e0 c9 6e                                       PUSHAW 110(%fp)
000066d5: a0 01                                          PUSHW &0x1
000066d7: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
000066df: 28 40                                          TSTW %r0
000066e1: 77 28                                          BNEB &0x28 <0x6709>
000066e3: 87 01 c9 6e                                    MOVB &0x1,110(%fp)
000066e7: 70                                             NOP
000066e8: e0 c9 6e                                       PUSHAW 110(%fp)
000066eb: a0 4f 0c 30 04 00                              PUSHW &0x4300c
000066f1: a0 01                                          PUSHW &0x1
000066f3: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
000066fb: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006703: 87 01 50                                       MOVB &0x1,(%r0)
00006706: 70                                             NOP
00006707: 7b 0f                                          BRB &0xf <0x6716>
00006709: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006711: 87 c9 6e 50                                    MOVB 110(%fp),(%r0)
00006715: 70                                             NOP
00006716: 83 ef a0 04 00 00                              CLRB *$0x4a0
0000671c: 70                                             NOP
0000671d: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00006725: a0 40                                          PUSHW %r0
00006727: a0 4f 44 10 00 00                              PUSHW &0x1044
0000672d: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
00006735: 2c 5c 7f 70 69 00 00                           CALL (%sp),$0x6970
0000673c: 7b 57                                          BRB &0x57 <0x6793>
0000673e: dc 02 7f a4 04 00 00 40                        ADDW3 &0x2,$0x4a4,%r0
00006746: 83 50                                          CLRB (%r0)
00006748: 70                                             NOP
00006749: dc 03 7f a4 04 00 00 40                        ADDW3 &0x3,$0x4a4,%r0
00006751: 83 50                                          CLRB (%r0)
00006753: 70                                             NOP
00006754: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
0000675b: 70                                             NOP
0000675c: 80 c9 70                                       CLRW 112(%fp)
0000675f: 70                                             NOP
00006760: 7b 06                                          BRB &0x6 <0x6766>
00006762: 90 c9 70                                       INCW 112(%fp)
00006765: 70                                             NOP
00006766: 3c 4f 50 c3 00 00 c9 70                        CMPW &0xc350,112(%fp)
0000676e: 4b f4                                          BLB &0xf4 <0x6762>
00006770: 87 01 7f 17 40 04 00                           MOVB &0x1,$0x44017
00006777: 70                                             NOP
00006778: 80 c9 70                                       CLRW 112(%fp)
0000677b: 70                                             NOP
0000677c: 7b 06                                          BRB &0x6 <0x6782>
0000677e: 90 c9 70                                       INCW 112(%fp)
00006781: 70                                             NOP
00006782: 3c 4f f0 49 02 00 c9 70                        CMPW &0x249f0,112(%fp)
0000678a: 4b f4                                          BLB &0xf4 <0x677e>
0000678c: 2c 5c 7f de 62 00 00                           CALL (%sp),$0x62de
00006793: dc 04 7f a4 04 00 00 40                        ADDW3 &0x4,$0x4a4,%r0
0000679b: 3f 01 50                                       CMPB &0x1,(%r0)
0000679e: 7f 11                                          BEB &0x11 <0x67af>
000067a0: 8b 7f 0d 90 04 00 40                           MCOMB $0x4900d,%r0
000067a7: b8 01 40                                       ANDW2 &0x1,%r0
000067aa: 3c 01 40                                       CMPW &0x1,%r0
000067ad: 77 91                                          BNEB &0x91 <0x673e>
000067af: 2c 5c 7f e0 5d 00 00                           CALL (%sp),$0x5de0
000067b6: 3c 4f ef be ed fe 48                           CMPW &0xfeedbeef,%r8
000067bd: 77 1a                                          BNEB &0x1a <0x67d7>
000067bf: 87 01 7f 13 40 04 00                           MOVB &0x1,$0x44013
000067c6: 70                                             NOP
;; Print "SYSTEM FAILURE: CONSULT YOUR SYSTEM ADMINISTRATION UTILITIES GUIDE"
000067c7: a0 4f 4d 10 00 00                              PUSHW &0x104d
000067cd: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4
000067d5: 7b 18                                          BRB &0x18 <0x67ed>
000067d7: 87 01 7f 17 40 04 00                           MOVB &0x1,$0x44017
000067de: 70                                             NOP
;; Print "FIRMWARE MODE\n"
000067df: a0 4f 93 10 00 00                              PUSHW &0x1093
000067e5: 2c cc fc 7f e4 44 00 00                        CALL -4(%sp),$0x44e4

;; Call 3ab4 XXX
000067ed: e0 59                                          PUSHAW (%fp)
000067ef: 2c cc fc 7f b4 3a 00 00                        CALL -4(%sp),$0x3ab4
000067f7: e0 59                                          PUSHAW (%fp)
000067f9: e0 c9 64                                       PUSHAW 100(%fp)
000067fc: 2c cc f8 7f 68 7f 00 00                        CALL -8(%sp),$0x7f68
00006804: 28 40                                          TSTW %r0
00006806: 77 2f                                          BNEB &0x2f <0x6835>
00006808: 84 4f ef be ed fe 7f 64 08 00 02               MOVW &0xfeedbeef,$0x2000864
00006813: 70                                             NOP
00006814: 2c 5c 7f 04 2b 00 00                           CALL (%sp),$0x2b04
0000681b: 84 7f 64 08 00 02 48                           MOVW $0x2000864,%r8
00006822: a0 4f 00 30 04 00                              PUSHW &0x43000
00006828: e0 c9 64                                       PUSHAW 100(%fp)
0000682b: a0 09                                          PUSHW &0x9
0000682d: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
;; Jump back to 0x66A8
00006835: 7a 73 fe                                       BRH &0xfe73 <0x66a8>
00006838: a0 4f 0c 30 04 00                              PUSHW &0x4300c
0000683e: e0 c9 6e                                       PUSHAW 110(%fp)
00006841: a0 01                                          PUSHW &0x1
00006843: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
0000684b: 28 40                                          TSTW %r0
0000684d: 77 28                                          BNEB &0x28 <0x6875>
0000684f: 87 01 c9 6e                                    MOVB &0x1,110(%fp)
00006853: 70                                             NOP
00006854: e0 c9 6e                                       PUSHAW 110(%fp)
00006857: a0 4f 0c 30 04 00                              PUSHW &0x4300c
0000685d: a0 01                                          PUSHW &0x1
0000685f: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
00006867: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
0000686f: 87 01 50                                       MOVB &0x1,(%r0)
00006872: 70                                             NOP
00006873: 7b 0f                                          BRB &0xf <0x6882>
00006875: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
0000687d: 87 c9 6e 50                                    MOVB 110(%fp),(%r0)
00006881: 70                                             NOP
00006882: 83 ef a0 04 00 00                              CLRB *$0x4a0
00006888: 70                                             NOP
00006889: 3c 4f 0d f0 ad 8b 48                           CMPW &0x8badf00d,%r8
00006890: 7f 56                                          BEB &0x56 <0x68e6>
00006892: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
0000689a: a0 40                                          PUSHW %r0
0000689c: a0 4f a4 10 00 00                              PUSHW &0x10a4
000068a2: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
000068aa: 2c 5c 7f 70 69 00 00                           CALL (%sp),$0x6970
000068b1: 28 40                                          TSTW %r0
000068b3: 77 09                                          BNEB &0x9 <0x68bc>
000068b5: 2c 5c 7f 4a 63 00 00                           CALL (%sp),$0x634a
000068bc: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
000068c4: a0 40                                          PUSHW %r0
000068c6: a0 4f ad 10 00 00                              PUSHW &0x10ad
000068cc: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
000068d4: 2c 5c 7f 70 69 00 00                           CALL (%sp),$0x6970
000068db: 28 40                                          TSTW %r0
000068dd: 77 09                                          BNEB &0x9 <0x68e6>
000068df: 2c 5c 7f 4a 63 00 00                           CALL (%sp),$0x634a
000068e6: 3c 4f ef be ed fe 7f 64 08 00 02               CMPW &0xfeedbeef,$0x2000864
000068f1: 7f 0a                                          BEB &0xa <0x68fb>
000068f3: 87 01 7f 17 40 04 00                           MOVB &0x1,$0x44017
000068fa: 70                                             NOP
000068fb: a0 4f 0d 30 04 00                              PUSHW &0x4300d
00006901: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00006909: a0 40                                          PUSHW %r0
0000690b: a0 2d                                          PUSHW &0x2d
0000690d: 2c cc f4 7f 24 52 00 00                        CALL -12(%sp),$0x5224
00006915: 28 40                                          TSTW %r0
00006917: 77 34                                          BNEB &0x34 <0x694b>
00006919: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00006921: a0 40                                          PUSHW %r0
00006923: a0 4f b4 10 00 00                              PUSHW &0x10b4
00006929: 2c cc f8 7f b0 7f 00 00                        CALL -8(%sp),$0x7fb0
00006931: dc 02 7f a0 04 00 00 40                        ADDW3 &0x2,$0x4a0,%r0
00006939: a0 40                                          PUSHW %r0
0000693b: a0 4f 0d 30 04 00                              PUSHW &0x4300d
00006941: a0 2d                                          PUSHW &0x2d
00006943: 2c cc f4 7f a0 52 00 00                        CALL -12(%sp),$0x52a0
0000694b: 87 02 ef a0 04 00 00                           MOVB &0x2,*$0x4a0
00006952: 70                                             NOP
00006953: 2c 5c 7f 70 69 00 00                           CALL (%sp),$0x6970
0000695a: 2c 5c 7f 4a 63 00 00                           CALL (%sp),$0x634a
00006961: 7a d8 fc                                       BRH &0xfcd8 <0x6639>
00006964: 04 c9 ec 4c                                    MOVAW -20(%fp),%sp
00006968: 20 48                                          POPW %r8
0000696a: 20 49                                          POPW %fp
0000696c: 08                                             RET
0000696d: 70                                             NOP
0000696e: 70                                             NOP
0000696f: 70                                             NOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Routine
;;

00006970: 10 49                                          SAVE %fp
00006972: 9c 4f 10 00 00 00 4c                           ADDW2 &0x10,%sp
00006979: 3f 01 ef a0 04 00 00                           CMPB &0x1,*$0x4a0
00006980: 77 0f                                          BNEB &0xf <0x698f>
00006982: 3c 4f f0 ff 00 00 7f 08 05 00 00               CMPW &0xfff0,$0x508
0000698d: 7f 26                                          BEB &0x26 <0x69b3>
0000698f: 84 4f 52 6c 00 00 7f f8 11 00 02               MOVW &0x6c52,$0x20011f8
0000699a: 70                                             NOP
0000699b: 84 4f 9e 6c 00 00 7f d8 12 00 02               MOVW &0x6c9e,$0x20012d8
000069a6: 70                                             NOP
000069a7: 84 7f d8 12 00 02 7f f4 11 00 02               MOVW $0x20012d8,$0x20011f4
000069b2: 70                                             NOP
000069b3: 3c 4f d0 f1 02 3b 7f 6c 08 00 02               CMPW &0x3b02f1d0,$0x200086c
000069be: 7f 55                                          BEB &0x55 <0x6a13>
000069c0: 84 4f d0 f1 02 3b 7f 6c 08 00 02               MOVW &0x3b02f1d0,$0x200086c
000069cb: 70                                             NOP
000069cc: 84 ef e4 04 00 00 59                           MOVW *$0x4e4,(%fp)
000069d3: 70                                             NOP
000069d4: dc 4f 00 00 00 02 ef e4 04 00 00 40            ADDW3 &0x2000000,*$0x4e4,%r0
000069e0: bc ef e8 04 00 00 40                           SUBW2 *$0x4e8,%r0
000069e7: d4 02 40 40                                    LRSW3 &0x2,%r0,%r0
000069eb: 84 40 59                                       MOVW %r0,(%fp)
000069ee: 70                                             NOP
000069ef: 84 ef e8 04 00 00 40                           MOVW *$0x4e8,%r0
000069f6: 80 50                                          CLRW (%r0)
000069f8: 70                                             NOP
000069f9: a0 59                                          PUSHW (%fp)
000069fb: dc 04 ef e8 04 00 00 40                        ADDW3 &0x4,*$0x4e8,%r0
00006a03: a0 40                                          PUSHW %r0
00006a05: a0 ef e8 04 00 00                              PUSHW *$0x4e8
00006a0b: 2c cc f4 7f 84 40 00 00                        CALL -12(%sp),$0x4084
00006a13: 83 7f 0d 90 04 00                              CLRB $0x4900d
00006a19: 70                                             NOP
00006a1a: 87 08 7f 0f 90 04 00                           MOVB &0x8,$0x4900f
00006a21: 70                                             NOP
00006a22: 2c 5c 7f 72 5f 00 00                           CALL (%sp),$0x5f72
00006a29: a0 00                                          PUSHW &0x0
00006a2b: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
00006a33: 2b ef a0 04 00 00                              TSTB *$0x4a0
00006a39: 7f 0f                                          BEB &0xf <0x6a48>
00006a3b: 3c 4f 00 80 00 00 7f 08 05 00 00               CMPW &0x8000,$0x508
00006a46: 43 10                                          BGEB &0x10 <0x6a56>
00006a48: 84 4f ef be ed fe ef 8c 04 00 00               MOVW &0xfeedbeef,*$0x48c
00006a53: 70                                             NOP
00006a54: 7b 0e                                          BRB &0xe <0x6a62>
00006a56: 84 4f ed 0d 1c a1 ef 8c 04 00 00               MOVW &0xa11c0ded,*$0x48c
00006a61: 70                                             NOP
00006a62: 84 4f 00 40 00 02 64                           MOVW &0x2004000,4(%fp)
00006a69: 70                                             NOP
00006a6a: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006a72: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
00006a76: d4 04 40 40                                    LRSW3 &0x4,%r0,%r0
00006a7a: 87 40 69                                       MOVB %r0,9(%fp)
00006a7d: 70                                             NOP
00006a7e: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006a86: 3f 01 50                                       CMPB &0x1,(%r0)
00006a89: 77 4a                                          BNEB &0x4a <0x6ad3>
00006a8b: 87 01 7f 1f 40 04 00                           MOVB &0x1,$0x4401f
00006a92: 70                                             NOP
00006a93: a0 00                                          PUSHW &0x0
00006a95: 2c cc fc 7f 2c 73 00 00                        CALL -4(%sp),$0x732c
00006a9d: 28 40                                          TSTW %r0
00006a9f: 77 0a                                          BNEB &0xa <0x6aa9>
00006aa1: 80 40                                          CLRW %r0
00006aa3: 24 7f 4b 6c 00 00                              JMP $0x6c4b
00006aa9: a0 00                                          PUSHW &0x0
00006aab: a0 7f a8 0a 00 02                              PUSHW $0x2000aa8
00006ab1: a0 4f 00 40 00 02                              PUSHW &0x2004000
00006ab7: a0 00                                          PUSHW &0x0
00006ab9: 2c cc f0 7f 98 76 00 00                        CALL -16(%sp),$0x7698
00006ac1: 28 40                                          TSTW %r0
00006ac3: 77 0a                                          BNEB &0xa <0x6acd>
00006ac5: 80 40                                          CLRW %r0
00006ac7: 24 7f 4b 6c 00 00                              JMP $0x6c4b
00006acd: 24 7f 99 6b 00 00                              JMP $0x6b99
00006ad3: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006adb: 3f 02 50                                       CMPB &0x2,(%r0)
00006ade: 77 46                                          BNEB &0x46 <0x6b24>
00006ae0: 87 01 7f 1f 40 04 00                           MOVB &0x1,$0x4401f
00006ae7: 70                                             NOP
00006ae8: a0 01                                          PUSHW &0x1
00006aea: 2c cc fc 7f 2c 73 00 00                        CALL -4(%sp),$0x732c
00006af2: 28 40                                          TSTW %r0
00006af4: 77 0a                                          BNEB &0xa <0x6afe>
00006af6: 80 40                                          CLRW %r0
00006af8: 24 7f 4b 6c 00 00                              JMP $0x6c4b
00006afe: a0 01                                          PUSHW &0x1
00006b00: a0 7f fc 0a 00 02                              PUSHW $0x2000afc
00006b06: a0 4f 00 40 00 02                              PUSHW &0x2004000
00006b0c: a0 00                                          PUSHW &0x0
00006b0e: 2c cc f0 7f 98 76 00 00                        CALL -16(%sp),$0x7698
00006b16: 28 40                                          TSTW %r0
00006b18: 77 0a                                          BNEB &0xa <0x6b22>
00006b1a: 80 40                                          CLRW %r0
00006b1c: 24 7f 4b 6c 00 00                              JMP $0x6c4b
00006b22: 7b 77                                          BRB &0x77 <0x6b99>
00006b24: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006b2c: 2b 50                                          TSTB (%r0)
00006b2e: 77 2b                                          BNEB &0x2b <0x6b59>
00006b30: a0 00                                          PUSHW &0x0
00006b32: a0 4f 00 40 00 02                              PUSHW &0x2004000
00006b38: a0 00                                          PUSHW &0x0
00006b3a: a0 00                                          PUSHW &0x0
00006b3c: 2c cc f0 7f 2c 7b 00 00                        CALL -16(%sp),$0x7b2c
00006b44: 28 40                                          TSTW %r0
00006b46: 77 11                                          BNEB &0x11 <0x6b57>
00006b48: 2c 5c 7f 34 7a 00 00                           CALL (%sp),$0x7a34
00006b4f: 80 40                                          CLRW %r0
00006b51: 24 7f 4b 6c 00 00                              JMP $0x6c4b
00006b57: 7b 42                                          BRB &0x42 <0x6b99>
00006b59: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006b61: fb 0f 50 40                                    ANDB3 &0xf,(%r0),%r0
00006b65: 87 40 68                                       MOVB %r0,8(%fp)
00006b68: 70                                             NOP
00006b69: 87 69 e0 40                                    MOVB 9(%fp),{uword}%r0
00006b6d: a0 40                                          PUSHW %r0
00006b6f: 87 68 e0 40                                    MOVB 8(%fp),{uword}%r0
00006b73: a0 40                                          PUSHW %r0
00006b75: 2c cc f8 7f ce 5a 00 00                        CALL -8(%sp),$0x5ace
00006b7d: 84 40 64                                       MOVW %r0,4(%fp)
00006b80: 70                                             NOP
00006b81: 28 64                                          TSTW 4(%fp)
00006b83: 77 16                                          BNEB &0x16 <0x6b99>
00006b85: 87 69 e0 40                                    MOVB 9(%fp),{uword}%r0
00006b89: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00006b8d: 83 c0 05                                       CLRB 5(%r0)
00006b90: 70                                             NOP
00006b91: 80 40                                          CLRW %r0
00006b93: 24 7f 4b 6c 00 00                              JMP $0x6c4b
00006b99: a0 00                                          PUSHW &0x0
00006b9b: 2c cc fc ef 1c 05 00 00                        CALL -4(%sp),*$0x51c
00006ba3: 28 40                                          TSTW %r0
00006ba5: 7f 47                                          BEB &0x47 <0x6bec>
00006ba7: a0 01                                          PUSHW &0x1
00006ba9: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
00006bb1: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006bb9: 2b 50                                          TSTB (%r0)
00006bbb: 77 0b                                          BNEB &0xb <0x6bc6>
00006bbd: 2c 5c 7f 34 7a 00 00                           CALL (%sp),$0x7a34
00006bc4: 7b 12                                          BRB &0x12 <0x6bd6>
00006bc6: 2b 69                                          TSTB 9(%fp)
00006bc8: 7f 0e                                          BEB &0xe <0x6bd6>
00006bca: 87 69 e0 40                                    MOVB 9(%fp),{uword}%r0
00006bce: d0 15 40 40                                    LLSW3 &0x15,%r0,%r0
00006bd2: 83 c0 05                                       CLRB 5(%r0)
00006bd5: 70                                             NOP
00006bd6: 3c 4f ef be ed fe 7f 64 08 00 02               CMPW &0xfeedbeef,$0x2000864
00006be1: 77 06                                          BNEB &0x6 <0x6be7>
00006be3: 80 40                                          CLRW %r0
00006be5: 7b 05                                          BRB &0x5 <0x6bea>
00006be7: 84 01 40                                       MOVW &0x1,%r0
00006bea: 7b 61                                          BRB &0x61 <0x6c4b>
00006bec: dc 04 64 40                                    ADDW3 &0x4,4(%fp),%r0
00006bf0: 3c 50 d9 04                                    CMPW (%r0),*4(%fp)
00006bf4: 77 20                                          BNEB &0x20 <0x6c14>
00006bf6: dc 04 64 40                                    ADDW3 &0x4,4(%fp),%r0
00006bfa: dc 08 64 41                                    ADDW3 &0x8,4(%fp),%r1
00006bfe: 3c 51 50                                       CMPW (%r1),(%r0)
00006c01: 77 13                                          BNEB &0x13 <0x6c14>
00006c03: dc 08 64 40                                    ADDW3 &0x8,4(%fp),%r0
00006c07: dc 0c 64 41                                    ADDW3 &0xc,4(%fp),%r1
00006c0b: 3c 51 50                                       CMPW (%r1),(%r0)
00006c0e: 77 06                                          BNEB &0x6 <0x6c14>
00006c10: 80 40                                          CLRW %r0
00006c12: 7b 39                                          BRB &0x39 <0x6c4b>
00006c14: 2c 5c d9 04                                    CALL (%sp),*4(%fp)
00006c18: dc 01 7f a0 04 00 00 40                        ADDW3 &0x1,$0x4a0,%r0
00006c20: 2b 50                                          TSTB (%r0)
00006c22: 77 09                                          BNEB &0x9 <0x6c2b>
00006c24: 2c 5c 7f 34 7a 00 00                           CALL (%sp),$0x7a34
00006c2b: a0 01                                          PUSHW &0x1
00006c2d: 2c cc fc ef 40 05 00 00                        CALL -4(%sp),*$0x540
00006c35: 3c 4f ef be ed fe 7f 64 08 00 02               CMPW &0xfeedbeef,$0x2000864
00006c40: 77 06                                          BNEB &0x6 <0x6c46>
00006c42: 80 40                                          CLRW %r0
00006c44: 7b 05                                          BRB &0x5 <0x6c49>
00006c46: 84 01 40                                       MOVW &0x1,%r0
00006c49: 7b 02                                          BRB &0x2 <0x6c4b>
00006c4b: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00006c4f: 20 49                                          POPW %fp
00006c51: 08                                             RET


00006c52: 10 49                                          SAVE %fp
00006c54: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
;; Print the string "FW-ERROR 1-%s"
00006c5b: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
;; Print the string "04: UNEXPECTED INTERRUPT"
00006c61: a0 4f bc 10 00 00                              PUSHW &0x10bc
00006c67: 2c cc f8 ef b0 04 00 00                        CALL -8(%sp),*$0x4b0
;; Print the string "EXECUTION HALTED"
00006c6f: a0 4f 9c 0d 00 00                              PUSHW &0xd9c
00006c75: 2c cc fc ef b0 04 00 00                        CALL -4(%sp),*$0x4b0
00006c7d: a0 5f 80 00                                    PUSHW &0x80
00006c81: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00006c89: a0 4f ef be ed fe                              PUSHW &0xfeedbeef
00006c8f: 2c cc fc 7f 22 63 00 00                        CALL -4(%sp),$0x6322
00006c97: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00006c9b: 20 49                                          POPW %fp
00006c9d: 08                                             RET


00006c9e: 10 49                                          SAVE %fp
00006ca0: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
;; Print the string "03: UNEXPECTED FAULT"
00006ca7: a0 4f 8c 0d 00 00                              PUSHW &0xd8c
00006cad: a0 4f d5 10 00 00                              PUSHW &0x10d5
;; Print the string "EXECUTION HALTED"
00006cb3: 2c cc f8 ef b0 04 00 00                        CALL -8(%sp),*$0x4b0
00006cbb: a0 4f 9c 0d 00 00                              PUSHW &0xd9c
00006cc1: 2c cc fc ef b0 04 00 00                        CALL -4(%sp),*$0x4b0
00006cc9: a0 6f 40                                       PUSHW &0x40
00006ccc: 2c cc fc 7f c0 61 00 00                        CALL -4(%sp),$0x61c0
00006cd4: a0 4f ef be ed fe                              PUSHW &0xfeedbeef
00006cda: 2c cc fc 7f 22 63 00 00                        CALL -4(%sp),$0x6322
00006ce2: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00006ce6: 20 49                                          POPW %fp
00006ce8: 08                                             RET
00006ce9: 70                                             NOP
00006cea: 70                                             NOP
00006ceb: 70                                             NOP


00006cec: 10 49                                          SAVE %fp
00006cee: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00006cf5: ec 4f 00 00 01 00 5a 40                        DIVW3 &0x10000,(%ap),%r0
00006cfd: 86 e2 7a e0 41                                 MOVH {uhalf}10(%ap),{uword}%r1
00006d02: 9c 5a 41                                       ADDW2 (%ap),%r1
00006d05: bc 01 41                                       SUBW2 &0x1,%r1
00006d08: ac e0 4f 00 00 01 00 41                        DIVW2 {uword}&0x10000,%r1
00006d10: 3c 41 40                                       CMPW %r1,%r0
00006d13: 53 0a                                          BGEUB &0xa <0x6d1d>
00006d15: 80 40                                          CLRW %r0
00006d17: 24 7f 1f 6e 00 00                              JMP $0x6e1f
00006d1d: 83 7f 0d 80 04 00                              CLRB $0x4800d
00006d23: 70                                             NOP
00006d24: 83 7f 08 80 04 00                              CLRB $0x48008
00006d2a: 70                                             NOP
00006d2b: 83 7f 0c 80 04 00                              CLRB $0x4800c
00006d31: 70                                             NOP
00006d32: 3b 77 01                                       BITB 7(%ap),&0x1
00006d35: 7f 35                                          BEB &0x35 <0x6d6a>
00006d37: 87 73 7f 02 80 04 00                           MOVB 3(%ap),$0x48002
00006d3e: 70                                             NOP
00006d3f: 87 72 7f 02 80 04 00                           MOVB 2(%ap),$0x48002
00006d46: 70                                             NOP
00006d47: 3b 77 08                                       BITB 7(%ap),&0x8
00006d4a: 7f 12                                          BEB &0x12 <0x6d5c>
00006d4c: f3 5f 80 00 71 40                              ORB3 &0x80,1(%ap),%r0
00006d52: 87 40 7f 03 e0 04 00                           MOVB %r0,$0x4e003
00006d59: 70                                             NOP
00006d5a: 7b 0e                                          BRB &0xe <0x6d68>
00006d5c: f3 00 71 40                                    ORB3 &0x0,1(%ap),%r0
00006d60: 87 40 7f 03 e0 04 00                           MOVB %r0,$0x4e003
00006d67: 70                                             NOP
00006d68: 7b 33                                          BRB &0x33 <0x6d9b>
00006d6a: 87 73 7f 00 80 04 00                           MOVB 3(%ap),$0x48000
00006d71: 70                                             NOP
00006d72: 87 72 7f 00 80 04 00                           MOVB 2(%ap),$0x48000
00006d79: 70                                             NOP
00006d7a: 3b 77 08                                       BITB 7(%ap),&0x8
00006d7d: 7f 12                                          BEB &0x12 <0x6d8f>
00006d7f: f3 5f 80 00 71 40                              ORB3 &0x80,1(%ap),%r0
00006d85: 87 40 7f 03 50 04 00                           MOVB %r0,$0x45003
00006d8c: 70                                             NOP
00006d8d: 7b 0e                                          BRB &0xe <0x6d9b>
00006d8f: f3 00 71 40                                    ORB3 &0x0,1(%ap),%r0
00006d93: 87 40 7f 03 50 04 00                           MOVB %r0,$0x45003
00006d9a: 70                                             NOP
00006d9b: 83 7f 0c 80 04 00                              CLRB $0x4800c
00006da1: 70                                             NOP
00006da2: 3b 77 01                                       BITB 7(%ap),&0x1
00006da5: 7f 2e                                          BEB &0x2e <0x6dd3>
00006da7: ff 01 7b 40                                    SUBB3 &0x1,11(%ap),%r0
00006dab: bb 5f ff 00 40                                 ANDB2 &0xff,%r0
00006db0: 87 40 7f 03 80 04 00                           MOVB %r0,$0x48003
00006db7: 70                                             NOP
00006db8: 86 e2 7a e0 40                                 MOVH {uhalf}10(%ap),{uword}%r0
00006dbd: bc 01 40                                       SUBW2 &0x1,%r0
00006dc0: d4 08 40 40                                    LRSW3 &0x8,%r0,%r0
00006dc4: bb 5f ff 00 40                                 ANDB2 &0xff,%r0
00006dc9: 87 40 7f 03 80 04 00                           MOVB %r0,$0x48003
00006dd0: 70                                             NOP
00006dd1: 7b 2c                                          BRB &0x2c <0x6dfd>
00006dd3: ff 01 7b 40                                    SUBB3 &0x1,11(%ap),%r0
00006dd7: bb 5f ff 00 40                                 ANDB2 &0xff,%r0
00006ddc: 87 40 7f 01 80 04 00                           MOVB %r0,$0x48001
00006de3: 70                                             NOP
00006de4: 86 e2 7a e0 40                                 MOVH {uhalf}10(%ap),{uword}%r0
00006de9: bc 01 40                                       SUBW2 &0x1,%r0
00006dec: d4 08 40 40                                    LRSW3 &0x8,%r0,%r0
00006df0: bb 5f ff 00 40                                 ANDB2 &0xff,%r0
00006df5: 87 40 7f 01 80 04 00                           MOVB %r0,$0x48001
00006dfc: 70                                             NOP
00006dfd: 87 77 7f 0b 80 04 00                           MOVB 7(%ap),$0x4800b
00006e04: 70                                             NOP
00006e05: fb 03 77 40                                    ANDB3 &0x3,7(%ap),%r0
00006e09: 9f 01 40                                       ADDB2 &0x1,%r0
00006e0c: 8b 40 40                                       MCOMB %r0,%r0
00006e0f: bb 0f 40                                       ANDB2 &0xf,%r0
00006e12: 87 40 7f 0f 80 04 00                           MOVB %r0,$0x4800f
00006e19: 70                                             NOP
00006e1a: 84 01 40                                       MOVW &0x1,%r0
00006e1d: 7b 02                                          BRB &0x2 <0x6e1f>
00006e1f: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00006e23: 20 49                                          POPW %fp
00006e25: 08                                             RET
00006e26: 70                                             NOP
00006e27: 70                                             NOP


00006e28: 10 44                                          SAVE %r4
00006e2a: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00006e31: 83 7f f0 14 00 02                              CLRB $0x20014f0
00006e37: 70                                             NOP
00006e38: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00006e3d: 84 5f 00 02 80 a4 0a 00 02                     MOVW &0x200,0x2000aa4(%r0)
00006e46: 70                                             NOP
00006e47: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00006e4c: 84 12 80 a0 0a 00 02                           MOVW &0x12,0x2000aa0(%r0)
00006e53: 70                                             NOP
00006e54: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00006e59: 84 04 80 9c 0a 00 02                           MOVW &0x4,0x2000a9c(%r0)
00006e60: 70                                             NOP
00006e61: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00006e66: 84 5f 32 01 80 98 0a 00 02                     MOVW &0x132,0x2000a98(%r0)
00006e6f: 70                                             NOP
00006e70: 80 7f 7c 0a 00 02                              CLRW $0x2000a7c
00006e76: 70                                             NOP
00006e77: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00006e7b: a0 40                                          PUSHW %r0
00006e7d: a0 00                                          PUSHW &0x0
00006e7f: a0 4f 74 08 00 02                              PUSHW &0x2000874
00006e85: a0 00                                          PUSHW &0x0
;; Access the hard drive.
00006e87: 2c cc f0 7f 98 76 00 00                        CALL -16(%sp),$0x7698
;; If %r0
00006e8f: 28 40                                          TSTW %r0
00006e91: 77 16                                          BNEB &0x16 <0x6ea7>
00006e93: 84 4f 00 00 01 00 7f 7c 0a 00 02               MOVW &0x10000,$0x2000a7c
00006e9e: 70                                             NOP
00006e9f: 80 40                                          CLRW %r0
00006ea1: 24 7f ec 70 00 00                              JMP $0x70ec
00006ea7: 3c 4f 0d 60 5e ca 7f 78 08 00 02               CMPW &0xca5e600d,$0x2000878
00006eb2: 7f 16                                          BEB &0x16 <0x6ec8>
00006eb4: 84 4f 00 00 02 00 7f 7c 0a 00 02               MOVW &0x20000,$0x2000a7c
00006ebf: 70                                             NOP
00006ec0: 80 40                                          CLRW %r0
00006ec2: 24 7f ec 70 00 00                              JMP $0x70ec
00006ec8: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00006ecd: 9c 4f 80 0a 00 02 40                           ADDW2 &0x2000a80,%r0
00006ed4: 84 40 48                                       MOVW %r0,%r8
00006ed7: 84 4f 74 08 00 02 47                           MOVW &0x2000874,%r7
00006ede: 82 46                                          CLRH %r6
00006ee0: 7b 12                                          BRB &0x12 <0x6ef2>
00006ee2: 84 48 40                                       MOVW %r8,%r0
00006ee5: 90 48                                          INCW %r8
00006ee7: 84 47 41                                       MOVW %r7,%r1
00006eea: 90 47                                          INCW %r7
00006eec: 87 51 50                                       MOVB (%r1),(%r0)
00006eef: 70                                             NOP
00006ef0: 92 46                                          INCH %r6
00006ef2: 86 e2 46 e0 40                                 MOVH {uhalf}%r6,{uword}%r0
00006ef7: 3c 6f 54 40                                    CMPW &0x54,%r0
00006efb: 5b e7                                          BLUB &0xe7 <0x6ee2>
00006efd: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00006f01: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00006f05: eb 6f 54 73 41                                 MULB3 &0x54,3(%ap),%r1
00006f0a: eb 6f 54 73 42                                 MULB3 &0x54,3(%ap),%r2
00006f0f: ec e0 82 a4 0a 00 02 81 c0 0a 00 02 41         DIVW3 {uword}0x2000aa4(%r2),0x2000ac0(%r1),%r1
00006f1c: 86 41 80 e8 14 00 02                           MOVH %r1,0x20014e8(%r0)
00006f23: 70                                             NOP
00006f24: 82 46                                          CLRH %r6
00006f26: 7b 1e                                          BRB &0x1e <0x6f44>
00006f28: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00006f2c: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
00006f30: 9c 4f e8 12 00 02 40                           ADDW2 &0x20012e8,%r0
00006f37: 86 e2 46 e0 41                                 MOVH {uhalf}%r6,{uword}%r1
00006f3c: 9c 41 40                                       ADDW2 %r1,%r0
00006f3f: 83 50                                          CLRB (%r0)
00006f41: 70                                             NOP
00006f42: 92 46                                          INCH %r6
00006f44: 86 e2 46 e0 40                                 MOVH {uhalf}%r6,{uword}%r0
00006f49: 3c 5f 00 01 40                                 CMPW &0x100,%r0
00006f4e: 5b da                                          BLUB &0xda <0x6f28>
00006f50: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00006f55: ec e0 08 80 a4 0a 00 02 40                     DIVW3 {uword}&0x8,0x2000aa4(%r0),%r0
00006f5e: 86 40 44                                       MOVH %r0,%r4
00006f61: 87 5f ff 00 7f 71 08 00 02                     MOVB &0xff,$0x2000871
00006f6a: 70                                             NOP
00006f6b: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00006f6f: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00006f73: 82 80 ec 14 00 02                              CLRH 0x20014ec(%r0)
00006f79: 70                                             NOP
00006f7a: 24 7f 8b 70 00 00                              JMP $0x708b
00006f80: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00006f84: a0 40                                          PUSHW %r0
00006f86: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00006f8b: 87 73 e0 41                                    MOVB 3(%ap),{uword}%r1
00006f8f: d0 01 41 41                                    LLSW3 &0x1,%r1,%r1
00006f93: 86 e2 81 ec 14 00 02 e0 41                     MOVH {uhalf}0x20014ec(%r1),{uword}%r1
00006f9c: dc 41 80 bc 0a 00 02 40                        ADDW3 %r1,0x2000abc(%r0),%r0
00006fa4: a0 40                                          PUSHW %r0
00006fa6: a0 4f 74 08 00 02                              PUSHW &0x2000874
00006fac: a0 00                                          PUSHW &0x0
00006fae: 2c cc f0 7f 98 76 00 00                        CALL -16(%sp),$0x7698
00006fb6: 28 40                                          TSTW %r0
00006fb8: 77 2a                                          BNEB &0x2a <0x6fe2>
00006fba: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00006fbe: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00006fc2: 86 e2 80 ec 14 00 02 e0 40                     MOVH {uhalf}0x20014ec(%r0),{uword}%r0
00006fcb: 9c 06 40                                       ADDW2 &0x6,%r0
00006fce: d0 10 40 40                                    LLSW3 &0x10,%r0,%r0
00006fd2: 84 40 7f 7c 0a 00 02                           MOVW %r0,$0x2000a7c
00006fd9: 70                                             NOP
00006fda: 80 40                                          CLRW %r0
00006fdc: 24 7f ec 70 00 00                              JMP $0x70ec
00006fe2: 82 45                                          CLRH %r5
00006fe4: 7b 77                                          BRB &0x77 <0x705b>
00006fe6: 86 e2 45 e0 40                                 MOVH {uhalf}%r5,{uword}%r0
00006feb: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00006fef: 3f 5f ff 00 80 74 08 00 02                     CMPB &0xff,0x2000874(%r0)
00006ff8: 77 04                                          BNEB &0x4 <0x6ffc>
00006ffa: 7b 71                                          BRB &0x71 <0x706b>
00006ffc: 86 e2 45 e0 40                                 MOVH {uhalf}%r5,{uword}%r0
00007001: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00007005: 87 80 74 08 00 02 e0 40                        MOVB 0x2000874(%r0),{uword}%r0
0000700d: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
00007011: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
00007016: 86 e2 45 e0 41                                 MOVH {uhalf}%r5,{uword}%r1
0000701b: d0 03 41 41                                    LLSW3 &0x3,%r1,%r1
0000701f: 87 81 75 08 00 02 e0 41                        MOVB 0x2000875(%r1),{uword}%r1
00007027: 9c 41 40                                       ADDW2 %r1,%r0
0000702a: 86 40 46                                       MOVH %r0,%r6
0000702d: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007031: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
00007035: 9c 4f e8 12 00 02 40                           ADDW2 &0x20012e8,%r0
0000703c: 86 e2 46 e0 41                                 MOVH {uhalf}%r6,{uword}%r1
00007041: ac e0 08 41                                    DIVW2 {uword}&0x8,%r1
00007045: 9c 41 40                                       ADDW2 %r1,%r0
00007048: 86 e2 46 e0 41                                 MOVH {uhalf}%r6,{uword}%r1
0000704d: a4 e0 08 41                                    MODW2 {uword}&0x8,%r1
00007051: d0 41 01 41                                    LLSW3 %r1,&0x1,%r1
00007055: b3 41 50                                       ORB2 %r1,(%r0)
00007058: 70                                             NOP
00007059: 92 45                                          INCH %r5
0000705b: 86 e2 45 e0 40                                 MOVH {uhalf}%r5,{uword}%r0
00007060: 86 e2 44 e0 41                                 MOVH {uhalf}%r4,{uword}%r1
00007065: 3c 41 40                                       CMPW %r1,%r0
00007068: 5a 7e ff                                       BLUH &0xff7e <0x6fe6>
0000706b: 86 e2 45 e0 40                                 MOVH {uhalf}%r5,{uword}%r0
00007070: 86 e2 44 e0 41                                 MOVH {uhalf}%r4,{uword}%r1
00007075: 3c 41 40                                       CMPW %r1,%r0
00007078: 53 04                                          BGEUB &0x4 <0x707c>
0000707a: 7b 39                                          BRB &0x39 <0x70b3>
0000707c: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007080: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00007084: 92 80 ec 14 00 02                              INCH 0x20014ec(%r0)
0000708a: 70                                             NOP
0000708b: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
0000708f: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00007093: 86 e2 80 ec 14 00 02 e0 40                     MOVH {uhalf}0x20014ec(%r0),{uword}%r0
0000709c: 87 73 e0 41                                    MOVB 3(%ap),{uword}%r1
000070a0: d0 01 41 41                                    LLSW3 &0x1,%r1,%r1
000070a4: 86 e2 81 e8 14 00 02 e0 41                     MOVH {uhalf}0x20014e8(%r1),{uword}%r1
000070ad: 3c 41 40                                       CMPW %r1,%r0
000070b0: 5a d0 fe                                       BLUH &0xfed0 <0x6f80>
000070b3: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
000070b7: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
000070bb: 87 73 e0 41                                    MOVB 3(%ap),{uword}%r1
000070bf: d0 01 41 41                                    LLSW3 &0x1,%r1,%r1
000070c3: 86 e2 81 e8 14 00 02 e0 41                     MOVH {uhalf}0x20014e8(%r1),{uword}%r1
000070cc: be 01 41                                       SUBH2 &0x1,%r1
000070cf: 86 41 80 ec 14 00 02                           MOVH %r1,0x20014ec(%r0)
000070d6: 70                                             NOP
000070d7: 87 73 7f 71 08 00 02                           MOVB 3(%ap),$0x2000871
000070de: 70                                             NOP
000070df: 87 01 7f f0 14 00 02                           MOVB &0x1,$0x20014f0
000070e6: 70                                             NOP
000070e7: 84 01 40                                       MOVW &0x1,%r0
000070ea: 7b 02                                          BRB &0x2 <0x70ec>
000070ec: 04 c9 fc 4c                                    MOVAW -4(%fp),%sp
000070f0: 20 48                                          POPW %r8
000070f2: 20 47                                          POPW %r7
000070f4: 20 46                                          POPW %r6
000070f6: 20 45                                          POPW %r5
000070f8: 20 44                                          POPW %r4
000070fa: 20 49                                          POPW %fp
000070fc: 08                                             RET
000070fd: 70                                             NOP
000070fe: 70                                             NOP
000070ff: 70                                             NOP


00007100: 10 48                                          SAVE %r8
00007102: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00007109: 2b 7f f0 14 00 02                              TSTB $0x20014f0
0000710f: 77 0b                                          BNEB &0xb <0x711a>
00007111: 84 01 40                                       MOVW &0x1,%r0
00007114: 24 7f 22 73 00 00                              JMP $0x7322
0000711a: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
0000711f: 3c 4f 0d 60 5e ca 80 84 0a 00 02               CMPW &0xca5e600d,0x2000a84(%r0)
0000712a: 7f 0a                                          BEB &0xa <0x7134>
0000712c: 80 40                                          CLRW %r0
0000712e: 24 7f 22 73 00 00                              JMP $0x7322
00007134: 87 da 04 e0 40                                 MOVB *4(%ap),{uword}%r0
00007139: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
0000713d: dc 01 74 41                                    ADDW3 &0x1,4(%ap),%r1
00007141: 87 51 e2 41                                    MOVB (%r1),{uhalf}%r1
00007145: 9e 41 40                                       ADDH2 %r1,%r0
00007148: 86 40 48                                       MOVH %r0,%r8
0000714b: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
0000714f: d0 08 40 40                                    LLSW3 &0x8,%r0,%r0
00007153: 9c 4f e8 12 00 02 40                           ADDW2 &0x20012e8,%r0
0000715a: 86 48 e4 41                                    MOVH %r8,{word}%r1
0000715e: ac 08 41                                       DIVW2 &0x8,%r1
00007161: 9c 41 40                                       ADDW2 %r1,%r0
00007164: 87 50 e0 40                                    MOVB (%r0),{uword}%r0
00007168: 86 48 e4 41                                    MOVH %r8,{word}%r1
0000716c: a4 08 41                                       MODW2 &0x8,%r1
0000716f: d0 41 01 41                                    LLSW3 %r1,&0x1,%r1
00007173: 38 40 41                                       BITW %r0,%r1
00007176: 77 0b                                          BNEB &0xb <0x7181>
00007178: 84 01 40                                       MOVW &0x1,%r0
0000717b: 24 7f 22 73 00 00                              JMP $0x7322
00007181: 3f 73 7f 71 08 00 02                           CMPB 3(%ap),$0x2000871
00007188: 7f 46                                          BEB &0x46 <0x71ce>
0000718a: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
0000718e: a0 40                                          PUSHW %r0
00007190: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00007195: a0 80 bc 0a 00 02                              PUSHW 0x2000abc(%r0)
0000719b: a0 4f 74 08 00 02                              PUSHW &0x2000874
000071a1: a0 00                                          PUSHW &0x0
000071a3: 2c cc f0 7f 98 76 00 00                        CALL -16(%sp),$0x7698
000071ab: 28 40                                          TSTW %r0
000071ad: 77 0a                                          BNEB &0xa <0x71b7>
000071af: 80 40                                          CLRW %r0
000071b1: 24 7f 22 73 00 00                              JMP $0x7322
000071b7: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
000071bb: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
000071bf: 82 80 ec 14 00 02                              CLRH 0x20014ec(%r0)
000071c5: 70                                             NOP
000071c6: 87 73 7f 71 08 00 02                           MOVB 3(%ap),$0x2000871
000071cd: 70                                             NOP
000071ce: 3c da 04 7f 74 08 00 02                        CMPW *4(%ap),$0x2000874
000071d6: 57 08                                          BGUB &0x8 <0x71de>
000071d8: 24 7f 70 72 00 00                              JMP $0x7270
000071de: 7b 6f                                          BRB &0x6f <0x724d>
000071e0: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
000071e4: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
000071e8: 86 e2 80 ec 14 00 02 e0 40                     MOVH {uhalf}0x20014ec(%r0),{uword}%r0
000071f1: 77 0b                                          BNEB &0xb <0x71fc>
000071f3: 84 01 40                                       MOVW &0x1,%r0
000071f6: 24 7f 22 73 00 00                              JMP $0x7322
000071fc: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007200: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00007204: 96 80 ec 14 00 02                              DECH 0x20014ec(%r0)
0000720a: 70                                             NOP
0000720b: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
0000720f: a0 40                                          PUSHW %r0
00007211: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00007216: 87 73 e0 41                                    MOVB 3(%ap),{uword}%r1
0000721a: d0 01 41 41                                    LLSW3 &0x1,%r1,%r1
0000721e: 86 e2 81 ec 14 00 02 e0 41                     MOVH {uhalf}0x20014ec(%r1),{uword}%r1
00007227: dc 41 80 bc 0a 00 02 40                        ADDW3 %r1,0x2000abc(%r0),%r0
0000722f: a0 40                                          PUSHW %r0
00007231: a0 4f 74 08 00 02                              PUSHW &0x2000874
00007237: a0 00                                          PUSHW &0x0
00007239: 2c cc f0 7f 98 76 00 00                        CALL -16(%sp),$0x7698
00007241: 28 40                                          TSTW %r0
00007243: 77 0a                                          BNEB &0xa <0x724d>
00007245: 80 40                                          CLRW %r0
00007247: 24 7f 22 73 00 00                              JMP $0x7322
0000724d: 3c da 04 7f 74 08 00 02                        CMPW *4(%ap),$0x2000874
00007255: 57 8b                                          BGUB &0x8b <0x71e0>
00007257: a0 74                                          PUSHW 4(%ap)
00007259: a0 4f 74 08 00 02                              PUSHW &0x2000874
0000725f: 2c cc f8 7f d6 7d 00 00                        CALL -8(%sp),$0x7dd6
00007267: 84 01 40                                       MOVW &0x1,%r0
0000726a: 24 7f 22 73 00 00                              JMP $0x7322
00007270: a0 74                                          PUSHW 4(%ap)
00007272: a0 4f 74 08 00 02                              PUSHW &0x2000874
00007278: 2c cc f8 7f d6 7d 00 00                        CALL -8(%sp),$0x7dd6
00007280: 28 40                                          TSTW %r0
00007282: 7f 0b                                          BEB &0xb <0x728d>
00007284: 84 01 40                                       MOVW &0x1,%r0
00007287: 24 7f 22 73 00 00                              JMP $0x7322
0000728d: 7b 68                                          BRB &0x68 <0x72f5>
0000728f: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007293: a0 40                                          PUSHW %r0
00007295: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
0000729a: 87 73 e0 41                                    MOVB 3(%ap),{uword}%r1
0000729e: d0 01 41 41                                    LLSW3 &0x1,%r1,%r1
000072a2: 86 e2 81 ec 14 00 02 e0 41                     MOVH {uhalf}0x20014ec(%r1),{uword}%r1
000072ab: dc 41 80 bc 0a 00 02 40                        ADDW3 %r1,0x2000abc(%r0),%r0
000072b3: a0 40                                          PUSHW %r0
000072b5: a0 4f 74 08 00 02                              PUSHW &0x2000874
000072bb: a0 00                                          PUSHW &0x0
000072bd: 2c cc f0 7f 98 76 00 00                        CALL -16(%sp),$0x7698
000072c5: 28 40                                          TSTW %r0
000072c7: 77 06                                          BNEB &0x6 <0x72cd>
000072c9: 80 40                                          CLRW %r0
000072cb: 7b 57                                          BRB &0x57 <0x7322>
000072cd: a0 74                                          PUSHW 4(%ap)
000072cf: a0 4f 74 08 00 02                              PUSHW &0x2000874
000072d5: 2c cc f8 7f d6 7d 00 00                        CALL -8(%sp),$0x7dd6
000072dd: 28 40                                          TSTW %r0
000072df: 7f 07                                          BEB &0x7 <0x72e6>
000072e1: 84 01 40                                       MOVW &0x1,%r0
000072e4: 7b 3e                                          BRB &0x3e <0x7322>
000072e6: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
000072ea: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
000072ee: 92 80 ec 14 00 02                              INCH 0x20014ec(%r0)
000072f4: 70                                             NOP
000072f5: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
000072f9: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
000072fd: 86 e2 80 ec 14 00 02 e0 40                     MOVH {uhalf}0x20014ec(%r0),{uword}%r0
00007306: 87 73 e0 41                                    MOVB 3(%ap),{uword}%r1
0000730a: d0 01 41 41                                    LLSW3 &0x1,%r1,%r1
0000730e: 86 e2 81 e8 14 00 02 e0 41                     MOVH {uhalf}0x20014e8(%r1),{uword}%r1
00007317: 3c 41 40                                       CMPW %r1,%r0
0000731a: 5a 75 ff                                       BLUH &0xff75 <0x728f>
0000731d: 84 01 40                                       MOVW &0x1,%r0
00007320: 7b 02                                          BRB &0x2 <0x7322>
00007322: 04 c9 ec 4c                                    MOVAW -20(%fp),%sp
00007326: 20 48                                          POPW %r8
00007328: 20 49                                          POPW %fp
0000732a: 08                                             RET
0000732b: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Procedure
;;

0000732c: 10 49                                          SAVE %fp
0000732e: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00007335: 87 01 7f 01 a0 04 00                           MOVB &0x1,$0x4a001
0000733c: 70                                             NOP
0000733d: a0 01                                          PUSHW &0x1
0000733f: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00007347: a0 20                                          PUSHW &0x20
00007349: a0 4f 74 0a 00 02                              PUSHW &0x2000a74
0000734f: a0 08                                          PUSHW &0x8
00007351: 2c cc f4 af 83 00                              CALL -12(%sp),0x83(%pc)
00007357: 28 40                                          TSTW %r0
00007359: 7f 1b                                          BEB &0x1b <0x7374>
0000735b: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
0000735f: a0 40                                          PUSHW %r0
00007361: 2c cc fc af 1f 00                              CALL -4(%sp),0x1f(%pc)
00007367: 28 40                                          TSTW %r0
00007369: 7f 07                                          BEB &0x7 <0x7370>
0000736b: 84 01 40                                       MOVW &0x1,%r0
0000736e: 7b 0a                                          BRB &0xa <0x7378>
00007370: 80 40                                          CLRW %r0
00007372: 7b 06                                          BRB &0x6 <0x7378>
00007374: 80 40                                          CLRW %r0
00007376: 7b 02                                          BRB &0x2 <0x7378>
00007378: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
0000737c: 20 49                                          POPW %fp
0000737e: 08                                             RET
0000737f: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Procedure
;;

00007380: 10 49                                          SAVE %fp
00007382: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00007389: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
0000738d: a0 40                                          PUSHW %r0
0000738f: 2c cc fc af a1 02                              CALL -4(%sp),0x2a1(%pc)
00007395: 28 40                                          TSTW %r0
00007397: 77 06                                          BNEB &0x6 <0x739d>
00007399: 80 40                                          CLRW %r0
0000739b: 7b 31                                          BRB &0x31 <0x73cc>
0000739d: f3 6f 58 73 40                                 ORB3 &0x58,3(%ap),%r0
000073a2: a0 40                                          PUSHW %r0
000073a4: a0 00                                          PUSHW &0x0
000073a6: a0 00                                          PUSHW &0x0
000073a8: 2c cc f4 af 2c 00                              CALL -12(%sp),0x2c(%pc)
000073ae: f3 6f 58 73 40                                 ORB3 &0x58,3(%ap),%r0
000073b3: a0 40                                          PUSHW %r0
000073b5: a0 00                                          PUSHW &0x0
000073b7: a0 00                                          PUSHW &0x0
000073b9: 2c cc f4 af 1b 00                              CALL -12(%sp),0x1b(%pc)
000073bf: 28 40                                          TSTW %r0
000073c1: 7f 07                                          BEB &0x7 <0x73c8>
000073c3: 84 01 40                                       MOVW &0x1,%r0
000073c6: 7b 06                                          BRB &0x6 <0x73cc>
000073c8: 80 40                                          CLRW %r0
000073ca: 7b 02                                          BRB &0x2 <0x73cc>
000073cc: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000073d0: 20 49                                          POPW %fp
000073d2: 08                                             RET
000073d3: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Procedure, but something to do with accessing the hard disk.
;;

000073d4: 10 49                                          SAVE %fp
000073d6: 9c 4f 08 00 00 00 4c                           ADDW2 &0x8,%sp
000073dd: 70                                             NOP

;; Save the current PSW into 20014FC
000073de: 84 4b 7f fc 14 00 02                           MOVW %psw,$0x20014fc
000073e5: 70                                             NOP
000073e6: 70                                             NOP
000073e7: b0 4f 00 e1 01 00 4b                           ORW2 &0x1e100,%psw

;; Read the disk controller status.
000073ee: 87 7f 01 a0 04 00 e0 40                        MOVB $0x4a001,{uword}%r0
000073f6: 84 40 7f d4 12 00 02                           MOVW %r0,$0x20012d4
000073fd: 70                                             NOP

;; If the controller available, GOTO 742D
000073fe: 38 40 5f 80 00                                 BITW %r0,&0x80
00007403: 7f 2a                                          BEB &0x2a <0x742d>

;; If the controller is busy, move the argument into R0
00007405: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0

;; Shift it left 24 (0x18) bits (so it occupies the top byte)
00007409: d0 18 40 40                                    LLSW3 &0x18,%r0,%r0
0000740d: b0 40 7f d4 12 00 02                           ORW2 %r0,$0x20012d4
00007414: 70                                             NOP

;;
00007415: 87 08 7f 01 a0 04 00                           MOVB &0x8,$0x4a001
0000741c: 70                                             NOP
0000741d: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw
00007424: 84 00 40                                       MOVW &0x0,%r0
00007427: 24 7f 26 76 00 00                              JMP $0x7626


;; Send a CLEAR BUFFER
0000742d: 87 02 7f 01 a0 04 00                           MOVB &0x2,$0x4a001
00007434: 70                                             NOP
;; Send a CLEAR CE BITS
00007435: 87 08 7f 01 a0 04 00                           MOVB &0x8,$0x4a001
0000743c: 70                                             NOP
;; GOTO 0x7450
0000743d: 7b 13                                          BRB &0x13 <0x7450>


0000743f: 84 74 40                                       MOVW 4(%ap),%r0
00007442: 90 74                                          INCW 4(%ap)
00007444: 70                                             NOP

;; Write to data buffer
;; (e.g., write 00 then 48
00007445: 87 50 7f 00 a0 04 00                           MOVB (%r0),$0x4a000
0000744c: 70                                             NOP
0000744d: 97 7b                                          DECB 11(%ap)
0000744f: 70                                             NOP

;;
00007450: 2b 7b                                          TSTB 11(%ap)
00007452: 77 ed                                          BNEB &0xed <0x743f>

;; Disk Command
00007454: 87 73 7f 01 a0 04 00                           MOVB 3(%ap),$0x4a001
0000745b: 70                                             NOP
0000745c: 82 59                                          CLRH (%fp)
0000745e: 70                                             NOP
0000745f: 7b 0f                                          BRB &0xf <0x746e>
00007461: a0 01                                          PUSHW &0x1
00007463: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
0000746b: 92 59                                          INCH (%fp)
0000746d: 70                                             NOP
0000746e: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
00007473: 3c 5f c8 00 40                                 CMPW &0xc8,%r0
00007478: 53 0d                                          BGEUB &0xd <0x7485>
0000747a: 3b 7f 01 a0 04 00 5f 80 00                     BITB $0x4a001,&0x80
00007483: 77 de                                          BNEB &0xde <0x7461>
00007485: 87 7f 01 a0 04 00 e0 40                        MOVB $0x4a001,{uword}%r0
0000748d: 84 40 7f d4 12 00 02                           MOVW %r0,$0x20012d4
00007494: 70                                             NOP
;; Is the controller busy? If so jump to 74c4
00007495: 38 40 5f 80 00                                 BITW %r0,&0x80
0000749a: 7f 2a                                          BEB &0x2a <0x74c4>
;; It's not, so...
0000749c: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
000074a0: d0 18 40 40                                    LLSW3 &0x18,%r0,%r0
000074a4: b0 40 7f d4 12 00 02                           ORW2 %r0,$0x20012d4
000074ab: 70                                             NOP
000074ac: 87 08 7f 01 a0 04 00                           MOVB &0x8,$0x4a001
000074b3: 70                                             NOP
000074b4: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw
000074bb: 84 00 40                                       MOVW &0x0,%r0
;; Just return.
000074be: 24 7f 26 76 00 00                              JMP $0x7626

;; Are any of the top bits set in our argument?
000074c4: 3b 73 5f f0 00                                 BITB 3(%ap),&0xf0
000074c9: 7f 2a                                          BEB &0x2a <0x74f3>
000074cb: 82 59                                          CLRH (%fp)
000074cd: 70                                             NOP
000074ce: 7b 0f                                          BRB &0xf <0x74dd>
000074d0: a0 01                                          PUSHW &0x1
000074d2: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
000074da: 92 59                                          INCH (%fp)
000074dc: 70                                             NOP
000074dd: 86 e2 59 e0 40                                 MOVH {uhalf}(%fp),{uword}%r0
000074e2: 3c 05 40                                       CMPW &0x5,%r0
000074e5: 53 0c                                          BGEUB &0xc <0x74f1>
000074e7: 3b 7f 01 a0 04 00 6f 60                        BITB $0x4a001,&0x60
000074ef: 7f e1                                          BEB &0xe1 <0x74d0>
000074f1: 7b 21                                          BRB &0x21 <0x7512>
000074f3: 80 7f d4 12 00 02                              CLRW $0x20012d4
000074f9: 70                                             NOP
000074fa: 87 08 7f 01 a0 04 00                           MOVB &0x8,$0x4a001
00007501: 70                                             NOP
00007502: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw
00007509: 84 01 40                                       MOVW &0x1,%r0
0000750c: 24 7f 26 76 00 00                              JMP $0x7626
00007512: 87 7f 01 a0 04 00 e0 40                        MOVB $0x4a001,{uword}%r0
0000751a: 84 40 7f d4 12 00 02                           MOVW %r0,$0x20012d4
00007521: 70                                             NOP

;; Check for CE flags
00007522: b8 6f 60 40                                    ANDW2 &0x60,%r0
00007526: 3c 6f 40 40                                    CMPW &0x40,%r0
;; If CEH/CEL != 0x40, go to 7532
0000752a: 77 08                                          BNEB &0x8 <0x7532>

;; GOTO 0x75b7
0000752c: 24 7f b7 75 00 00                              JMP $0x75b7
00007532: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007536: d0 18 40 40                                    LLSW3 &0x18,%r0,%r0
0000753a: 87 7f 00 a0 04 00 e0 41                        MOVB $0x4a000,{uword}%r1
00007542: d0 08 41 41                                    LLSW3 &0x8,%r1,%r1
00007546: b0 41 40                                       ORW2 %r1,%r0
00007549: b0 40 7f d4 12 00 02                           ORW2 %r0,$0x20012d4
00007550: 70                                             NOP
00007551: 38 7f d4 12 00 02 5f 00 20                     BITW $0x20012d4,&0x2000
0000755a: 7f 11                                          BEB &0x11 <0x756b>
0000755c: 3b 73 5f b0 00                                 BITB 3(%ap),&0xb0
00007561: 7f 0a                                          BEB &0xa <0x756b>
00007563: 87 01 7f 00 15 00 02                           MOVB &0x1,$0x2001500
0000756a: 70                                             NOP
0000756b: 38 7f d4 12 00 02 08                           BITW $0x20012d4,&0x8
00007572: 7f 31                                          BEB &0x31 <0x75a3>
00007574: 84 7f d4 12 00 02 64                           MOVW $0x20012d4,4(%fp)
0000757b: 70                                             NOP
0000757c: fb 01 73 40                                    ANDB3 &0x1,3(%ap),%r0
00007580: a0 40                                          PUSHW %r0
00007582: 2c cc fc af aa fd                              CALL -4(%sp),0x..fdaa(%pc)
00007588: 28 40                                          TSTW %r0
0000758a: 7f 11                                          BEB &0x11 <0x759b>
0000758c: fb 01 73 40                                    ANDB3 &0x1,3(%ap),%r0
00007590: b4 01 40                                       XORW2 &0x1,%r0
00007593: a0 40                                          PUSHW %r0
00007595: 2c cc fc af eb fd                              CALL -4(%sp),0x..fdeb(%pc)
0000759b: 84 64 7f d4 12 00 02                           MOVW 4(%fp),$0x20012d4
000075a2: 70                                             NOP
000075a3: 87 08 7f 01 a0 04 00                           MOVB &0x8,$0x4a001
000075aa: 70                                             NOP
000075ab: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw
000075b2: 84 00 40                                       MOVW &0x0,%r0
000075b5: 7b 71                                          BRB &0x71 <0x7626>


000075b7: 38 7f d4 12 00 02 08                           BITW $0x20012d4,&0x8
000075be: 7f 4d                                          BEB &0x4d <0x760b>
000075c0: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
000075c4: d0 18 40 40                                    LLSW3 &0x18,%r0,%r0
000075c8: b0 40 7f d4 12 00 02                           ORW2 %r0,$0x20012d4
000075cf: 70                                             NOP
000075d0: 84 7f d4 12 00 02 64                           MOVW $0x20012d4,4(%fp)
000075d7: 70                                             NOP
000075d8: fb 01 73 40                                    ANDB3 &0x1,3(%ap),%r0
000075dc: a0 40                                          PUSHW %r0
000075de: 2c cc fc af 4e fd                              CALL -4(%sp),0x..fd4e(%pc)
000075e4: 28 40                                          TSTW %r0
000075e6: 7f 11                                          BEB &0x11 <0x75f7>
000075e8: fb 01 73 40                                    ANDB3 &0x1,3(%ap),%r0
000075ec: b4 01 40                                       XORW2 &0x1,%r0
000075ef: a0 40                                          PUSHW %r0
000075f1: 2c cc fc af 8f fd                              CALL -4(%sp),0x..fd8f(%pc)
000075f7: 84 64 7f d4 12 00 02                           MOVW 4(%fp),$0x20012d4
000075fe: 70                                             NOP
000075ff: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw
00007606: 84 00 40                                       MOVW &0x0,%r0
00007609: 7b 1d                                          BRB &0x1d <0x7626>
0000760b: 87 08 7f 01 a0 04 00                           MOVB &0x8,$0x4a001
00007612: 70                                             NOP
00007613: 80 7f d4 12 00 02                              CLRW $0x20012d4
00007619: 70                                             NOP
0000761a: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw

;; Why are we flagging R0?
00007621: 84 01 40                                       MOVW &0x1,%r0
00007624: 7b 02                                          BRB &0x2 <0x7626>

00007626: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
0000762a: 20 49                                          POPW %fp
0000762c: 08                                             RET
0000762d: 70                                             NOP
0000762e: 70                                             NOP
0000762f: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Procedure
;;

00007630: 10 49                                          SAVE %fp
00007632: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00007639: f3 30 73 40                                    ORB3 &0x30,3(%ap),%r0
0000763d: a0 40                                          PUSHW %r0
0000763f: a0 00                                          PUSHW &0x0
00007641: a0 00                                          PUSHW &0x0
00007643: 2c cc f4 af 91 fd                              CALL -12(%sp),0x..fd91(%pc)
00007649: 28 40                                          TSTW %r0
0000764b: 77 06                                          BNEB &0x6 <0x7651>
0000764d: 80 40                                          CLRW %r0
0000764f: 7b 40                                          BRB &0x40 <0x768f>
00007651: 87 7f 00 a0 04 00 e0 40                        MOVB $0x4a000,{uword}%r0
00007659: 84 40 7f d4 12 00 02                           MOVW %r0,$0x20012d4
00007660: 70                                             NOP
00007661: 38 40 02                                       BITW %r0,&0x2
00007664: 7f 0e                                          BEB &0xe <0x7672>
00007666: 80 7f d4 12 00 02                              CLRW $0x20012d4
0000766c: 70                                             NOP
0000766d: 84 01 40                                       MOVW &0x1,%r0
00007670: 7b 1f                                          BRB &0x1f <0x768f>
00007672: d0 10 7f d4 12 00 02 7f d4 12 00 02            LLSW3 &0x10,$0x20012d4,$0x20012d4
0000767e: 70                                             NOP
0000767f: b0 4f 00 00 00 30 7f d4 12 00 02               ORW2 &0x30000000,$0x20012d4
0000768a: 70                                             NOP
0000768b: 80 40                                          CLRW %r0
0000768d: 7b 02                                          BRB &0x2 <0x768f>
0000768f: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007693: 20 49                                          POPW %fp
00007695: 08                                             RET
00007696: 70                                             NOP
00007697: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'hd_acs' - Routine to access hard disk
;;

;; Here, argument 1 seems to get some kind of failure code if we can't
;; access the hard drive -- I'm trying to figure out what that is.

00007698: 10 49                                          SAVE %fp
0000769a: 9c 4f 14 00 00 00 4c                           ADDW2 &0x14,%sp
000076a1: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
000076a6: eb 6f 54 73 41                                 MULB3 &0x54,3(%ap),%r1
000076ab: e8 81 a0 0a 00 02 80 9c 0a 00 02 40            MULW3 0x2000aa0(%r1),0x2000a9c(%r0),%r0
000076b7: ec e0 40 74 40                                 DIVW3 {uword}%r0,4(%ap),%r0
000076bc: 84 40 64                                       MOVW %r0,4(%fp)
000076bf: 70                                             NOP
000076c0: eb 6f 54 73 41                                 MULB3 &0x54,3(%ap),%r1
000076c5: 3c 81 98 0a 00 02 40                           CMPW 0x2000a98(%r1),%r0
000076cc: 5b 0a                                          BLUB &0xa <0x76d6>
000076ce: 80 40                                          CLRW %r0
000076d0: 24 7f 79 78 00 00                              JMP $0x7879
000076d6: d4 08 64 40                                    LRSW3 &0x8,4(%fp),%r0
000076da: bb 5f ff 00 40                                 ANDB2 &0xff,%r0
000076df: 87 40 6c                                       MOVB %r0,12(%fp)
000076e2: 70                                             NOP
000076e3: fb 5f ff 00 67 40                              ANDB3 &0xff,7(%fp),%r0
000076e9: 87 40 6d                                       MOVB %r0,13(%fp)
000076ec: 70                                             NOP
000076ed: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
000076f2: eb 6f 54 73 41                                 MULB3 &0x54,3(%ap),%r1
000076f7: e8 81 a0 0a 00 02 80 9c 0a 00 02 40            MULW3 0x2000aa0(%r1),0x2000a9c(%r0),%r0
00007703: e4 e0 40 74 40                                 MODW3 {uword}%r0,4(%ap),%r0
00007708: 84 40 59                                       MOVW %r0,(%fp)
0000770b: 70                                             NOP
0000770c: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00007711: ec e0 80 a0 0a 00 02 59 40                     DIVW3 {uword}0x2000aa0(%r0),(%fp),%r0
0000771a: 87 40 6e                                       MOVB %r0,14(%fp)
0000771d: 70                                             NOP
0000771e: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00007723: e4 e0 80 a0 0a 00 02 59 40                     MODW3 {uword}0x2000aa0(%r0),(%fp),%r0
0000772c: 87 40 c9 0f                                    MOVB %r0,15(%fp)
00007730: 70                                             NOP
00007731: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007735: a0 40                                          PUSHW %r0
00007737: e0 6c                                          PUSHAW 12(%fp)
;; Call 0x7100
00007739: 2c cc f8 7f 00 71 00 00                        CALL -8(%sp),$0x7100
00007741: 28 40                                          TSTW %r0
00007743: 77 0a                                          BNEB &0xa <0x774d>
00007745: 80 40                                          CLRW %r0
00007747: 24 7f 79 78 00 00                              JMP $0x7879
0000774d: 3f 07 6e                                       CMPB &0x7,14(%fp)
00007750: 5f 0d                                          BLEUB &0xd <0x775d>
00007752: df 02 73 40                                    ADDB3 &0x2,3(%ap),%r0
00007756: 87 40 c9 11                                    MOVB %r0,17(%fp)
0000775a: 70                                             NOP
0000775b: 7b 07                                          BRB &0x7 <0x7762>
0000775d: 87 73 c9 11                                    MOVB 3(%ap),17(%fp)
00007761: 70                                             NOP
00007762: 82 68                                          CLRH 8(%fp)
00007764: 70                                             NOP
00007765: 24 7f 43 78 00 00                              JMP $0x7843
0000776b: 86 e2 68 e0 40                                 MOVH {uhalf}8(%fp),{uword}%r0
00007770: 7f 10                                          BEB &0x10 <0x7780>
00007772: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007776: a0 40                                          PUSHW %r0
;; Call 0x7380
00007778: 2c cc fc 7f 80 73 00 00                        CALL -4(%sp),$0x7380
00007780: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007784: a0 40                                          PUSHW %r0
00007786: e0 6c                                          PUSHAW 12(%fp)
;; Call 0x7880
00007788: 2c cc f8 af f8 00                              CALL -8(%sp),0xf8(%pc)
0000778e: 28 40                                          TSTW %r0
00007790: 77 08                                          BNEB &0x8 <0x7798>
00007792: 24 7f 40 78 00 00                              JMP $0x7840
00007798: 87 6e 7f f4 14 00 02                           MOVB 14(%fp),$0x20014f4
0000779f: 70                                             NOP
000077a0: 8b 6c 40                                       MCOMB 12(%fp),%r0
000077a3: 87 40 7f f5 14 00 02                           MOVB %r0,$0x20014f5
000077aa: 70                                             NOP
000077ab: 87 6d 7f f6 14 00 02                           MOVB 13(%fp),$0x20014f6
000077b2: 70                                             NOP
000077b3: 87 6e 7f f7 14 00 02                           MOVB 14(%fp),$0x20014f7
000077ba: 70                                             NOP
000077bb: 87 c9 0f 7f f8 14 00 02                        MOVB 15(%fp),$0x20014f8
000077c3: 70                                             NOP
000077c4: 87 01 7f f9 14 00 02                           MOVB &0x1,$0x20014f9
000077cb: 70                                             NOP
000077cc: 2b ca 0f                                       TSTB 15(%ap)
000077cf: 77 07                                          BNEB &0x7 <0x77d6>
000077d1: 84 04 40                                       MOVW &0x4,%r0
000077d4: 7b 05                                          BRB &0x5 <0x77d9>
000077d6: 84 08 40                                       MOVW &0x8,%r0
000077d9: b3 00 40                                       ORB2 &0x0,%r0
000077dc: 87 40 c9 10                                    MOVB %r0,16(%fp)
000077e0: 70                                             NOP
000077e1: a0 78                                          PUSHW 8(%ap)
000077e3: 87 c9 10 e0 40                                 MOVB 16(%fp),{uword}%r0
000077e8: a0 40                                          PUSHW %r0
000077ea: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
000077ef: a0 80 a4 0a 00 02                              PUSHW 0x2000aa4(%r0)
;; Call 0x6cec
000077f5: 2c cc f4 7f ec 6c 00 00                        CALL -12(%sp),$0x6cec
000077fd: 28 40                                          TSTW %r0
000077ff: 77 06                                          BNEB &0x6 <0x7805>
00007801: 80 40                                          CLRW %r0
00007803: 7b 76                                          BRB &0x76 <0x7879>
00007805: 83 7f 00 15 00 02                              CLRB $0x2001500
0000780b: 70                                             NOP
0000780c: 2b ca 0f                                       TSTB 15(%ap)
0000780f: 77 09                                          BNEB &0x9 <0x7818>
00007811: 84 5f b0 00 40                                 MOVW &0xb0,%r0
00007816: 7b 07                                          BRB &0x7 <0x781d>
00007818: 84 5f f0 00 40                                 MOVW &0xf0,%r0
0000781d: 87 c9 11 e0 41                                 MOVB 17(%fp),{uword}%r1
00007822: b0 41 40                                       ORW2 %r1,%r0
00007825: a0 40                                          PUSHW %r0
00007827: a0 4f f4 14 00 02                              PUSHW &0x20014f4
0000782d: a0 06                                          PUSHW &0x6
0000782f: 2c cc f4 7f d4 73 00 00                        CALL -12(%sp),$0x73d4
00007837: 28 40                                          TSTW %r0
00007839: 7f 07                                          BEB &0x7 <0x7840>
0000783b: 84 01 40                                       MOVW &0x1,%r0
0000783e: 7b 3b                                          BRB &0x3b <0x7879>
00007840: 92 68                                          INCH 8(%fp)
00007842: 70                                             NOP
00007843: 86 e2 68 e0 40                                 MOVH {uhalf}8(%fp),{uword}%r0
00007848: 3c 10 40                                       CMPW &0x10,%r0
0000784b: 5a 20 ff                                       BLUH &0xff20 <0x776b>
0000784e: 2b 7f 00 15 00 02                              TSTB $0x2001500
00007854: 7f 21                                          BEB &0x21 <0x7875>
00007856: a0 4f f4 10 00 00                              PUSHW &0x10f4
0000785c: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
00007860: a0 40                                          PUSHW %r0
00007862: a0 6c                                          PUSHW 12(%fp)
00007864: a0 10                                          PUSHW &0x10
00007866: 2c cc f0 ef b0 04 00 00                        CALL -16(%sp),*$0x4b0
0000786e: 83 7f 00 15 00 02                              CLRB $0x2001500
00007874: 70                                             NOP
00007875: 80 40                                          CLRW %r0
00007877: 7b 02                                          BRB &0x2 <0x7879>
00007879: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
0000787d: 20 49                                          POPW %fp
0000787f: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Procedure

00007880: 10 49                                          SAVE %fp
00007882: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00007889: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
0000788d: a0 40                                          PUSHW %r0
0000788f: 2c cc fc 7f 30 76 00 00                        CALL -4(%sp),$0x7630
00007897: 28 40                                          TSTW %r0
00007899: 77 06                                          BNEB &0x6 <0x789f>
0000789b: 80 40                                          CLRW %r0
0000789d: 7b 30                                          BRB &0x30 <0x78cd>
0000789f: 87 da 04 7f f4 14 00 02                        MOVB *4(%ap),$0x20014f4
000078a7: 70                                             NOP
000078a8: dc 01 74 40                                    ADDW3 &0x1,4(%ap),%r0
000078ac: 87 50 7f f5 14 00 02                           MOVB (%r0),$0x20014f5
000078b3: 70                                             NOP
000078b4: f3 6f 68 73 40                                 ORB3 &0x68,3(%ap),%r0
000078b9: a0 40                                          PUSHW %r0
000078bb: a0 4f f4 14 00 02                              PUSHW &0x20014f4
000078c1: a0 02                                          PUSHW &0x2
000078c3: 2c cc f4 7f d4 73 00 00                        CALL -12(%sp),$0x73d4
000078cb: 7b 02                                          BRB &0x2 <0x78cd>
000078cd: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
000078d1: 20 49                                          POPW %fp
000078d3: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown Procedure

000078d4: 10 49                                          SAVE %fp
000078d6: 9c 4f 0c 00 00 00 4c                           ADDW2 &0xc,%sp
000078dd: 84 4f 74 08 00 02 68                           MOVW &0x2000874,8(%fp)
000078e4: 70                                             NOP
000078e5: 87 5f ff 00 7f 71 08 00 02                     MOVB &0xff,$0x2000871
000078ee: 70                                             NOP
000078ef: 87 73 e0 40                                    MOVB 3(%ap),{uword}%r0
000078f3: a0 40                                          PUSHW %r0
000078f5: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
000078fa: fc 01 80 98 0a 00 02 40                        SUBW3 &0x1,0x2000a98(%r0),%r0
00007902: eb 6f 54 73 41                                 MULB3 &0x54,3(%ap),%r1
00007907: a8 81 9c 0a 00 02 40                           MULW2 0x2000a9c(%r1),%r0
0000790e: eb 6f 54 73 41                                 MULB3 &0x54,3(%ap),%r1
00007913: a8 81 a0 0a 00 02 40                           MULW2 0x2000aa0(%r1),%r0
0000791a: a0 40                                          PUSHW %r0
0000791c: a0 68                                          PUSHW 8(%fp)
0000791e: a0 00                                          PUSHW &0x0
00007920: 2c cc f0 7f 98 76 00 00                        CALL -16(%sp),$0x7698
00007928: 28 40                                          TSTW %r0
0000792a: 77 06                                          BNEB &0x6 <0x7930>
0000792c: 80 40                                          CLRW %r0
0000792e: 7b 54                                          BRB &0x54 <0x7982>
00007930: 80 59                                          CLRW (%fp)
00007932: 70                                             NOP
00007933: 7b 38                                          BRB &0x38 <0x796b>
00007935: 80 64                                          CLRW 4(%fp)
00007937: 70                                             NOP
00007938: 7b 29                                          BRB &0x29 <0x7961>
0000793a: e4 02 59 40                                    MODW3 &0x2,(%fp),%r0
0000793e: 7f 0a                                          BEB &0xa <0x7948>
00007940: fc 64 5f ff 00 40                              SUBW3 4(%fp),&0xff,%r0
00007946: 7b 05                                          BRB &0x5 <0x794b>
00007948: 84 64 40                                       MOVW 4(%fp),%r0
0000794b: 84 68 41                                       MOVW 8(%fp),%r1
0000794e: 90 68                                          INCW 8(%fp)
00007950: 70                                             NOP
00007951: 87 51 e0 41                                    MOVB (%r1),{uword}%r1
00007955: 3c 40 41                                       CMPW %r0,%r1
00007958: 7f 06                                          BEB &0x6 <0x795e>
0000795a: 80 40                                          CLRW %r0
0000795c: 7b 26                                          BRB &0x26 <0x7982>
0000795e: 90 64                                          INCW 4(%fp)
00007960: 70                                             NOP
00007961: 3c 5f 00 01 64                                 CMPW &0x100,4(%fp)
00007966: 4b d4                                          BLB &0xd4 <0x793a>
00007968: 90 59                                          INCW (%fp)
0000796a: 70                                             NOP
0000796b: eb 6f 54 73 40                                 MULB3 &0x54,3(%ap),%r0
00007970: d4 08 80 a4 0a 00 02 40                        LRSW3 &0x8,0x2000aa4(%r0),%r0
00007978: 3c 40 59                                       CMPW %r0,(%fp)
0000797b: 5b ba                                          BLUB &0xba <0x7935>
0000797d: 84 01 40                                       MOVW &0x1,%r0
00007980: 7b 02                                          BRB &0x2 <0x7982>
00007982: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007986: 20 49                                          POPW %fp
00007988: 08                                             RET
00007989: 70                                             NOP
0000798a: 70                                             NOP
0000798b: 70                                             NOP
0000798c: 10 49                                          SAVE %fp
0000798e: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00007995: 87 10 7f 0e 90 04 00                           MOVB &0x10,$0x4900e
0000799c: 70                                             NOP
0000799d: 87 20 7f 0e 90 04 00                           MOVB &0x20,$0x4900e
000079a4: 70                                             NOP
000079a5: 86 e2 7f 02 40 04 00 e0 40                     MOVH {uhalf}$0x44002,{uword}%r0
000079ae: b8 5f 00 04 40                                 ANDW2 &0x400,%r0
000079b3: 3c 5f 00 04 40                                 CMPW &0x400,%r0
000079b8: 7f 16                                          BEB &0x16 <0x79ce>
000079ba: 87 01 7f 1b 40 04 00                           MOVB &0x1,$0x4401b
000079c1: 70                                             NOP
000079c2: a0 5f 2c 01                                    PUSHW &0x12c
000079c6: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
000079ce: a0 5f c8 00                                    PUSHW &0xc8
000079d2: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
000079da: 87 5f d0 00 7f 00 d0 04 00                     MOVB &0xd0,$0x4d000
000079e3: 70                                             NOP
000079e4: a0 01                                          PUSHW &0x1
000079e6: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
000079ee: 3b 7f 00 d0 04 00 5f 80 00                     BITB $0x4d000,&0x80
000079f7: 7f 0b                                          BEB &0xb <0x7a02>
000079f9: 2c 5c af 3b 00                                 CALL (%sp),0x3b(%pc)
000079fe: 80 40                                          CLRW %r0
00007a00: 7b 2d                                          BRB &0x2d <0x7a2d>
00007a02: 3f 01 73                                       CMPB &0x1,3(%ap)
00007a05: 77 07                                          BNEB &0x7 <0x7a0c>
00007a07: 84 04 40                                       MOVW &0x4,%r0
00007a0a: 7b 04                                          BRB &0x4 <0x7a0e>
00007a0c: 80 40                                          CLRW %r0
00007a0e: b0 08 40                                       ORW2 &0x8,%r0
00007a11: a0 40                                          PUSHW %r0
00007a13: a0 10                                          PUSHW &0x10
00007a15: 2c cc f8 af 47 00                              CALL -8(%sp),0x47(%pc)
00007a1b: 28 40                                          TSTW %r0
00007a1d: 7f 07                                          BEB &0x7 <0x7a24>
00007a1f: 84 01 40                                       MOVW &0x1,%r0
00007a22: 7b 0b                                          BRB &0xb <0x7a2d>
00007a24: 2c 5c af 10 00                                 CALL (%sp),0x10(%pc)
00007a29: 80 40                                          CLRW %r0
00007a2b: 7b 02                                          BRB &0x2 <0x7a2d>
00007a2d: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007a31: 20 49                                          POPW %fp
00007a33: 08                                             RET
00007a34: 10 49                                          SAVE %fp
00007a36: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00007a3d: 87 01 7f 1f 40 04 00                           MOVB &0x1,$0x4401f
00007a44: 70                                             NOP
00007a45: 87 10 7f 0f 90 04 00                           MOVB &0x10,$0x4900f
00007a4c: 70                                             NOP
00007a4d: 87 20 7f 0f 90 04 00                           MOVB &0x20,$0x4900f
00007a54: 70                                             NOP
00007a55: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007a59: 20 49                                          POPW %fp
00007a5b: 08                                             RET
00007a5c: 10 49                                          SAVE %fp
00007a5e: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00007a65: 3b 7f 00 d0 04 00 01                           BITB $0x4d000,&0x1
00007a6c: 7f 0a                                          BEB &0xa <0x7a76>
00007a6e: 80 40                                          CLRW %r0
00007a70: 24 7f 24 7b 00 00                              JMP $0x7b24
00007a76: 70                                             NOP
00007a77: 84 4b 7f fc 14 00 02                           MOVW %psw,$0x20014fc
00007a7e: 70                                             NOP
00007a7f: 70                                             NOP
00007a80: b0 4f 00 e1 01 00 4b                           ORW2 &0x1e100,%psw
00007a87: 87 73 7f 00 d0 04 00                           MOVB 3(%ap),$0x4d000
00007a8e: 70                                             NOP
00007a8f: a0 01                                          PUSHW &0x1
00007a91: a0 5f e6 00                                    PUSHW &0xe6
00007a95: 2c cc f8 7f 2c 55 00 00                        CALL -8(%sp),$0x552c
00007a9d: 80 59                                          CLRW (%fp)
00007a9f: 70                                             NOP
00007aa0: 7b 21                                          BRB &0x21 <0x7ac1>
00007aa2: 3c 6f 64 59                                    CMPW &0x64,(%fp)
00007aa6: 4f 0e                                          BLEB &0xe <0x7ab4>
00007aa8: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw
00007aaf: 84 00 40                                       MOVW &0x0,%r0
00007ab2: 7b 72                                          BRB &0x72 <0x7b24>
00007ab4: a0 01                                          PUSHW &0x1
00007ab6: 2c cc fc ef 28 05 00 00                        CALL -4(%sp),*$0x528
00007abe: 90 59                                          INCW (%fp)
00007ac0: 70                                             NOP
00007ac1: 3b 7f 00 d0 04 00 01                           BITB $0x4d000,&0x1
00007ac8: 77 da                                          BNEB &0xda <0x7aa2>
00007aca: fb 5f a0 00 73 40                              ANDB3 &0xa0,3(%ap),%r0
00007ad0: 3c 5f a0 00 40                                 CMPW &0xa0,%r0
00007ad5: 7f 0f                                          BEB &0xf <0x7ae4>
00007ad7: fb 5f f0 00 73 40                              ANDB3 &0xf0,3(%ap),%r0
00007add: 3c 5f f0 00 40                                 CMPW &0xf0,%r0
00007ae2: 77 10                                          BNEB &0x10 <0x7af2>
00007ae4: a0 01                                          PUSHW &0x1
00007ae6: a0 5f e6 00                                    PUSHW &0xe6
00007aea: 2c cc f8 7f 2c 55 00 00                        CALL -8(%sp),$0x552c
00007af2: 3b 7f 00 d0 04 00 77                           BITB $0x4d000,7(%ap)
00007af9: 7f 1f                                          BEB &0x1f <0x7b18>
00007afb: 3b 7f 00 d0 04 00 08                           BITB $0x4d000,&0x8
00007b02: 7f 0a                                          BEB &0xa <0x7b0c>
00007b04: 87 01 7f 00 15 00 02                           MOVB &0x1,$0x2001500
00007b0b: 70                                             NOP
00007b0c: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw
00007b13: 84 00 40                                       MOVW &0x0,%r0
00007b16: 7b 0e                                          BRB &0xe <0x7b24>
00007b18: 84 7f fc 14 00 02 4b                           MOVW $0x20014fc,%psw
00007b1f: 84 01 40                                       MOVW &0x1,%r0
00007b22: 7b 02                                          BRB &0x2 <0x7b24>
00007b24: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007b28: 20 49                                          POPW %fp
00007b2a: 08                                             RET
00007b2b: 70                                             NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'fd_acs' - Routine to access floppy disk
;;

00007b2c: 10 49                                          SAVE %fp
00007b2e: 9c 4f 0c 00 00 00 4c                           ADDW2 &0xc,%sp
00007b35: ec e0 12 5a 40                                 DIVW3 {uword}&0x12,(%ap),%r0
00007b3a: 3c 6f 50 40                                    CMPW &0x50,%r0
00007b3e: 5b 0a                                          BLUB &0xa <0x7b48>
00007b40: 80 40                                          CLRW %r0
00007b42: 24 7f 94 7d 00 00                              JMP $0x7d94
00007b48: 2b ca 0f                                       TSTB 15(%ap)
00007b4b: 7f 08                                          BEB &0x8 <0x7b53>
00007b4d: 3f 03 ca 0f                                    CMPB &0x3,15(%ap)
00007b51: 77 79                                          BNEB &0x79 <0x7bca>
00007b53: a0 01                                          PUSHW &0x1
00007b55: 2c cc fc 7f 8c 79 00 00                        CALL -4(%sp),$0x798c
00007b5d: 28 40                                          TSTW %r0
00007b5f: 77 0a                                          BNEB &0xa <0x7b69>
00007b61: 80 40                                          CLRW %r0
00007b63: 24 7f 94 7d 00 00                              JMP $0x7d94
00007b69: 87 5f ff 00 7f 71 08 00 02                     MOVB &0xff,$0x2000871
00007b72: 70                                             NOP
00007b73: 83 7f 70 08 00 02                              CLRB $0x2000870
00007b79: 70                                             NOP
00007b7a: a0 5f 8e 05                                    PUSHW &0x58e
00007b7e: a0 4f 74 08 00 02                              PUSHW &0x2000874
00007b84: a0 00                                          PUSHW &0x0
00007b86: a0 01                                          PUSHW &0x1
00007b88: 2c cc f0 cf a4                                 CALL -16(%sp),-92(%pc)
00007b8d: 28 40                                          TSTW %r0
00007b8f: 77 0a                                          BNEB &0xa <0x7b99>
00007b91: 80 40                                          CLRW %r0
00007b93: 24 7f 94 7d 00 00                              JMP $0x7d94
00007b99: 3c 4f 0d 60 5e ca 7f 78 08 00 02               CMPW &0xca5e600d,$0x2000878
00007ba4: 77 18                                          BNEB &0x18 <0x7bbc>
00007ba6: 86 7f b2 08 00 02 7f 02 15 00 02               MOVH $0x20008b2,$0x2001502
00007bb1: 70                                             NOP
00007bb2: 87 01 7f 70 08 00 02                           MOVB &0x1,$0x2000870
00007bb9: 70                                             NOP
00007bba: 7b 10                                          BRB &0x10 <0x7bca>
00007bbc: 82 7f 02 15 00 02                              CLRH $0x2001502
00007bc2: 70                                             NOP
00007bc3: 83 7f 70 08 00 02                              CLRB $0x2000870
00007bc9: 70                                             NOP
00007bca: 83 68                                          CLRB 8(%fp)
00007bcc: 70                                             NOP
00007bcd: ec e0 12 5a 40                                 DIVW3 {uword}&0x12,(%ap),%r0
00007bd2: 87 40 69                                       MOVB %r0,9(%fp)
00007bd5: 70                                             NOP
00007bd6: e4 e0 12 5a 40                                 MODW3 {uword}&0x12,(%ap),%r0
00007bdb: ac e0 09 40                                    DIVW2 {uword}&0x9,%r0
00007bdf: 87 40 6a                                       MOVB %r0,10(%fp)
00007be2: 70                                             NOP
00007be3: e4 e0 09 5a 40                                 MODW3 {uword}&0x9,(%ap),%r0
00007be8: 87 40 6b                                       MOVB %r0,11(%fp)
00007beb: 70                                             NOP
00007bec: 2b 7f 70 08 00 02                              TSTB $0x2000870
00007bf2: 7f 60                                          BEB &0x60 <0x7c52>
00007bf4: 3f 02 7f 71 08 00 02                           CMPB &0x2,$0x2000871
00007bfb: 7f 49                                          BEB &0x49 <0x7c44>
00007bfd: 87 5f ff 00 7f 71 08 00 02                     MOVB &0xff,$0x2000871
00007c06: 70                                             NOP
00007c07: 83 7f 70 08 00 02                              CLRB $0x2000870
00007c0d: 70                                             NOP
00007c0e: 86 7f 02 15 00 02 e4 40                        MOVH $0x2001502,{word}%r0
00007c16: a0 40                                          PUSHW %r0
00007c18: a0 4f 74 08 00 02                              PUSHW &0x2000874
00007c1e: a0 00                                          PUSHW &0x0
00007c20: a0 01                                          PUSHW &0x1
00007c22: 2c cc f0 af 0a ff                              CALL -16(%sp),0x..f0a(%pc)
00007c28: 28 40                                          TSTW %r0
00007c2a: 77 0a                                          BNEB &0xa <0x7c34>
00007c2c: 80 40                                          CLRW %r0
00007c2e: 24 7f 94 7d 00 00                              JMP $0x7d94
00007c34: 87 02 7f 71 08 00 02                           MOVB &0x2,$0x2000871
00007c3b: 70                                             NOP
00007c3c: 87 01 7f 70 08 00 02                           MOVB &0x1,$0x2000870
00007c43: 70                                             NOP
00007c44: e0 68                                          PUSHAW 8(%fp)
00007c46: a0 4f 74 08 00 02                              PUSHW &0x2000874
00007c4c: 2c cc f8 af 8a 01                              CALL -8(%sp),0x18a(%pc)
00007c52: 87 5f 9c 00 66                                 MOVB &0x9c,6(%fp)
00007c57: 70                                             NOP
00007c58: 3f 01 7b                                       CMPB &0x1,11(%ap)
00007c5b: 77 14                                          BNEB &0x14 <0x7c6f>
00007c5d: 87 6f 49 64                                    MOVB &0x49,4(%fp)
00007c61: 70                                             NOP
00007c62: 87 5f a0 00 65                                 MOVB &0xa0,5(%fp)
00007c67: 70                                             NOP
00007c68: b3 6f 40 66                                    ORB2 &0x40,6(%fp)
00007c6c: 70                                             NOP
00007c6d: 7b 0d                                          BRB &0xd <0x7c7a>
00007c6f: 87 6f 45 64                                    MOVB &0x45,4(%fp)
00007c73: 70                                             NOP
00007c74: 87 5f 80 00 65                                 MOVB &0x80,5(%fp)
00007c79: 70                                             NOP
00007c7a: 87 6a e0 40                                    MOVB 10(%fp),{uword}%r0
00007c7e: d0 01 40 40                                    LLSW3 &0x1,%r0,%r0
00007c82: b3 08 40                                       ORB2 &0x8,%r0
00007c85: b3 40 65                                       ORB2 %r0,5(%fp)
00007c88: 70                                             NOP
00007c89: 82 62                                          CLRH 2(%fp)
00007c8b: 70                                             NOP
00007c8c: 82 59                                          CLRH (%fp)
00007c8e: 70                                             NOP
00007c8f: 24 7f 30 7d 00 00                              JMP $0x7d30
00007c95: 87 69 e0 40                                    MOVB 9(%fp),{uword}%r0
00007c99: a0 40                                          PUSHW %r0
00007c9b: 2c cc fc af 01 01                              CALL -4(%sp),0x101(%pc)
00007ca1: 28 40                                          TSTW %r0
00007ca3: 77 1a                                          BNEB &0x1a <0x7cbd>
00007ca5: a0 01                                          PUSHW &0x1
00007ca7: 2c cc fc 7f 8c 79 00 00                        CALL -4(%sp),$0x798c
00007caf: 28 40                                          TSTW %r0
00007cb1: 77 0a                                          BNEB &0xa <0x7cbb>
00007cb3: 80 40                                          CLRW %r0
00007cb5: 24 7f 94 7d 00 00                              JMP $0x7d94
00007cbb: 7b 72                                          BRB &0x72 <0x7d2d>
00007cbd: df 01 6b 40                                    ADDB3 &0x1,11(%fp),%r0
00007cc1: 87 40 7f 02 d0 04 00                           MOVB %r0,$0x4d002
00007cc8: 70                                             NOP
00007cc9: a0 74                                          PUSHW 4(%ap)
00007ccb: 87 64 e0 40                                    MOVB 4(%fp),{uword}%r0
00007ccf: a0 40                                          PUSHW %r0
00007cd1: a0 5f 00 02                                    PUSHW &0x200
00007cd5: 2c cc f4 7f ec 6c 00 00                        CALL -12(%sp),$0x6cec
00007cdd: 28 40                                          TSTW %r0
00007cdf: 77 0a                                          BNEB &0xa <0x7ce9>
00007ce1: 80 40                                          CLRW %r0
00007ce3: 24 7f 94 7d 00 00                              JMP $0x7d94
00007ce9: 83 7f 00 15 00 02                              CLRB $0x2001500
00007cef: 70                                             NOP
00007cf0: 87 65 e0 40                                    MOVB 5(%fp),{uword}%r0
00007cf4: a0 40                                          PUSHW %r0
00007cf6: 87 66 e0 40                                    MOVB 6(%fp),{uword}%r0
00007cfa: a0 40                                          PUSHW %r0
00007cfc: 2c cc f8 7f 5c 7a 00 00                        CALL -8(%sp),$0x7a5c
00007d04: 28 40                                          TSTW %r0
00007d06: 7f 08                                          BEB &0x8 <0x7d0e>
00007d08: 86 01 62                                       MOVH &0x1,2(%fp)
00007d0b: 70                                             NOP
00007d0c: 7b 2a                                          BRB &0x2a <0x7d36>
00007d0e: 3b 7f 00 d0 04 00 5f 80 00                     BITB $0x4d000,&0x80
00007d17: 7f 04                                          BEB &0x4 <0x7d1b>
00007d19: 7b 1d                                          BRB &0x1d <0x7d36>
00007d1b: a0 01                                          PUSHW &0x1
00007d1d: 2c cc fc 7f 8c 79 00 00                        CALL -4(%sp),$0x798c
00007d25: 28 40                                          TSTW %r0
00007d27: 77 06                                          BNEB &0x6 <0x7d2d>
00007d29: 80 40                                          CLRW %r0
00007d2b: 7b 69                                          BRB &0x69 <0x7d94>
00007d2d: 92 59                                          INCH (%fp)
00007d2f: 70                                             NOP
00007d30: 3e 10 59                                       CMPH &0x10,(%fp)
00007d33: 4a 62 ff                                       BLH &0xff62 <0x7c95>
00007d36: 2b 7f 00 15 00 02                              TSTB $0x2001500
00007d3c: 7f 1b                                          BEB &0x1b <0x7d57>
00007d3e: a0 4f 28 11 00 00                              PUSHW &0x1128
00007d44: a0 68                                          PUSHW 8(%fp)
00007d46: a0 10                                          PUSHW &0x10
00007d48: 2c cc f4 ef b0 04 00 00                        CALL -12(%sp),*$0x4b0
00007d50: 83 7f 00 15 00 02                              CLRB $0x2001500
00007d56: 70                                             NOP
00007d57: 2a 62                                          TSTH 2(%fp)
00007d59: 7f 0e                                          BEB &0xe <0x7d67>
00007d5b: 3f 02 ca 0f                                    CMPB &0x2,15(%ap)
00007d5f: 7f 08                                          BEB &0x8 <0x7d67>
00007d61: 3f 03 ca 0f                                    CMPB &0x3,15(%ap)
00007d65: 77 29                                          BNEB &0x29 <0x7d8e>
00007d67: 2b 7f 70 08 00 02                              TSTB $0x2000870
00007d6d: 7f 1a                                          BEB &0x1a <0x7d87>
00007d6f: 83 7f 70 08 00 02                              CLRB $0x2000870
00007d75: 70                                             NOP
00007d76: 82 7f 02 15 00 02                              CLRH $0x2001502
00007d7c: 70                                             NOP
00007d7d: 87 5f ff 00 7f 71 08 00 02                     MOVB &0xff,$0x2000871
00007d86: 70                                             NOP
00007d87: 2c 5c 7f 34 7a 00 00                           CALL (%sp),$0x7a34
00007d8e: 86 62 e4 40                                    MOVH 2(%fp),{word}%r0
00007d92: 7b 02                                          BRB &0x2 <0x7d94>
00007d94: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007d98: 20 49                                          POPW %fp
00007d9a: 08                                             RET
00007d9b: 70                                             NOP


00007d9c: 10 49                                          SAVE %fp
00007d9e: 9c 4f 00 00 00 00 4c                           ADDW2 &0x0,%sp
00007da5: 3f 73 7f 01 d0 04 00                           CMPB 3(%ap),$0x4d001
00007dac: 77 07                                          BNEB &0x7 <0x7db3>
00007dae: 84 01 40                                       MOVW &0x1,%r0
00007db1: 7b 1d                                          BRB &0x1d <0x7dce>
00007db3: 87 73 7f 03 d0 04 00                           MOVB 3(%ap),$0x4d003
00007dba: 70                                             NOP
00007dbb: a0 1c                                          PUSHW &0x1c
00007dbd: a0 10                                          PUSHW &0x10
00007dbf: 2c cc f8 7f 5c 7a 00 00                        CALL -8(%sp),$0x7a5c
00007dc7: 86 e2 40 e0 40                                 MOVH {uhalf}%r0,{uword}%r0
00007dcc: 7b 02                                          BRB &0x2 <0x7dce>
00007dce: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007dd2: 20 49                                          POPW %fp
00007dd4: 08                                             RET
00007dd5: 70                                             NOP
00007dd6: 10 49                                          SAVE %fp
00007dd8: 9c 4f 04 00 00 00 4c                           ADDW2 &0x4,%sp
00007ddf: 82 59                                          CLRH (%fp)
00007de1: 70                                             NOP
00007de2: 7b 42                                          BRB &0x42 <0x7e24>
00007de4: 86 59 e4 40                                    MOVH (%fp),{word}%r0
00007de8: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00007dec: 9c 74 40                                       ADDW2 4(%ap),%r0
00007def: 3c da 00 50                                    CMPW *0(%ap),(%r0)
00007df3: 77 18                                          BNEB &0x18 <0x7e0b>
00007df5: 86 59 e4 40                                    MOVH (%fp),{word}%r0
00007df9: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00007dfd: 9c 74 40                                       ADDW2 4(%ap),%r0
00007e00: 84 c0 04 da 00                                 MOVW 4(%r0),*0(%ap)
00007e05: 70                                             NOP
00007e06: 84 01 40                                       MOVW &0x1,%r0
00007e09: 7b 25                                          BRB &0x25 <0x7e2e>
00007e0b: 86 59 e4 40                                    MOVH (%fp),{word}%r0
00007e0f: d0 03 40 40                                    LLSW3 &0x3,%r0,%r0
00007e13: 9c 74 40                                       ADDW2 4(%ap),%r0
00007e16: 3c da 00 50                                    CMPW *0(%ap),(%r0)
00007e1a: 5f 07                                          BLEUB &0x7 <0x7e21>
00007e1c: 84 01 40                                       MOVW &0x1,%r0
00007e1f: 7b 0f                                          BRB &0xf <0x7e2e>
00007e21: 92 59                                          INCH (%fp)
00007e23: 70                                             NOP
00007e24: 3e 6f 40 59                                    CMPH &0x40,(%fp)
00007e28: 4b bc                                          BLB &0xbc <0x7de4>
00007e2a: 80 40                                          CLRW %r0
00007e2c: 7b 02                                          BRB &0x2 <0x7e2e>
00007e2e: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007e32: 20 49                                          POPW %fp
00007e34: 08                                             RET
00007e35: 70                                             NOP
00007e36: 70                                             NOP
00007e37: 70                                             NOP
00007e38: 10 47                                          SAVE %r7
00007e3a: 84 5a 41                                       MOVW (%ap),%r1
00007e3d: 84 00 47                                       MOVW &0x0,%r7
00007e40: 87 51 e0 48                                    MOVB (%r1),{uword}%r8
00007e44: 3b 88 71 11 00 00 04                           BITB 0x1171(%r8),&0x4
00007e4b: 77 46                                          BNEB &0x46 <0x7e91>
00007e4d: 7b 13                                          BRB &0x13 <0x7e60>
00007e4f: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00007e53: 20 48                                          POPW %r8
00007e55: 20 47                                          POPW %r7
00007e57: 20 49                                          POPW %fp
00007e59: 08                                             RET
00007e5a: 90 41                                          INCW %r1
00007e5c: 87 51 e0 48                                    MOVB (%r1),{uword}%r8
00007e60: 3b 88 71 11 00 00 08                           BITB 0x1171(%r8),&0x8
00007e67: 77 f3                                          BNEB &0xf3 <0x7e5a>
00007e69: 3c 48 2b                                       CMPW %r8,&0x2b
00007e6c: 7f 09                                          BEB &0x9 <0x7e75>
00007e6e: 3c 48 2d                                       CMPW %r8,&0x2d
00007e71: 77 0a                                          BNEB &0xa <0x7e7b>
00007e73: 90 47                                          INCW %r7
00007e75: 90 41                                          INCW %r1
00007e77: 87 51 e0 48                                    MOVB (%r1),{uword}%r8
00007e7b: 3b 88 71 11 00 00 04                           BITB 0x1171(%r8),&0x4
00007e82: 77 0f                                          BNEB &0xf <0x7e91>
00007e84: 80 40                                          CLRW %r0
00007e86: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00007e8a: 20 48                                          POPW %r8
00007e8c: 20 47                                          POPW %r7
00007e8e: 20 49                                          POPW %fp
00007e90: 08                                             RET
00007e91: fc 48 30 42                                    SUBW3 %r8,&0x30,%r2
00007e95: 7b 0c                                          BRB &0xc <0x7ea1>
00007e97: a8 0a 42                                       MULW2 &0xa,%r2
00007e9a: fc 48 30 40                                    SUBW3 %r8,&0x30,%r0
00007e9e: 9c 40 42                                       ADDW2 %r0,%r2
00007ea1: 90 41                                          INCW %r1
00007ea3: 87 51 e0 48                                    MOVB (%r1),{uword}%r8
00007ea7: 3b 88 71 11 00 00 04                           BITB 0x1171(%r8),&0x4
00007eae: 77 e9                                          BNEB &0xe9 <0x7e97>
00007eb0: 28 47                                          TSTW %r7
00007eb2: 7f 10                                          BEB &0x10 <0x7ec2>
00007eb4: 84 42 40                                       MOVW %r2,%r0
00007eb7: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00007ebb: 20 48                                          POPW %r8
00007ebd: 20 47                                          POPW %r7
00007ebf: 20 49                                          POPW %fp
00007ec1: 08                                             RET
00007ec2: 8c 42 40                                       MNEGW %r2,%r0
00007ec5: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00007ec9: 20 48                                          POPW %r8
00007ecb: 20 47                                          POPW %r7
00007ecd: 20 49                                          POPW %fp
00007ecf: 08                                             RET
00007ed0: 10 47                                          SAVE %r7
00007ed2: 84 5a 41                                       MOVW (%ap),%r1
00007ed5: 84 00 47                                       MOVW &0x0,%r7
00007ed8: 87 51 e0 48                                    MOVB (%r1),{uword}%r8
00007edc: 3b 88 71 11 00 00 04                           BITB 0x1171(%r8),&0x4
00007ee3: 77 46                                          BNEB &0x46 <0x7f29>
00007ee5: 7b 13                                          BRB &0x13 <0x7ef8>
00007ee7: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00007eeb: 20 48                                          POPW %r8
00007eed: 20 47                                          POPW %r7
00007eef: 20 49                                          POPW %fp
00007ef1: 08                                             RET
00007ef2: 90 41                                          INCW %r1
00007ef4: 87 51 e0 48                                    MOVB (%r1),{uword}%r8
00007ef8: 3b 88 71 11 00 00 08                           BITB 0x1171(%r8),&0x8
00007eff: 77 f3                                          BNEB &0xf3 <0x7ef2>
00007f01: 3c 48 2b                                       CMPW %r8,&0x2b
00007f04: 7f 09                                          BEB &0x9 <0x7f0d>
00007f06: 3c 48 2d                                       CMPW %r8,&0x2d
00007f09: 77 0a                                          BNEB &0xa <0x7f13>
00007f0b: 90 47                                          INCW %r7
00007f0d: 90 41                                          INCW %r1
00007f0f: 87 51 e0 48                                    MOVB (%r1),{uword}%r8
00007f13: 3b 88 71 11 00 00 04                           BITB 0x1171(%r8),&0x4
00007f1a: 77 0f                                          BNEB &0xf <0x7f29>
00007f1c: 80 40                                          CLRW %r0
00007f1e: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00007f22: 20 48                                          POPW %r8
00007f24: 20 47                                          POPW %r7
00007f26: 20 49                                          POPW %fp
00007f28: 08                                             RET
00007f29: fc 48 30 42                                    SUBW3 %r8,&0x30,%r2
00007f2d: 7b 0c                                          BRB &0xc <0x7f39>
00007f2f: a8 0a 42                                       MULW2 &0xa,%r2
00007f32: fc 48 30 40                                    SUBW3 %r8,&0x30,%r0
00007f36: 9c 40 42                                       ADDW2 %r0,%r2
00007f39: 90 41                                          INCW %r1
00007f3b: 87 51 e0 48                                    MOVB (%r1),{uword}%r8
00007f3f: 3b 88 71 11 00 00 04                           BITB 0x1171(%r8),&0x4
00007f46: 77 e9                                          BNEB &0xe9 <0x7f2f>
00007f48: 28 47                                          TSTW %r7
00007f4a: 7f 10                                          BEB &0x10 <0x7f5a>
00007f4c: 84 42 40                                       MOVW %r2,%r0
00007f4f: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00007f53: 20 48                                          POPW %r8
00007f55: 20 47                                          POPW %r7
00007f57: 20 49                                          POPW %fp
00007f59: 08                                             RET
00007f5a: 8c 42 40                                       MNEGW %r2,%r0
00007f5d: 04 c9 f0 4c                                    MOVAW -16(%fp),%sp
00007f61: 20 48                                          POPW %r8
00007f63: 20 47                                          POPW %r7
00007f65: 20 49                                          POPW %fp
00007f67: 08                                             RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 'strcmp' Routine
;;

00007f68: 10 49                                          SAVE %fp
00007f6a: 84 5a 40                                       MOVW (%ap),%r0
00007f6d: 84 74 41                                       MOVW 4(%ap),%r1
00007f70: 3c 41 40                                       CMPW %r1,%r0
00007f73: 77 08                                          BNEB &0x8 <0x7f7b>
00007f75: 7b 10                                          BRB &0x10 <0x7f85>
00007f77: 90 40                                          INCW %r0
00007f79: 90 41                                          INCW %r1
00007f7b: 3f 51 50                                       CMPB (%r1),(%r0)
00007f7e: 77 07                                          BNEB &0x7 <0x7f85>
00007f80: 3f 50 00                                       CMPB (%r0),&0x0
00007f83: 77 f4                                          BNEB &0xf4 <0x7f77>
00007f85: ff 51 50 40                                    SUBB3 (%r1),(%r0),%r0
00007f89: 87 e7 40 e4 40                                 MOVB {sbyte}%r0,{word}%r0
00007f8e: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007f92: 20 49                                          POPW %fp
00007f94: 08                                             RET
00007f95: 70                                             NOP
00007f96: 70                                             NOP
00007f97: 70                                             NOP
00007f98: 10 49                                          SAVE %fp
00007f9a: 84 5a 40                                       MOVW (%ap),%r0
00007f9d: 7b 04                                          BRB &0x4 <0x7fa1>
00007f9f: 90 40                                          INCW %r0
00007fa1: 2b 50                                          TSTB (%r0)
00007fa3: 77 fc                                          BNEB &0xfc <0x7f9f>
00007fa5: bc 5a 40                                       SUBW2 (%ap),%r0
00007fa8: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007fac: 20 49                                          POPW %fp
00007fae: 08                                             RET
00007faf: 70                                             NOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unknown routine.
;;

00007fb0: 10 49                                          SAVE %fp
00007fb2: 84 5a 41                                       MOVW (%ap),%r1
00007fb5: 84 74 40                                       MOVW 4(%ap),%r0
00007fb8: 30 35                                          STRCPY
00007fba: 84 5a 40                                       MOVW (%ap),%r0
00007fbd: 04 c9 e8 4c                                    MOVAW -24(%fp),%sp
00007fc1: 20 49                                          POPW %fp
00007fc3: 08                                             RET

;; Filling bytes

00007fc4: 00                                             ???
00007fc5: 00                                             ???
00007fc6: 00                                             ???
00007fc7: 00                                             ???
00007fc8: 00                                             ???
00007fc9: 00                                             ???
00007fca: 00                                             ???
00007fcb: 00                                             ???
00007fcc: 00                                             ???
00007fcd: 00                                             ???
00007fce: 00                                             ???
00007fcf: 00                                             ???
00007fd0: 00                                             ???
00007fd1: 00                                             ???
00007fd2: 00                                             ???
00007fd3: 00                                             ???
00007fd4: 00                                             ???
00007fd5: 00                                             ???
00007fd6: 00                                             ???
00007fd7: 00                                             ???
00007fd8: 00                                             ???
00007fd9: 00                                             ???
00007fda: 00                                             ???
00007fdb: 00                                             ???
00007fdc: 00                                             ???
00007fdd: 00                                             ???
00007fde: 00                                             ???
00007fdf: 00                                             ???
00007fe0: 00                                             ???
00007fe1: 00                                             ???
00007fe2: 00                                             ???
00007fe3: 00                                             ???
00007fe4: 00                                             ???
00007fe5: 00                                             ???
00007fe6: 00                                             ???
00007fe7: 00                                             ???
00007fe8: 00                                             ???
00007fe9: 00                                             ???
00007fea: 00                                             ???
00007feb: 00                                             ???
00007fec: 00                                             ???
00007fed: 00                                             ???
00007fee: 25                                             ???
00007fef: 72                                             NOP3

;; Serial Number Structure

00007ff0: 22 22 22 22
00007ff4: 03 02 01 30
00007ff8: 03 02 01 0e
00007ffc: 03 02 01 0b
