{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - RLEW expansion                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Rlew;

{$Q-}{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenRlew = class(TObject)
  private
    FRlew: IKeenRlew;
    function Words(const ABytes: TBytes): TArray<Word>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCopiareLeParoleCheNonSonoIlTag;
    [Test]
    procedure DovrebbeRipetereIlValoreDopoIlTag;
    [Test]
    procedure DovrebbeNonScrivereNullaPerUnConteggioZero;
    [Test]
    procedure DovrebbeRiprodurreISequenzeCasuali;
    [Test]
    procedure DovrebbeLeggereDaUnOffsetEIgnorareUnByteDispari;
    [Test]
    procedure DovrebbeRifiutareDatiTroncati;
    [Test]
    procedure DovrebbeRifiutareUnaRipetizioneOltreLaFine;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaNegativa;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Tests.Keen.Builders;

{ TTestKeenRlew }

procedure TTestKeenRlew.Setup;
begin
  FRlew := TKeenFactory.CreateRlew;
end;

procedure TTestKeenRlew.TearDown;
begin
  FRlew := nil;
end;

function TTestKeenRlew.Words(const ABytes: TBytes): TArray<Word>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ABytes) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Word(ABytes[LIndex * 2]) or (Word(ABytes[LIndex * 2 + 1]) shl 8);
end;

procedure TTestKeenRlew.DovrebbeCopiareLeParoleCheNonSonoIlTag;
var
  LResult: TArray<Word>;
begin
  LResult := Words(FRlew.Expand(TBytes.Create($01, $00, $02, $01, $FF, $FF), 0, 6, $ABCD));
  Assert.AreEqual(3, Length(LResult));
  Assert.AreEqual($0001, Integer(LResult[0]));
  Assert.AreEqual($0102, Integer(LResult[1]));
  Assert.AreEqual($FFFF, Integer(LResult[2]));
end;

procedure TTestKeenRlew.DovrebbeRipetereIlValoreDopoIlTag;
var
  LResult: TArray<Word>;
begin
  // tag, count 3, value $1234, then the word 7
  LResult := Words(FRlew.Expand(TBytes.Create($CD, $AB, $03, $00, $34, $12, $07, $00), 0, 8, $ABCD));
  Assert.AreEqual(4, Length(LResult));
  Assert.AreEqual($1234, Integer(LResult[0]));
  Assert.AreEqual($1234, Integer(LResult[2]));
  Assert.AreEqual(7, Integer(LResult[3]));
end;

procedure TTestKeenRlew.DovrebbeNonScrivereNullaPerUnConteggioZero;
var
  LResult: TArray<Word>;
begin
  LResult := Words(FRlew.Expand(TBytes.Create($CD, $AB, $00, $00, $34, $12, $07, $00), 0, 2, $ABCD));
  Assert.AreEqual(1, Length(LResult));
  Assert.AreEqual(7, Integer(LResult[0]));
end;

procedure TTestKeenRlew.DovrebbeRiprodurreISequenzeCasuali;
var
  LCase: Integer;
  LIndex: Integer;
  LPlain: TArray<Word>;
  LResult: TArray<Word>;
  LState: Cardinal;
  LRun: Integer;
  LValue: Word;
  LLength: Integer;
begin
  LState := 5;
  for LCase := 1 to 60 do
  begin
    LState := LState * 1664525 + 1013904223;
    LLength := 1 + (LState shr 20) mod 700;
    SetLength(LPlain, LLength);
    LIndex := 0;
    while LIndex < LLength do
    begin
      LState := LState * 1664525 + 1013904223;
      LValue := Word(LState shr 16);
      if (LState shr 8) mod 5 = 0 then
        LValue := $ABCD;
      LRun := 1 + (LState shr 4) mod 9;
      while (LRun > 0) and (LIndex < LLength) do
      begin
        LPlain[LIndex] := LValue;
        Inc(LIndex);
        Dec(LRun);
      end;
    end;
    LResult := Words(FRlew.Expand(TTestRlewEncoder.Encode(LPlain, $ABCD), 0, LLength * 2, $ABCD));
    Assert.AreEqual(LLength, Length(LResult));
    for LIndex := 0 to LLength - 1 do
      if LResult[LIndex] <> LPlain[LIndex] then
        Assert.Fail(Format('caso %d, parola %d: %d invece di %d', [LCase, LIndex, LResult[LIndex], LPlain[LIndex]]));
  end;
end;

procedure TTestKeenRlew.DovrebbeLeggereDaUnOffsetEIgnorareUnByteDispari;
var
  LResult: TBytes;
begin
  // the first word is skipped (the expanded length that the maps have in front); an odd length loses the last byte
  LResult := FRlew.Expand(TBytes.Create($99, $99, $01, $00, $02, $00), 2, 3, $ABCD);
  Assert.AreEqual(2, Length(LResult));
  Assert.AreEqual(1, Integer(LResult[0]));
end;

procedure TTestKeenRlew.DovrebbeRifiutareDatiTroncati;
begin
  Assert.WillRaise(
    procedure
    begin
      FRlew.Expand(TBytes.Create($01, $00), 0, 4, $ABCD);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      FRlew.Expand(TBytes.Create($CD, $AB, $02, $00), 0, 4, $ABCD);
    end, EKeenDataException);
end;

procedure TTestKeenRlew.DovrebbeRifiutareUnaRipetizioneOltreLaFine;
begin
  // the C writes after the buffer (the comment of the asm: "a repeat count that produces 0xfff0 bytes can blow this")
  Assert.WillRaise(
    procedure
    begin
      FRlew.Expand(TBytes.Create($CD, $AB, $05, $00, $01, $00), 0, 8, $ABCD);
    end, EKeenDataException);
end;

procedure TTestKeenRlew.DovrebbeRifiutareUnaLunghezzaNegativa;
begin
  Assert.WillRaise(
    procedure
    begin
      FRlew.Expand(nil, 0, -2, $ABCD);
    end, EKeenDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenRlew);

end.
