{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the skies and of UMAPINFO of Speed Haste               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.SkyTextures;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameData.Intf, DelphiDoom.Speed.SkyTextures;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedSkyTextures = class(TObject)
  strict private
    FWad: IGameWadComposer;
    FPatches: IGamePatchBuilder;
    function Patch(AWidth, AHeight, AColor: Integer): TBytes;
    function Pnames(const ANames: array of string): TBytes;
    procedure AddCircuit(const AMarker, ASky, AMountain: string);
    procedure AddSkyPictures;
    function PixelOf(const APatch: TBytes; AColumn, ARow: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeFareUnaTexturePerOgniPistaConCieloEMontagne;
    [Test]
    procedure DovrebbeAggiungereLaTextureComeUltimoLump;
    [Test]
    procedure DovrebbeDescrivereUnaTextureDiUnPatchAlto128;
    [Test]
    procedure DovrebbeMettereLeNuvoleInAltoEFinoAllOrizzonte;
    [Test]
    procedure DovrebbeMettereLeMontagneInFondoLasciandoIBuchi;
    [Test]
    procedure DovrebbeCopiareLImmagineFraIMarcatoriDeiPatch;
    [Test]
    procedure NonDovrebbeFareNienteSenzaPNAMES;
    [Test]
    procedure NonDovrebbeFareUnaTexturePerUnaPistaSenzaImmagini;
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
  end;

  [TestFixture]
  [Category('speed')]
  TTestSpeedUmapInfoBuilder = class(TObject)
  strict private
    FWad: IGameWadComposer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareNomeECieloDiOgniPista;
    [Test]
    procedure DovrebbePreferireLaTextureDelCielo;
    [Test]
    procedure NonDovrebbeScrivereNienteSenzaPiste;
    [Test]
    procedure DovrebbeRifiutareUnWadNil;
  end;

implementation

uses
  DelphiDoom.GameData.Types, DelphiDoom.GameData.Factory, DelphiDoom.Palette.Factory, DelphiDoom.Speed.UmapInfoBuilder;

const
  TRANSPARENT_INDEX = 255;

{ TTestSpeedSkyTextures }

procedure TTestSpeedSkyTextures.Setup;
begin
  FWad := TGameDataFactory.CreateWadComposer;
  FPatches := TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Speed, TPaletteFactory.CreateColorMatcher);
end;

// A picture of one color (an index of the palette), as the lump of a patch
function TTestSpeedSkyTextures.Patch(AWidth, AHeight, AColor: Integer): TBytes;
var
  LImage: TBytes;
begin
  SetLength(LImage, AWidth * AHeight);
  FillChar(LImage[0], Length(LImage), AColor);
  Result := FPatches.FromColumns(LImage, AWidth, AHeight, False);
end;

// The index of the palette at a pixel of a patch whose columns are made of one post
function TTestSpeedSkyTextures.PixelOf(const APatch: TBytes; AColumn, ARow: Integer): Integer;
var
  LOffset, LTop, LCount: Integer;
begin
  Result := TRANSPARENT_INDEX;
  LOffset := PInteger(@APatch[8 + 4 * AColumn])^;
  while APatch[LOffset] <> 255 do
  begin
    LTop := APatch[LOffset];
    LCount := APatch[LOffset + 1];
    if (ARow >= LTop) and (ARow < LTop + LCount) then
      Exit(APatch[LOffset + 3 + ARow - LTop]);
    Inc(LOffset, LCount + 4);
  end;
end;

function TTestSpeedSkyTextures.Pnames(const ANames: array of string): TBytes;
var
  LIndex, LChar: Integer;
begin
  SetLength(Result, 4 + 8 * Length(ANames));
  PInteger(@Result[0])^ := Length(ANames);
  for LIndex := 0 to High(ANames) do
    for LChar := 1 to Length(ANames[LIndex]) do
      Result[4 + LIndex * 8 + LChar - 1] := Ord(ANames[LIndex][LChar]);
end;

procedure TTestSpeedSkyTextures.AddCircuit(const AMarker, ASky, AMountain: string);
begin
  FWad.AddMarker(AMarker);
  FWad.AddLump('THINGS', nil);
  FWad.AddText('MAPDATA', 'name=Test circuit'#13#10'sky=' + ASky + #13#10'mountain=' + AMountain + #13#10);
end;

// The pictures of the first circuit: the clouds of color 40 and mountains of color 60
procedure TTestSpeedSkyTextures.AddSkyPictures;
begin
  FWad.AddLump('PNAMES', Pnames(['WALL1', 'WALL2']));
  FWad.AddLump('NUBES0', Patch(32, 70, 40));
  FWad.AddLump('MOUNT0', Patch(32, 49, 60));
  AddCircuit('E1M1', 'NUBES0', 'MOUNT0');
end;

procedure TTestSpeedSkyTextures.DovrebbeFareUnaTexturePerOgniPistaConCieloEMontagne;
var
  LEntries: TArray<TSpeedSkyEntry>;
begin
  AddSkyPictures;
  FWad.AddLump('NUBES1', Patch(32, 70, 41));
  FWad.AddLump('MOUNT1', Patch(32, 35, 61));
  AddCircuit('E1M2', 'NUBES1', 'MOUNT1');
  LEntries := TSpeedSkyTextures.Append(FWad, FPatches, TRANSPARENT_INDEX);
  Assert.AreEqual(2, Length(LEntries));
  Assert.AreEqual('E1M1', LEntries[0].Level);
  Assert.AreEqual('SKYE1M1', LEntries[0].Texture);
  Assert.AreEqual('SKYE1M2', LEntries[1].Texture);
end;

procedure TTestSpeedSkyTextures.DovrebbeAggiungereLaTextureComeUltimoLump;
begin
  AddSkyPictures;
  TSpeedSkyTextures.Append(FWad, FPatches, TRANSPARENT_INDEX);
  // the last lump with a name is the one that the engine reads
  Assert.AreEqual('TEXTURE3', FWad.LumpNames[FWad.Count - 1]);
  Assert.AreEqual('PNAMES', FWad.LumpNames[FWad.Count - 2]);
end;

procedure TTestSpeedSkyTextures.DovrebbeDescrivereUnaTextureDiUnPatchAlto128;
var
  LData: TBytes;
  LOffset: Integer;
begin
  AddSkyPictures;
  TSpeedSkyTextures.Append(FWad, FPatches, TRANSPARENT_INDEX);
  LData := FWad.LumpData[FWad.IndexOf('TEXTURE3')];
  Assert.AreEqual(1, PInteger(@LData[0])^, 'una texture');
  LOffset := PInteger(@LData[4])^;
  Assert.AreEqual<Integer>(32, PSmallInt(@LData[LOffset + 12])^, 'larghezza');
  Assert.AreEqual<Integer>(128, PSmallInt(@LData[LOffset + 14])^, 'altezza');
  Assert.AreEqual<Integer>(1, PSmallInt(@LData[LOffset + 20])^, 'un patch');
  Assert.AreEqual<Integer>(2, PSmallInt(@LData[LOffset + 26])^, 'il patch e il primo nome nuovo');
  // PNAMES: the two names of before and the picture
  LData := FWad.LumpData[FWad.Count - 2];
  Assert.AreEqual(3, PInteger(@LData[0])^);
  Assert.AreEqual('SKYE1M1', string(PAnsiChar(@LData[4 + 2 * 8])));
end;

procedure TTestSpeedSkyTextures.DovrebbeMettereLeNuvoleInAltoEFinoAllOrizzonte;
var
  LPicture: TBytes;
begin
  AddSkyPictures;
  TSpeedSkyTextures.Append(FWad, FPatches, TRANSPARENT_INDEX);
  LPicture := FWad.LumpData[FWad.IndexOf('SKYE1M1')];
  Assert.AreEqual(40, PixelOf(LPicture, 3, 0), 'la prima riga');
  Assert.AreEqual(40, PixelOf(LPicture, 3, 69), 'l ultima delle nuvole');
  // the rows between the clouds and the mountains are the last row of the clouds
  Assert.AreEqual(40, PixelOf(LPicture, 3, 75), 'sotto le nuvole');
end;

procedure TTestSpeedSkyTextures.DovrebbeMettereLeMontagneInFondoLasciandoIBuchi;
var
  LMountain, LPicture, LImage: TBytes;
begin
  FWad.AddLump('PNAMES', Pnames(['WALL1']));
  FWad.AddLump('NUBES0', Patch(8, 70, 40));
  // mountains: the first column is only mountains, the second has a hole on the top half
  SetLength(LImage, 8 * 10);
  FillChar(LImage[0], Length(LImage), 60);
  FillChar(LImage[10], 5, TRANSPARENT_INDEX);
  LMountain := FPatches.FromColumns(LImage, 8, 10, False);
  FWad.AddLump('MOUNT0', LMountain);
  AddCircuit('E1M1', 'NUBES0', 'MOUNT0');
  TSpeedSkyTextures.Append(FWad, FPatches, TRANSPARENT_INDEX);
  LPicture := FWad.LumpData[FWad.IndexOf('SKYE1M1')];
  Assert.AreEqual(60, PixelOf(LPicture, 0, 127), 'il fondo e montagna');
  Assert.AreEqual(60, PixelOf(LPicture, 0, 118), 'il bordo alto della montagna');
  Assert.AreEqual(40, PixelOf(LPicture, 1, 118), 'dove la montagna ha un buco si vede il cielo');
  Assert.AreEqual(60, PixelOf(LPicture, 1, 123), 'sotto il buco la montagna');
end;

procedure TTestSpeedSkyTextures.DovrebbeCopiareLImmagineFraIMarcatoriDeiPatch;
var
  LStart: Integer;
begin
  AddSkyPictures;
  TSpeedSkyTextures.Append(FWad, FPatches, TRANSPARENT_INDEX);
  LStart := FWad.IndexOf('P_START');
  Assert.IsTrue(LStart >= 0, 'P_START');
  Assert.AreEqual('SKYE1M1', FWad.LumpNames[LStart + 1]);
  Assert.AreEqual('P_END', FWad.LumpNames[LStart + 2]);
end;

procedure TTestSpeedSkyTextures.NonDovrebbeFareNienteSenzaPNAMES;
begin
  FWad.AddLump('NUBES0', Patch(32, 70, 40));
  FWad.AddLump('MOUNT0', Patch(32, 49, 60));
  AddCircuit('E1M1', 'NUBES0', 'MOUNT0');
  Assert.AreEqual(0, Length(TSpeedSkyTextures.Append(FWad, FPatches, TRANSPARENT_INDEX)));
  Assert.AreEqual(-1, FWad.IndexOf('TEXTURE3'));
end;

procedure TTestSpeedSkyTextures.NonDovrebbeFareUnaTexturePerUnaPistaSenzaImmagini;
begin
  FWad.AddLump('PNAMES', Pnames(['WALL1']));
  AddCircuit('E1M1', 'NUBES0', 'MOUNT0');
  Assert.AreEqual(0, Length(TSpeedSkyTextures.Append(FWad, FPatches, TRANSPARENT_INDEX)));
  Assert.AreEqual(-1, FWad.IndexOf('TEXTURE3'));
end;

procedure TTestSpeedSkyTextures.DovrebbeRifiutareGliOggettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedSkyTextures.Append(nil, FPatches, TRANSPARENT_INDEX);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TSpeedSkyTextures.Append(FWad, nil, TRANSPARENT_INDEX);
    end, EArgumentNilException);
end;

{ TTestSpeedUmapInfoBuilder }

procedure TTestSpeedUmapInfoBuilder.Setup;
begin
  FWad := TGameDataFactory.CreateWadComposer;
end;

procedure TTestSpeedUmapInfoBuilder.DovrebbeDareNomeECieloDiOgniPista;
var
  LText: string;
begin
  FWad.AddMarker('E1M1');
  FWad.AddLump('THINGS', nil);
  FWad.AddText('MAPDATA', 'name=Racer''s Edge'#13#10'sky=SKY1'#13#10);
  LText := TSpeedUmapInfoBuilder.Build(FWad, nil);
  Assert.IsTrue(Pos('MAP E1M1', LText) > 0);
  Assert.IsTrue(Pos('levelname = "Racer''s Edge"', LText) > 0);
  Assert.IsTrue(Pos('skytexture = "SKY1"', LText) > 0);
end;

procedure TTestSpeedUmapInfoBuilder.DovrebbePreferireLaTextureDelCielo;
var
  LText: string;
  LSkies: TArray<TSpeedSkyEntry>;
begin
  FWad.AddMarker('E1M1');
  FWad.AddText('MAPDATA', 'name=A'#13#10'sky=NUBES0'#13#10);
  SetLength(LSkies, 1);
  LSkies[0].Level := 'E1M1';
  LSkies[0].Texture := 'SKYE1M1';
  LText := TSpeedUmapInfoBuilder.Build(FWad, LSkies);
  Assert.IsTrue(Pos('skytexture = "SKYE1M1"', LText) > 0);
  Assert.AreEqual(0, Pos('NUBES0', LText));
end;

procedure TTestSpeedUmapInfoBuilder.NonDovrebbeScrivereNienteSenzaPiste;
begin
  FWad.AddLump('PLAYPAL', nil);
  Assert.AreEqual('', TSpeedUmapInfoBuilder.Build(FWad, nil));
end;

procedure TTestSpeedUmapInfoBuilder.DovrebbeRifiutareUnWadNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedUmapInfoBuilder.Build(nil, nil);
    end, EArgumentNilException);
end;

end.
