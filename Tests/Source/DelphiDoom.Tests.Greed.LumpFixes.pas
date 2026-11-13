{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the corrections of the data         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.LumpFixes;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Intf, DelphiDoom.Greed.LumpFixes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedLumpFixes = class(TObject)
  private
    function Fix(ASize: Integer; ACrc32: Cardinal; const AReplacement: TBytes): TGreedLumpFix;
  public
    [Test]
    procedure DovrebbeSostituireUnLumpDellaStessaDimensioneEDelloStessoCrc;
    [Test]
    procedure DovrebbeLasciareUnLumpDiAltraDimensione;
    [Test]
    procedure DovrebbeLasciareUnLumpDiAltroCrc;
    [Test]
    procedure DovrebbeLasciareUnLumpVuoto;
    [Test]
    procedure DovrebbeProvareLeVoceInOrdine;
    [Test]
    procedure DovrebbeDareUnaCopiaDellaSostituzione;
    [Test]
    procedure DovrebbeNonFareNullaSenzaVoci;
    [Test]
    procedure DovrebbeAvereLaVoceDelPstDellOriginale;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.Builders, DelphiDoom.Greed.PstCorrection;

{ TTestGreedLumpFixes }

function TTestGreedLumpFixes.Fix(ASize: Integer; ACrc32: Cardinal; const AReplacement: TBytes): TGreedLumpFix;
begin
  Result.Size := ASize;
  Result.Crc32 := ACrc32;
  Result.Replacement := AReplacement;
end;

procedure TTestGreedLumpFixes.DovrebbeSostituireUnLumpDellaStessaDimensioneEDelloStessoCrc;
var
  LOriginal: TBytes;
  LFixes: IGreedLumpFixes;
  LResult: TBytes;
begin
  LOriginal := TBytes.Create(1, 2, 3, 4);
  LFixes := TGreedLumpFixes.Create([Fix(4, Cardinal(StrToInt64('$' + TGreedLumps.CrcHex(LOriginal))), TBytes.Create(9, 8, 7, 6))]);
  LResult := LFixes.Apply(LOriginal);
  Assert.AreEqual<Integer>(4, Length(LResult));
  Assert.AreEqual(9, Integer(LResult[0]));
  Assert.AreEqual(6, Integer(LResult[3]));
end;

procedure TTestGreedLumpFixes.DovrebbeLasciareUnLumpDiAltraDimensione;
var
  LOriginal: TBytes;
  LFixes: IGreedLumpFixes;
begin
  LOriginal := TBytes.Create(1, 2, 3, 4);
  LFixes := TGreedLumpFixes.Create([Fix(5, Cardinal(StrToInt64('$' + TGreedLumps.CrcHex(LOriginal))), TBytes.Create(9))]);
  Assert.AreEqual(1, Integer(LFixes.Apply(LOriginal)[0]));
end;

procedure TTestGreedLumpFixes.DovrebbeLasciareUnLumpDiAltroCrc;
var
  LFixes: IGreedLumpFixes;
begin
  LFixes := TGreedLumpFixes.Create([Fix(4, $12345678, TBytes.Create(9))]);
  Assert.AreEqual<Integer>(4, Length(LFixes.Apply(TBytes.Create(1, 2, 3, 4))));
  Assert.AreEqual(1, Integer(LFixes.Apply(TBytes.Create(1, 2, 3, 4))[0]));
end;

procedure TTestGreedLumpFixes.DovrebbeLasciareUnLumpVuoto;
var
  LFixes: IGreedLumpFixes;
begin
  LFixes := TGreedLumpFixes.Create([Fix(0, 0, TBytes.Create(9))]);
  Assert.AreEqual<Integer>(0, Length(LFixes.Apply(nil)));
end;

procedure TTestGreedLumpFixes.DovrebbeProvareLeVoceInOrdine;
var
  LOriginal: TBytes;
  LCrc: Cardinal;
  LFixes: IGreedLumpFixes;
begin
  LOriginal := TBytes.Create(5, 6);
  LCrc := Cardinal(StrToInt64('$' + TGreedLumps.CrcHex(LOriginal)));
  LFixes := TGreedLumpFixes.Create([Fix(2, LCrc, TBytes.Create(1)), Fix(2, LCrc, TBytes.Create(2))]);
  Assert.AreEqual(1, Integer(LFixes.Apply(LOriginal)[0]));
end;

procedure TTestGreedLumpFixes.DovrebbeDareUnaCopiaDellaSostituzione;
var
  LOriginal: TBytes;
  LFixes: IGreedLumpFixes;
  LFirst: TBytes;
begin
  LOriginal := TBytes.Create(5, 6);
  LFixes := TGreedLumpFixes.Create([Fix(2, Cardinal(StrToInt64('$' + TGreedLumps.CrcHex(LOriginal))), TBytes.Create(1, 1))]);
  LFirst := LFixes.Apply(LOriginal);
  LFirst[0] := 99;
  Assert.AreEqual(1, Integer(LFixes.Apply(LOriginal)[0]));
end;

procedure TTestGreedLumpFixes.DovrebbeNonFareNullaSenzaVoci;
var
  LFixes: IGreedLumpFixes;
begin
  LFixes := TGreedLumpFixes.Create([]);
  Assert.AreEqual<Integer>(2, Length(LFixes.Apply(TBytes.Create(1, 2))));
end;

procedure TTestGreedLumpFixes.DovrebbeAvereLaVoceDelPstDellOriginale;
var
  LFixes: IGreedLumpFixes;
  LBytes: TBytes;
begin
  Assert.AreEqual(10463, Length(GREED_PST_CORRECTED));
  // the first word of the corrected sprite (left offset $34) and its last byte, as in g_fixlump.pas
  Assert.AreEqual($34, Integer(GREED_PST_CORRECTED[0]));
  Assert.AreEqual($0D, Integer(GREED_PST_CORRECTED[10462]));
  // the default table has a lump of that size that is not replaced: its CRC is not the one of the original
  LFixes := TGreedLumpFixes.CreateDefault;
  SetLength(LBytes, 10463);
  Assert.AreEqual(0, Integer(LFixes.Apply(LBytes)[0]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedLumpFixes);

end.
