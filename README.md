AT&T 3B2 ROM images
====================

3B2 Model 310
-------------

- 310_AAYYC.bin
- 310_AAYYD.bin
- 310_AAYYE.bin
- 310_AAYYF.bin
- 310_full.bin

These are binary images of Intel D2764A EPROMs from an AT&T 3B2 Model
310.  The 3B2 reads full 32-bit words from the 4 ROMs. The low byte
comes from AAYYC, the next byte from AAYYD, the next byte from AAYYE,
and the high byte from AAYYD.

The file `310_full.bin` contains the output of interleaving the D2764A
images, and contains 8,192 32-bit words.

- 310_full.hex

This is a canonical HEX+ASCII dump of the `310_full.bin` file.

3B2 Model 400
-------------

- 400_AAYYC.bin
- 400_AAYYD.bin
- 400_AAYYE.bin
- 400_AAYYF.bin
- 400_full.bin

These are binary images of Intel D2764A EPROMs from an AT&T 3B2 Model
400.  They appear to be identical to the 310 ROMs except for the final
few bytes. They are included for completeness.

- 400_full.hex

This is a canonical HEX+ASCII dump of the `400_full.bin` file.

3B2 Debug Monitor (DEMON)
-------------------------

- 400_DEMON_0.bin
- 400_DEMON_1.bin
- 400_DEMON_2.bin
- 400_DEMON_3.bin
- 400_DEMON_full.bin

These are binary images of 16KB Intel D27128A EPROMs containing the
AT&T 3B2 Computer Debug Monitor.

- 400_DEMON.jpg

Photograph of DEMON EPROMs installed in a 3B2/400.

3B2 Model 500
-------------

- 500_abtrt.bin
- 500_abtru.bin
- 500_abtrw.bin
- 500_abtry.bin
- 500_full.bin

These are binary images of 32KB EPROMs (presumably D27C128 or
equivalent) from an AT&T 3B2 Model 500. Together, they comprise a
128KB / 32KW ROM.

- 500_full.hex

This is the canonical HEX+ASCII dump of the `500_full.bin` file.

WE32100 Disassembler
--------------------

A very bare-bones WE32100 disassembler can be found in the file
`we32dis.rb`.  It is implemented in Ruby and requires at least Ruby
2.0 to function correctly.

Disassembled Model 400 ROM
--------------------------

The file `400_full.s` contains a disassembled and commented version of
the Model 400 ROM. It is a work in progress, and has not been fully
commented yet.

