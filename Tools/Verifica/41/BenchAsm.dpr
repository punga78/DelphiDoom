{******************************************************************************}
{                                                                              }
{  Issue #41: micro benchmark of the old assembler against the Pascal versions }
{  (32 bit only: the assembler of Tests\Source\DelphiDoom.Tests.AsmParity.Oracles    }
{  does not exist at 64 bit).                                                  }
{                                                                              }
{  Build:  C:\Strumenti\delphi-build.cmd Tools\Verifica\41\BenchAsm.dpr Release Win32 }
{  Run:    the executable is written next to the .dpr (BenchAsm.exe)           }
{                                                                              }
{  It prints nanoseconds per operation. A ratio asm/pascal under 1 means that  }
{  the assembler is faster; the engine keeps the assembler for 32 bit (CPUX86) }
{  where the Pascal is slower than 5%.                                         }
{                                                                              }
{******************************************************************************}
program BenchAsm;

{$APPTYPE CONSOLE}
{$Q-}
{$R-}

uses
  System.SysUtils,
  System.Diagnostics,
  DelphiDoom.MathCore.Types in '..\..\..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.FixedMath in '..\..\..\Libs\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.MemoryFill in '..\..\..\Libs\MathCore\DelphiDoom.MathCore.MemoryFill.pas',
  DelphiDoom.Tests.AsmParity.Oracles in '..\..\..\Tests\Source\DelphiDoom.Tests.AsmParity.Oracles.pas';

const
  ITERATIONS = 50000000;
  DATA_MASK = 4095;
  FILL_COUNT = 1024;
  FILL_ROUNDS = 200000;

var
  Data: array[0..DATA_MASK] of Integer;
  Sink: Integer;
  FillBuffer: array[0..FILL_COUNT - 1] of Cardinal;

procedure Report(const AName: string; const AWatch: TStopwatch; AOperations: Int64);
begin
  Writeln(Format('%-28s %8.3f ns/op  (%d ms)',
    [AName, AWatch.Elapsed.TotalMilliseconds * 1000000.0 / AOperations, AWatch.ElapsedMilliseconds]));
end;

procedure RunMul;
var
  LWatch: TStopwatch;
  LIndex: Integer;
  LSum: Integer;
begin
  LSum := 0;
  LWatch := TStopwatch.StartNew;
  for LIndex := 0 to ITERATIONS - 1 do
    LSum := LSum + OldFixedMul(Data[LIndex and DATA_MASK], Data[(LIndex + 7) and DATA_MASK]);
  Report('FixedMul asm', LWatch, ITERATIONS);
  Sink := Sink + LSum;

  LSum := 0;
  LWatch := TStopwatch.StartNew;
  for LIndex := 0 to ITERATIONS - 1 do
    LSum := LSum + TFixedMath.Mul(Data[LIndex and DATA_MASK], Data[(LIndex + 7) and DATA_MASK]);
  Report('FixedMul pascal', LWatch, ITERATIONS);
  Sink := Sink + LSum;
end;

procedure RunMul88;
var
  LWatch: TStopwatch;
  LIndex: Integer;
  LSum: Integer;
begin
  LSum := 0;
  LWatch := TStopwatch.StartNew;
  for LIndex := 0 to ITERATIONS - 1 do
    LSum := LSum + OldFixedMul88(Data[LIndex and DATA_MASK], Data[(LIndex + 7) and DATA_MASK]);
  Report('FixedMul88 asm', LWatch, ITERATIONS);
  Sink := Sink + LSum;

  LSum := 0;
  LWatch := TStopwatch.StartNew;
  for LIndex := 0 to ITERATIONS - 1 do
    LSum := LSum + TFixedMath.Mul88(Data[LIndex and DATA_MASK], Data[(LIndex + 7) and DATA_MASK]);
  Report('FixedMul88 pascal', LWatch, ITERATIONS);
  Sink := Sink + LSum;
end;

procedure RunShift;
var
  LWatch: TStopwatch;
  LIndex: Integer;
  LSum: Integer;
begin
  LSum := 0;
  LWatch := TStopwatch.StartNew;
  for LIndex := 0 to ITERATIONS - 1 do
    LSum := LSum + OldSHR14(Data[LIndex and DATA_MASK]);
  Report('_SHR14 asm', LWatch, ITERATIONS);
  Sink := Sink + LSum;

  LSum := 0;
  LWatch := TStopwatch.StartNew;
  for LIndex := 0 to ITERATIONS - 1 do
    LSum := LSum + TFixedMath.ShiftRight(Data[LIndex and DATA_MASK], 14);
  Report('_SHR14 pascal (inline)', LWatch, ITERATIONS);
  Sink := Sink + LSum;
end;

procedure RunDivide;
var
  LWatch: TStopwatch;
  LIndex: Integer;
  LSum: Integer;
  LA: Integer;
  LB: Integer;
begin
  // numerators under $8000 and denominators from $10000: the quotient always fits
  LSum := 0;
  LWatch := TStopwatch.StartNew;
  for LIndex := 0 to ITERATIONS - 1 do
  begin
    LA := Data[LIndex and DATA_MASK] and $7FFF;
    LB := (Data[(LIndex + 7) and DATA_MASK] and $FFFF) or $10000;
    LSum := LSum + OldFixedDiv2(LA, LB);
  end;
  Report('FixedDiv2 asm', LWatch, ITERATIONS);
  Sink := Sink + LSum;

  LSum := 0;
  LWatch := TStopwatch.StartNew;
  for LIndex := 0 to ITERATIONS - 1 do
  begin
    LA := Data[LIndex and DATA_MASK] and $7FFF;
    LB := (Data[(LIndex + 7) and DATA_MASK] and $FFFF) or $10000;
    LSum := LSum + TFixedMath.DivideRaw(LA, LB);
  end;
  Report('FixedDiv2 pascal', LWatch, ITERATIONS);
  Sink := Sink + LSum;
end;

procedure RunFill;
var
  LWatch: TStopwatch;
  LRound: Integer;
begin
  LWatch := TStopwatch.StartNew;
  for LRound := 0 to FILL_ROUNDS - 1 do
    OldFillDWord(@FillBuffer[0], FILL_COUNT, Cardinal(LRound));
  Report('FillDWord 1024 asm', LWatch, FILL_ROUNDS);
  Sink := Sink + Integer(FillBuffer[0]);

  LWatch := TStopwatch.StartNew;
  for LRound := 0 to FILL_ROUNDS - 1 do
    TMemoryFill.FillDWords(@FillBuffer[0], FILL_COUNT, Cardinal(LRound));
  Report('FillDWord 1024 pascal', LWatch, FILL_ROUNDS);
  Sink := Sink + Integer(FillBuffer[0]);
end;

var
  GIndex: Integer;
  GState: Cardinal;

begin
  GState := $2545F491;
  for GIndex := 0 to DATA_MASK do
  begin
    GState := GState xor (GState shl 13);
    GState := GState xor (GState shr 17);
    GState := GState xor (GState shl 5);
    Data[GIndex] := Integer(GState);
  end;
  Sink := 0;
  RunMul;
  RunMul88;
  RunShift;
  RunDivide;
  RunFill;
  Writeln('(sink ', Sink, ')');
end.
