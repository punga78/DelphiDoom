{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the palette library - TColorRegionLumps                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.ColorRegionLumps;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Palette.Types,
  DelphiDoom.Palette.ColorRegionLumps;

type
  [TestFixture]
  [Category('palette')]
  TTestPaletteColorRegionLumps = class(TObject)
  strict private
    function Lengths(ACount, AValue: Integer): TArray<Integer>;
  public
    [Test]
    procedure DovrebbeDareZeroSenzaLump;
    [Test]
    procedure DovrebbeContareTuttiIlumpDiUnaSezioneCompleta;
    [Test]
    procedure DovrebbeFermarsiAlLimiteDelleRegioniDelMotore;
    [Test]
    procedure DovrebbeFermarsiACR_ENDDiUnaSezioneCorta;
    [Test]
    procedure DovrebbeFermarsiAlLumpCheNonHaLaDimensioneDiUnaTabella;
    [Test]
    procedure DovrebbeFermarsiSeMancanoLeDimensioni;
  end;

implementation

{ TTestPaletteColorRegionLumps }

function TTestPaletteColorRegionLumps.Lengths(ACount, AValue: Integer): TArray<Integer>;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := AValue;
end;

procedure TTestPaletteColorRegionLumps.DovrebbeDareZeroSenzaLump;
begin
  Assert.AreEqual(0, TColorRegionLumps.ValidCount(nil, nil));
end;

procedure TTestPaletteColorRegionLumps.DovrebbeContareTuttiIlumpDiUnaSezioneCompleta;
var
  LNames: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LNames, REGION_COUNT);
  for LIndex := 0 to REGION_COUNT - 1 do
    LNames[LIndex] := 'CR' + IntToStr(LIndex);
  Assert.AreEqual(REGION_COUNT,
    TColorRegionLumps.ValidCount(LNames, Lengths(REGION_COUNT, COLORMAP_ROW_SIZE)));
end;

procedure TTestPaletteColorRegionLumps.DovrebbeFermarsiAlLimiteDelleRegioniDelMotore;
var
  LNames: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LNames, REGION_COUNT + 5);
  for LIndex := 0 to High(LNames) do
    LNames[LIndex] := 'CR' + IntToStr(LIndex);
  Assert.AreEqual(REGION_COUNT,
    TColorRegionLumps.ValidCount(LNames, Lengths(Length(LNames), COLORMAP_ROW_SIZE)));
end;

// Regression: Rad-X has 11 regions then CR_END, GLGAMMA (17090 bytes), BLUMAP...: the old
// loop read 24 lumps into 256 bytes each and overwrote the headers of the zone
procedure TTestPaletteColorRegionLumps.DovrebbeFermarsiACR_ENDDiUnaSezioneCorta;
var
  LNames: TArray<string>;
  LLengths: TArray<Integer>;
  LIndex: Integer;
begin
  SetLength(LNames, REGION_COUNT);
  for LIndex := 0 to REGION_COUNT - 1 do
    LNames[LIndex] := 'CR' + IntToStr(LIndex);
  LNames[11] := 'cr_end';
  LLengths := Lengths(REGION_COUNT, COLORMAP_ROW_SIZE);
  Assert.AreEqual(11, TColorRegionLumps.ValidCount(LNames, LLengths));
end;

procedure TTestPaletteColorRegionLumps.DovrebbeFermarsiAlLumpCheNonHaLaDimensioneDiUnaTabella;
var
  LNames: TArray<string>;
  LLengths: TArray<Integer>;
begin
  LNames := TArray<string>.Create('CRBRICK', 'CRTAN', 'GLGAMMA', 'CRGRAY');
  LLengths := TArray<Integer>.Create(256, 256, 17090, 256);
  Assert.AreEqual(2, TColorRegionLumps.ValidCount(LNames, LLengths));
end;

procedure TTestPaletteColorRegionLumps.DovrebbeFermarsiSeMancanoLeDimensioni;
begin
  Assert.AreEqual(1, TColorRegionLumps.ValidCount(TArray<string>.Create('A', 'B', 'C'),
    TArray<Integer>.Create(256)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPaletteColorRegionLumps);

end.
