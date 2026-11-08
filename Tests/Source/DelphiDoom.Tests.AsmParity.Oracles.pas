{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the assembler replacements - the old assembler          }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AsmParity.Oracles;

{$Q-}
{$R-}

interface

{$IFDEF CPUX86}

// The functions below are the assembler blocks of the engine, copied as they were (m_fixed,
// r_softlights, p_local, d_delphi) under another name: the tests compare them with the Pascal
// versions. Only two lines are added, push ebx and pop ebx in OldFixedDiv2 and OldFixedDivFast,
// because the old code changed ebx without saving it (the callers of the engine did not mind;
// the DUnitX runner could). Nothing else changes: not the instructions, not the registers.
// They exist only for the 32 bit build of the tests.

/// <summary>The old FixedMul</summary>
function OldFixedMul(const a, b: Integer): Integer;
function OldFixedMulShl3(const a, b: Integer): Integer;
function OldFixedMulShl4(const a, b: Integer): Integer;
function OldFixedMulShl5(const a, b: Integer): Integer;
function OldFixedMulShl8(const a, b: Integer): Integer;
function OldFixedMulShl10(const a, b: Integer): Integer;
function OldFixedMulShl14(const a, b: Integer): Integer;
function OldFixedMulDiv8(const a, b: Integer): Integer;
function OldFixedMulDiv16(const a, b: Integer): Integer;
function OldFixedMulDiv256(const a, b: Integer): Integer;
function OldFixedMul88(const a, b: Integer): Integer;
function OldFixedMul8(const a, b: Integer): Integer;
function OldFixedIntMul(const a, b: Integer): Integer;
function OldIntFixedMul(const a, b: Integer): Integer;
function OldFixedInt_FixedMul(const a, b: Integer): Integer;
function OldFixedInt(const x: Integer): Integer;
/// <summary>The old FixedDivLW: the idiv of the processor raises if the quotient does not fit</summary>
function OldFixedDivLW(const a, b: LongWord): LongWord;
function OldFixedDiv_fast(const a, b: Integer): Integer;
function OldFixedDiv2(const a, b: Integer): Integer;
/// <summary>The old ASM_CalcFactor of r_softlights</summary>
function OldCalcFactor(const a, b: LongWord): LongWord;

/// <summary>The old MapBlockInt of p_local (sar by MAPBLOCKSHIFT = 23)</summary>
function OldMapBlockInt(const x: Integer): Integer;
/// <summary>The old MapToFrac of p_local (sar by MAPBTOFRAC = 7)</summary>
function OldMapToFrac(const x: Integer): Integer;

function OldSHL(const x: Integer; const bits: Integer): Integer;
function OldSHR(const x: Integer; const bits: Integer): Integer;
function OldSHR1(const x: Integer): Integer;
function OldSHR2(const x: Integer): Integer;
function OldSHR3(const x: Integer): Integer;
function OldSHR4(const x: Integer): Integer;
function OldSHR7(const x: Integer): Integer;
function OldSHR8(const x: Integer): Integer;
function OldSHR14(const x: Integer): Integer;

/// <summary>The old FillDWord of d_delphi (rep stosd; a negative count would fill the memory)</summary>
procedure OldFillDWord(const dest: Pointer; Count: Integer; Value: LongWord);

/// <summary>The old toupper(Char) of d_delphi: it looks at the low byte only</summary>
function OldToUpperChar(ch: Char): Char;
function OldToUpperAnsi(ch: AnsiChar): AnsiChar;
function OldToLowerChar(ch: Char): Char;
function OldToLowerAnsi(ch: AnsiChar): AnsiChar;

{$ENDIF}

implementation

{$IFDEF CPUX86}

const
  FRACBITS = 16;
  MAXINT = $7FFFFFFF;
  FRACUNIT = 1 shl FRACBITS;

function OldFixedMul(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
end;

function OldFixedMulShl3(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 3
end;

function OldFixedMulShl4(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 4
end;

function OldFixedMulShl5(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 5
end;

function OldFixedMulShl8(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 8
end;

function OldFixedMulShl10(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 10
end;

function OldFixedMulShl14(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
  shl eax, 14
end;

function OldFixedMulDiv8(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 19
end;

function OldFixedMulDiv16(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 20
end;

function OldFixedMulDiv256(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 24
end;

function OldFixedMul88(const a, b: Integer): Integer; assembler;
asm
  sar a, 8
  sar b, 8
  imul b
  shrd eax, edx, 16
end;

function OldFixedMul8(const a, b: Integer): Integer; assembler;
asm
  sar a, 8
  imul b
  shrd eax, edx, 16
end;

function OldFixedIntMul(const a, b: Integer): Integer; assembler;
asm
  sar b, FRACBITS
  imul b
  shrd eax, edx, 16
end;

function OldIntFixedMul(const a, b: Integer): Integer; assembler;
asm
  sar eax, FRACBITS
  imul b
  shrd eax, edx, 16
end;

function OldFixedInt_FixedMul(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
  sar eax, FRACBITS
end;

function OldFixedInt(const x: Integer): Integer; assembler;
asm
  sar eax, FRACBITS
end;

function OldFixedDivLW(const a, b: LongWord): LongWord; assembler;
asm
  push ebx
  mov ebx, eax
  shr ebx, $0e
  cmp edx, ebx
  jbe @@retmax
  mov ebx, edx
  cmp ebx, 0
  jne @@loop1
@@retmax:
  mov eax, MAXINT
  jmp @@exit
@@loop1:
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
@@exit:
  pop ebx
end;

function OldFixedDiv_fast(const a, b: Integer): Integer; assembler;
asm
  push ebx
  mov ebx, b
  cmp ebx, 0
  jne @@loop1
  mov eax, MAXINT
  jmp @@exit
@@loop1:
  mov ebx, b
  mov eax, a
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
@@exit:
  pop ebx
end;

function OldFixedDiv2(const a, b: Integer): Integer; register; assembler;
asm
  push ebx
  mov ebx, b
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
  pop ebx
end;

function OldCalcFactor(const a, b: LongWord): LongWord; assembler;
asm
  push ebx
  mov ebx, eax
  shr ebx, $0e
  cmp edx, ebx
  jbe @@retmax
  mov ebx, edx
  cmp ebx, 0
  jne @@loop1
@@retmax:
  mov eax, MAXINT
  jmp @@exit
@@loop1:
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
@@exit:
  sub eax, FRACUNIT
  neg eax
  pop ebx
end;

function OldMapBlockInt(const x: Integer): Integer; assembler;
asm
  sar eax, 23
end;

function OldMapToFrac(const x: Integer): Integer; assembler;
asm
  sar eax, 7
end;

function OldSHL(const x: Integer; const bits: Integer): Integer; assembler;
asm
  mov ecx, edx
  sal eax, cl
end;

function OldSHR(const x: Integer; const bits: Integer): Integer; assembler;
asm
  mov ecx, edx
  sar eax, cl
end;

function OldSHR1(const x: Integer): Integer; assembler;
asm
  sar eax, 1
end;

function OldSHR2(const x: Integer): Integer; assembler;
asm
  sar eax, 2
end;

function OldSHR3(const x: Integer): Integer; assembler;
asm
  sar eax, 3
end;

function OldSHR4(const x: Integer): Integer; assembler;
asm
  sar eax, 4
end;

function OldSHR7(const x: Integer): Integer; assembler;
asm
  sar eax, 7
end;

function OldSHR8(const x: Integer): Integer; assembler;
asm
  sar eax, 8
end;

function OldSHR14(const x: Integer): Integer; assembler;
asm
  sar eax, 14
end;

procedure OldFillDWord(const dest: Pointer; Count: Integer; Value: LongWord); assembler; register;
asm
  push edi
  mov  edi, eax  // assign Destination
  mov  eax, ecx  // assign Value
  mov  ecx, edx
  rep  stosd
  pop edi
end;

function OldToUpperChar(ch: Char): Char;
asm
  cmp al, 'a'
  jb  @@exit
  cmp al, 'z'
  ja  @@exit
  sub al, 'a' - 'A'
@@exit:
end;

function OldToUpperAnsi(ch: AnsiChar): AnsiChar;
asm
  cmp al, 'a'
  jb  @@exit
  cmp al, 'z'
  ja  @@exit
  sub al, 'a' - 'A'
@@exit:
end;

function OldToLowerChar(ch: Char): Char;
asm
  cmp al, 'A'
  jb  @@exit
  cmp al, 'Z'
  ja  @@exit
  sub al, 'A' - 'a'
@@exit:
end;

function OldToLowerAnsi(ch: AnsiChar): AnsiChar;
asm
  cmp al, 'A'
  jb  @@exit
  cmp al, 'Z'
  ja  @@exit
  sub al, 'A' - 'a'
@@exit:
end;

{$ENDIF}

end.
