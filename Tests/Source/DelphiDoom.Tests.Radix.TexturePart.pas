{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixTexturePart                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.TexturePart;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Context, DelphiDoom.Radix.TexturePart,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixTexturePart = class(TObject)
  strict private
    FWad: IGameWadComposer;
    FAliases: TArray<string>;
    function Sky(AHeight, AWidth: Integer): TBytes;
    function Dat: TBytes;
    procedure Run(const ADat: TBytes);
    function ReadInt(const ABytes: TBytes; AOffset: Integer): Integer;
  public
    [Test]
    procedure DovrebbeScrivereLeToppeNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeScrivereUnaPatchPerOgniBitmapPiuLoStub;
    [Test]
    procedure DovrebbeScrivereIlPnamesConISeiNomiDeiCieli;
    [Test]
    procedure DovrebbeScrivereLaTabellaDelleTexture;
    [Test]
    procedure DovrebbeScrivereGliOffsetDelleTextureDeiCieliConLaSecondaPatch;
    [Test]
    procedure DovrebbeDareUnAliasPerOgniMuroEPerIlCieloTrovato;
    [Test]
    procedure DovrebbeNonFareNullaSenzaLaTabellaDeiMuri;
    [Test]
    procedure DovrebbeUsareIlPrimoCieloQuandoMancaQuelloDellEpisodio;
  end;

implementation

{ TTestRadixTexturePart }

function TTestRadixTexturePart.Sky(AHeight, AWidth: Integer): TBytes;
begin
  Result := TRadixDatBuilder.Words(AHeight) + TRadixDatBuilder.Words(AWidth) +
    TRadixDatBuilder.Pattern(AHeight * AWidth, 3);
end;

function TTestRadixTexturePart.Dat: TBytes;
var
  LBuilder: TRadixDatBuilder;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.AddWallBitmaps([32, 32, 8, 16]);
    LBuilder.Add('MainEpisodeImage[1]', Sky(4, 8));
    LBuilder.Add('FillEpisodeImage[1]', Sky(4, 8));
    Result := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRadixTexturePart.Run(const ADat: TBytes);
begin
  FWad := TRadixPartRunner.Run(TRadixTexturePart.Create('PNAMES0', 'TEXTURE0'), ADat, nil, FAliases);
end;

function TTestRadixTexturePart.ReadInt(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := PInteger(@ABytes[AOffset])^;
end;

procedure TTestRadixTexturePart.DovrebbeScrivereLeToppeNellOrdineDelVecchioCodice;
var
  LExpected: TArray<string>;
  LIndex: Integer;
begin
  Run(Dat);
  LExpected := ['P_START', 'RDXW0000', 'RDXW0001', 'RDXW0002', 'RSKY1', 'RSKY1B', 'RSKY2',
    'RSKY2B', 'RSKY3', 'RSKY3B', 'P_END', 'TEXTURE0', 'PNAMES0'];
  Assert.AreEqual(Length(LExpected), FWad.Count);
  for LIndex := 0 to High(LExpected) do
    Assert.AreEqual(LExpected[LIndex], FWad.LumpNames[LIndex]);
end;

procedure TTestRadixTexturePart.DovrebbeScrivereUnaPatchPerOgniBitmapPiuLoStub;
begin
  Run(Dat);
  // the width of the patch is the first word
  Assert.AreEqual(Integer(32), Integer(FWad.LumpData[FWad.IndexOf('RDXW0000')][0]));
  Assert.AreEqual(Integer(32), Integer(FWad.LumpData[FWad.IndexOf('RDXW0001')][0]));
  Assert.AreEqual(Integer(8), Integer(FWad.LumpData[FWad.IndexOf('RDXW0002')][0]));
  Assert.AreEqual(Integer(16), Integer(FWad.LumpData[FWad.IndexOf('RDXW0002')][2]));
end;

procedure TTestRadixTexturePart.DovrebbeScrivereIlPnamesConISeiNomiDeiCieli;
var
  LPnames: TBytes;
begin
  Run(Dat);
  LPnames := FWad.LumpData[FWad.IndexOf('PNAMES0')];
  // stub, 2 bitmaps and 3 skies of 2 patches: 9 names
  Assert.AreEqual(9, ReadInt(LPnames, 0));
  Assert.AreEqual(4 + 9 * 8, Length(LPnames));
  Assert.AreEqual('RDXW0000', TEncoding.ASCII.GetString(LPnames, 4, 8));
  Assert.AreEqual('RSKY3B' + #0#0, TEncoding.ASCII.GetString(LPnames, 4 + 8 * 8, 8));
end;

procedure TTestRadixTexturePart.DovrebbeScrivereLaTabellaDelleTexture;
var
  LTextures: TBytes;
begin
  Run(Dat);
  LTextures := FWad.LumpData[FWad.IndexOf('TEXTURE0')];
  // the stub, 2 bitmaps and 3 skies; the offset of the first one is after the table
  Assert.AreEqual(6, ReadInt(LTextures, 0));
  Assert.AreEqual(4 + 6 * 4, ReadInt(LTextures, 4));
  Assert.AreEqual(4 + 6 * 4 + 32, ReadInt(LTextures, 8));
  Assert.AreEqual(4 + 24 + 3 * 32 + 3 * 32 + 3 * 10, Length(LTextures));
end;

procedure TTestRadixTexturePart.DovrebbeScrivereGliOffsetDelleTextureDeiCieliConLaSecondaPatch;
var
  LTextures: TBytes;
begin
  Run(Dat);
  LTextures := FWad.LumpData[FWad.IndexOf('TEXTURE0')];
  // the sky 1 follows the 3 textures; the sky 2 is 32 + 10 bytes after it
  Assert.AreEqual(4 + 24 + 3 * 32, ReadInt(LTextures, 4 + 3 * 4));
  Assert.AreEqual(4 + 24 + 3 * 32 + 32 + 10, ReadInt(LTextures, 4 + 4 * 4));
  // the patch count of the sky is 2 and the width is twice the one of the picture
  Assert.AreEqual(2, Integer(PSmallInt(@LTextures[4 + 24 + 3 * 32 + 20])^));
  Assert.AreEqual(16, Integer(PSmallInt(@LTextures[4 + 24 + 3 * 32 + 12])^));
end;

procedure TTestRadixTexturePart.DovrebbeDareUnAliasPerOgniMuroEPerIlCieloTrovato;
begin
  Run(Dat);
  Assert.AreEqual(4, Length(FAliases));
  Assert.AreEqual('RDXW0001=Wall0', FAliases[0]);
  Assert.AreEqual('RDXW0002=Wall1', FAliases[1]);
  Assert.AreEqual('RSKY1=MainEpisodeImage[1]', FAliases[2]);
  Assert.AreEqual('RSKY1B=FillEpisodeImage[1]', FAliases[3]);
end;

procedure TTestRadixTexturePart.DovrebbeNonFareNullaSenzaLaTabellaDeiMuri;
var
  LBuilder: TRadixDatBuilder;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('Other', [1]);
    Run(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(0, FWad.Count);
end;

procedure TTestRadixTexturePart.DovrebbeUsareIlPrimoCieloQuandoMancaQuelloDellEpisodio;
begin
  Run(Dat);
  // the skies 2 and 3 are made from the picture of the episode 1, and have no alias
  Assert.AreEqual(Length(FWad.LumpData[FWad.IndexOf('RSKY1')]),
    Length(FWad.LumpData[FWad.IndexOf('RSKY3')]));
  Assert.AreEqual(FWad.LumpData[FWad.IndexOf('RSKY1')], FWad.LumpData[FWad.IndexOf('RSKY2')]);
end;

end.
