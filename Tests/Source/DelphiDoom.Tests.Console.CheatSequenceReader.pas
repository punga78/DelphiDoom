{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the cheat sequencereader                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CheatSequenceReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('console')]
  TTestCheatSequenceReader = class(TObject)
  public
    [Test]
    procedure TestStopsAtTheEndMarkWithoutTakingIt;
    [Test]
    procedure TestTakesTheFirstByteWhateverItIs;
    [Test]
    procedure TestMissingEndMarkIsAnError;
    [Test]
    procedure TestEmptyArrayIsAnError;
    [Test]
    procedure DovrebbeDareComeIlVecchioCodiceUnArrayDiCaratteri;
    [Test]
    procedure DovrebbeDareComeIlVecchioCodiceUnaStringa;
    [Test]
    procedure DovrebbeRifiutareUnaStringaSenzaSegnoDiFine;
  end;

implementation

uses
  DelphiDoom.Console.Types, DelphiDoom.Console.CheatSequenceReader, DelphiDoom.Tests.Console.CheatData;

{ TTestCheatSequenceReader }

procedure TTestCheatSequenceReader.TestStopsAtTheEndMarkWithoutTakingIt;
var
  LSequence: AnsiString;
begin
  LSequence := TCheatSequenceReader.FromBytes(IDDQD);
  Assert.AreEqual(5, Length(LSequence), 'dovrebbe fermarsi prima del segno di fine');
  Assert.AreEqual(Integer($B2), Integer(Ord(LSequence[1])));
  Assert.AreEqual(Integer($26), Integer(Ord(LSequence[5])));
end;

procedure TTestCheatSequenceReader.TestTakesTheFirstByteWhateverItIs;
var
  LSequence: AnsiString;
begin
  LSequence := TCheatSequenceReader.FromBytes([$FF, $FF]);
  Assert.AreEqual(1, Length(LSequence), 'dovrebbe prendere sempre il primo byte');
end;

procedure TTestCheatSequenceReader.TestMissingEndMarkIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      TCheatSequenceReader.FromBytes([$B2, $26]);
    end,
    EConsoleException, 'dovrebbe rifiutare una sequenza senza segno di fine');
end;

procedure TTestCheatSequenceReader.TestEmptyArrayIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      TCheatSequenceReader.FromBytes([]);
    end,
    EConsoleException, 'dovrebbe rifiutare un array vuoto');
end;

// get_cheatseq_string of m_cheat at 63a151cc (the two overloads that read an array or a string)
function OldCheatSeqFromChars(const A: array of AnsiChar): AnsiString;
var
  i: integer;
begin
  result := '';
  i := 0;
  repeat
    result := result + A[i];
    inc(i);
  until A[i] = AnsiChar($FF);
end;

function OldCheatSeqFromString(const A: AnsiString): AnsiString;
var
  i: integer;
begin
  result := '';
  i := 1;
  repeat
    result := result + A[i];
    inc(i);
  until A[i] = AnsiChar($FF);
end;

// random sequences with the end mark somewhere after the first byte (what the games give)
procedure RandomSequence(var ASeed: Cardinal; out AChars: TArray<AnsiChar>);
var
  LLength: Integer;
  LMark: Integer;
  LIndex: Integer;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  LLength := 2 + Integer((ASeed shr 8) mod 30);
  ASeed := ASeed * 1664525 + 1013904223;
  LMark := 1 + Integer((ASeed shr 8) mod Cardinal(LLength - 1));
  SetLength(AChars, LLength);
  for LIndex := 0 to LLength - 1 do
  begin
    ASeed := ASeed * 1664525 + 1013904223;
    AChars[LIndex] := AnsiChar((ASeed shr 16) and $FF);
  end;
  AChars[LMark] := AnsiChar($FF);
end;

procedure TTestCheatSequenceReader.DovrebbeDareComeIlVecchioCodiceUnArrayDiCaratteri;
var
  LSeed: Cardinal;
  LChars: TArray<AnsiChar>;
  LCase: Integer;
begin
  LSeed := 185;
  for LCase := 1 to 20000 do
  begin
    RandomSequence(LSeed, LChars);
    Assert.IsTrue(OldCheatSeqFromChars(LChars) = TCheatSequenceReader.FromChars(LChars),
      'caso ' + IntToStr(LCase));
  end;
end;

procedure TTestCheatSequenceReader.DovrebbeDareComeIlVecchioCodiceUnaStringa;
var
  LSeed: Cardinal;
  LChars: TArray<AnsiChar>;
  LText: AnsiString;
  LCase: Integer;
  LIndex: Integer;
  LOld, LNew: AnsiString;
begin
  LSeed := 1850;
  for LCase := 1 to 20000 do
  begin
    RandomSequence(LSeed, LChars);
    SetLength(LText, Length(LChars));
    for LIndex := 0 to High(LChars) do
      LText[LIndex + 1] := LChars[LIndex];
    LOld := OldCheatSeqFromString(LText);
    LNew := TCheatSequenceReader.FromString(LText);
    Assert.IsTrue(LOld = LNew, 'caso ' + IntToStr(LCase));
  end;
end;

procedure TTestCheatSequenceReader.DovrebbeRifiutareUnaStringaSenzaSegnoDiFine;
begin
  // the old code read past the end of the string, up to a byte $FF found in memory
  Assert.WillRaise(
    procedure
    begin
      TCheatSequenceReader.FromString('idkfa');
    end,
    EConsoleException);
  Assert.WillRaise(
    procedure
    begin
      TCheatSequenceReader.FromString('');
    end,
    EConsoleException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCheatSequenceReader);

end.
