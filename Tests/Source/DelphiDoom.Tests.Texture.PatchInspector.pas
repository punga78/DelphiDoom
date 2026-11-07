{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTexturePatchInspector                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.PatchInspector;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.PatchInspector,
  DelphiDoom.Tests.Texture.Samples;

type
  [TestFixture]
  [Category('texture')]
  TTestTexturePatchInspector = class(TObject)
  public
    [Test]
    procedure DovrebbeAccettareLePatchValide;
    [Test]
    procedure DovrebbeRifiutareLeSampleCheNonSonoPatch;
    [Test]
    procedure DovrebbeRifiutareUnaPatchTroncataACaso;
    [Test]
    procedure DovrebbeRifiutareUnPostFuoriDallImmagine;
    [Test]
    procedure DovrebbeRifiutareLeDimensioniNonValide;
    [Test]
    procedure DovrebbeAccettareUnaPatchSenzaColonne;
    [Test]
    procedure DovrebbeUsareSoloLaParteDelLumpIndicataDallaDimensione;
    [Test]
    procedure DovrebbeRifiutareDatiCasuali;
  end;

implementation

procedure TTestTexturePatchInspector.DovrebbeAccettareLePatchValide;
var
  LFile: TTextureSampleFile;
begin
  for LFile in TTextureSamples.PatchFiles do
    if not LFile.ShapeOnly then
      Assert.IsTrue(TTexturePatchInspector.IsValid(LFile.Bytes, Length(LFile.Bytes)), LFile.Name);
end;

procedure TTestTexturePatchInspector.DovrebbeRifiutareLeSampleCheNonSonoPatch;
var
  LFile: TTextureSampleFile;
begin
  for LFile in TTextureSamples.PatchFiles do
    if LFile.ShapeOnly and (Length(LFile.Bytes) >= 8) and (LFile.Name <> 'patch-zero-width') then
      Assert.IsFalse(TTexturePatchInspector.IsValid(LFile.Bytes, Length(LFile.Bytes)), LFile.Name);
end;

procedure TTestTexturePatchInspector.DovrebbeRifiutareUnaPatchTroncataACaso;
var
  LBytes: TBytes;
  LCut: Integer;
  LFiles: TTextureSampleFiles;
begin
  LFiles := TTextureSamples.PatchFiles;
  LBytes := LFiles[2].Bytes;
  for LCut := 1 to 5 do
  begin
    SetLength(LBytes, Length(LBytes) - 7);
    Assert.IsFalse(TTexturePatchInspector.IsValid(LBytes, Length(LBytes)), 'dovrebbe rifiutare la patch senza gli ultimi byte');
  end;
end;

procedure TTestTexturePatchInspector.DovrebbeRifiutareUnPostFuoriDallImmagine;
begin
  // 1x2: a post of 5 pixels from the row 0
  Assert.IsFalse(TTexturePatchInspector.IsValid(
    TBytes.Create(1, 0, 2, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 5, 0, 1, 2, 3, 4, 5, 0, $FF), 22),
    'dovrebbe rifiutare un post che esce dall''altezza');
end;

procedure TTestTexturePatchInspector.DovrebbeRifiutareLeDimensioniNonValide;
begin
  Assert.IsFalse(TTexturePatchInspector.IsValid(TBytes.Create($01, $30, 8, 0, 0, 0, 0, 0), 8), 'dovrebbe rifiutare una larghezza oltre 8192');
  Assert.IsFalse(TTexturePatchInspector.IsValid(TBytes.Create(8, 0, $01, $04, 0, 0, 0, 0), 8), 'dovrebbe rifiutare un''altezza oltre 1024');
  Assert.IsFalse(TTexturePatchInspector.IsValid(TBytes.Create($FF, $FF, 8, 0, 0, 0, 0, 0), 8), 'dovrebbe rifiutare una larghezza negativa');
end;

procedure TTestTexturePatchInspector.DovrebbeAccettareUnaPatchSenzaColonne;
begin
  // as the old code: a width of 0 has no column to look at
  Assert.IsTrue(TTexturePatchInspector.IsValid(TBytes.Create(0, 0, 8, 0, 0, 0, 0, 0), 8), 'dovrebbe accettare la larghezza 0');
end;

procedure TTestTexturePatchInspector.DovrebbeUsareSoloLaParteDelLumpIndicataDallaDimensione;
var
  LBytes: TBytes;
  LFiles: TTextureSampleFiles;
begin
  LFiles := TTextureSamples.PatchFiles;
  LBytes := LFiles[0].Bytes;
  Assert.IsTrue(TTexturePatchInspector.IsValid(LBytes, Length(LBytes)), 'dovrebbe accettare la patch intera');
  Assert.IsFalse(TTexturePatchInspector.IsValid(LBytes, Length(LBytes) div 2), 'dovrebbe rifiutare con la dimensione piu'' corta');
  Assert.IsTrue(TTexturePatchInspector.IsValid(LBytes, Length(LBytes) + 100), 'dovrebbe fermarsi alla fine dei byte che ci sono');
end;

procedure TTestTexturePatchInspector.DovrebbeRifiutareDatiCasuali;
var
  LSeed: Integer;
  LAccepted: Integer;
begin
  LAccepted := 0;
  for LSeed := 1 to 50 do
    if TTexturePatchInspector.IsValid(TTextureSamples.RandomBytes(Cardinal(LSeed), 300), 300) then
      Inc(LAccepted);
  Assert.AreEqual(0, LAccepted, 'dovrebbe rifiutare dati casuali');
end;

end.
