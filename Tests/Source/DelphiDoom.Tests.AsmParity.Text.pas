{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the assembler replacements - toupper, tolower, StrLCopy }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AsmParity.Text;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   toupper and tolower of d_delphi are Pascal in every build now (the assembler looked at the low
  ///   byte of the character only). For the 8 bit characters and for the Char below 256 the result
  ///   is the one of the old code; above 256 the old code was wrong, and these tests say how.
  /// </summary>
  [TestFixture]
  [Category('asm')]
  TTestAsmText = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeMaiuscoleDegliAnsiCharCometProcessoreVecchio;
    [Test]
    procedure DovrebbeDareLeMinuscoleDegliAnsiCharCometProcessoreVecchio;
    [Test]
    procedure DovrebbeDareLeMaiuscoleDeiCharSottoDuecentocinquantasei;
    [Test]
    procedure DovrebbeDareLeMinuscoleDeiCharSottoDuecentocinquantasei;
    [Test]
    procedure DovrebbeLasciareInvariatiICharSopraDuecentocinquantacinque;
    [Test]
    procedure DovrebbeCambiareSoloLeLettereAsciiInTuttoLIntervallo;
    [Test]
    procedure DovrebbeCopiareAlMassimoIlNumeroDiCaratteriChiesto;
    [Test]
    procedure DovrebbeCopiareTuttoSeLaSorgenteEPiuCorta;
  end;

implementation

uses
  d_delphi
{$IFDEF CPUX86}
  , DelphiDoom.Tests.AsmParity.Oracles
{$ENDIF}
  ;

{ TTestAsmText }

// What the old assembler gave for a code below 256: only the 26 letters of ASCII change. The
// 32 bit build checks the rule against the assembler itself for every code, so that the 64 bit
// build, where the assembler cannot run, compares d_delphi with the same 256 values.
function OldUpperCode(ACode: Integer): Integer;
begin
  Result := ACode;
  if (ACode >= Ord('a')) and (ACode <= Ord('z')) then
    Result := ACode - 32;
end;

function OldLowerCode(ACode: Integer): Integer;
begin
  Result := ACode;
  if (ACode >= Ord('A')) and (ACode <= Ord('Z')) then
    Result := ACode + 32;
end;

procedure TTestAsmText.DovrebbeDareLeMaiuscoleDegliAnsiCharCometProcessoreVecchio;
var
  LCode: Integer;
begin
  for LCode := 0 to 255 do
  begin
{$IFDEF CPUX86}
    Assert.AreEqual(Integer(OldToUpperAnsi(AnsiChar(LCode))), OldUpperCode(LCode),
      'assembler, code ' + IntToStr(LCode));
{$ENDIF}
    Assert.AreEqual(OldUpperCode(LCode), Integer(d_delphi.toupper(AnsiChar(LCode))),
      'code ' + IntToStr(LCode));
  end;
end;

procedure TTestAsmText.DovrebbeDareLeMinuscoleDegliAnsiCharCometProcessoreVecchio;
var
  LCode: Integer;
begin
  for LCode := 0 to 255 do
  begin
{$IFDEF CPUX86}
    Assert.AreEqual(Integer(OldToLowerAnsi(AnsiChar(LCode))), OldLowerCode(LCode),
      'assembler, code ' + IntToStr(LCode));
{$ENDIF}
    Assert.AreEqual(OldLowerCode(LCode), Integer(d_delphi.tolower(AnsiChar(LCode))),
      'code ' + IntToStr(LCode));
  end;
end;

procedure TTestAsmText.DovrebbeDareLeMaiuscoleDeiCharSottoDuecentocinquantasei;
var
  LCode: Integer;
begin
  for LCode := 0 to 255 do
  begin
{$IFDEF CPUX86}
    Assert.AreEqual(Integer(Ord(OldToUpperChar(Char(LCode)))), OldUpperCode(LCode),
      'assembler, code ' + IntToStr(LCode));
{$ENDIF}
    Assert.AreEqual(OldUpperCode(LCode), Integer(Ord(d_delphi.toupper(Char(LCode)))),
      'code ' + IntToStr(LCode));
  end;
end;

procedure TTestAsmText.DovrebbeDareLeMinuscoleDeiCharSottoDuecentocinquantasei;
var
  LCode: Integer;
begin
  for LCode := 0 to 255 do
  begin
{$IFDEF CPUX86}
    Assert.AreEqual(Integer(Ord(OldToLowerChar(Char(LCode)))), OldLowerCode(LCode),
      'assembler, code ' + IntToStr(LCode));
{$ENDIF}
    Assert.AreEqual(OldLowerCode(LCode), Integer(Ord(d_delphi.tolower(Char(LCode)))),
      'code ' + IntToStr(LCode));
  end;
end;

procedure TTestAsmText.DovrebbeLasciareInvariatiICharSopraDuecentocinquantacinque;
var
  LCode: Integer;
begin
  // regression: the old assembler compared the low byte only, so $0161 (s with caron) became $0141
  // and $0141 became $0161
  for LCode := 256 to 65535 do
  begin
    Assert.AreEqual(LCode, Integer(Ord(d_delphi.toupper(Char(LCode)))), 'toupper ' + IntToStr(LCode));
    Assert.AreEqual(LCode, Integer(Ord(d_delphi.tolower(Char(LCode)))), 'tolower ' + IntToStr(LCode));
  end;
end;

procedure TTestAsmText.DovrebbeCambiareSoloLeLettereAsciiInTuttoLIntervallo;
var
  LCode: Integer;
  LExpectedUpper: Integer;
  LExpectedLower: Integer;
begin
  for LCode := 0 to 255 do
  begin
    LExpectedUpper := LCode;
    if (LCode >= Ord('a')) and (LCode <= Ord('z')) then
      LExpectedUpper := LCode - 32;
    LExpectedLower := LCode;
    if (LCode >= Ord('A')) and (LCode <= Ord('Z')) then
      LExpectedLower := LCode + 32;
    Assert.AreEqual(LExpectedUpper, Integer(Ord(d_delphi.toupper(Char(LCode)))), 'toupper ' + IntToStr(LCode));
    Assert.AreEqual(LExpectedLower, Integer(Ord(d_delphi.tolower(Char(LCode)))), 'tolower ' + IntToStr(LCode));
  end;
end;

procedure TTestAsmText.DovrebbeCopiareAlMassimoIlNumeroDiCaratteriChiesto;
var
  LBuffer: array[0..15] of Char;
  LResult: PChar;
  I: Integer;
begin
  for I := 0 to 15 do
    LBuffer[I] := '#';
  LResult := d_delphi.StrLCopy(@LBuffer[0], PChar('hello world'), 5);
  Assert.IsTrue(LResult = @LBuffer[0], 'it returns the destination');
  Assert.AreEqual('hello', string(PChar(@LBuffer[0])));
  Assert.AreEqual(Integer(Ord('#')), Integer(Ord(LBuffer[6])), 'nothing after the terminator');
end;

procedure TTestAsmText.DovrebbeCopiareTuttoSeLaSorgenteEPiuCorta;
var
  LBuffer: array[0..15] of Char;
begin
  d_delphi.StrLCopy(@LBuffer[0], PChar('abc'), 10);
  Assert.AreEqual('abc', string(PChar(@LBuffer[0])));
end;

end.
