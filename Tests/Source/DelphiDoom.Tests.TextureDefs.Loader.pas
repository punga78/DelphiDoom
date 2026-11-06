{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - the loader           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.Loader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.TextureDefs.Types, DelphiDoom.TextureDefs.Intf,
  DelphiDoom.Tests.TextureDefs.Fakes, DelphiDoom.Tests.TextureDefs.Corpus;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsLoader = class(TObject)
  private
    FSource: TFakeLumpSource;
    FSourceIntf: ITextureDefsLumpSource;
    FCase: TTextureDefsCase;
    procedure Fill(const ALines: array of string);
    function Load(AIncludePk3: Boolean; AFormat: TTextureDefsFormat = TTextureDefsFormat.Standard): TTextureDefsSet;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestNumbersTheTexturesLumpAfterLump;
    [Test]
    procedure TestTagsEachTextureWithItsLump;
    [Test]
    procedure TestTheLumpsTwoAndThreeAreOptional;
    [Test]
    procedure TestSkipsAnEmptySecondLump;
    [Test]
    procedure TestAppendsTheTexturesOfThePk3WhenAsked;
    [Test]
    procedure TestDoesNotReadTexture0Otherwise;
    [Test]
    procedure TestGivesThePatchNames;
    [Test]
    procedure TestWorksForStrife;
    [Test]
    procedure TestMissingPnamesIsAnError;
    [Test]
    procedure TestMissingTexture1IsAnError;
    [Test]
    procedure TestMissingTexture0IsAnErrorWhenAsked;
    [Test]
    procedure TestReadsPnamesFirst;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Factory;

{ TTestTextureDefsLoader }

procedure TTestTextureDefsLoader.Setup;
begin
  FSource := TFakeLumpSource.Create;
  FSourceIntf := FSource;
  FCase := nil;
end;

procedure TTestTextureDefsLoader.TearDown;
begin
  FCase.Free;
end;

procedure TTestTextureDefsLoader.Fill(const ALines: array of string);
begin
  FCase := TTextureDefsCorpus.FromLines(ALines);
  FSource.SetLump('PNAMES', FCase.BuildPatchNames);
  FSource.SetLump('TEXTURE1', FCase.BuildTextureLumpNumber(1));
  if FCase.HasTextureLump(2) then
    FSource.SetLump('TEXTURE2', FCase.BuildTextureLumpNumber(2));
  if FCase.HasTextureLump(3) then
    FSource.SetLump('TEXTURE3', FCase.BuildTextureLumpNumber(3));
  if FCase.HasPk3 then
    FSource.SetLump('TEXTURE0', FCase.BuildPk3Lump);
end;

function TTestTextureDefsLoader.Load(AIncludePk3: Boolean; AFormat: TTextureDefsFormat): TTextureDefsSet;
begin
  Result := TTextureDefsFactory.CreateLoader(FSourceIntf, AFormat).Load(AIncludePk3);
end;

procedure TTestTextureDefsLoader.TestNumbersTheTexturesLumpAfterLump;
var
  LSet: TTextureDefsSet;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0', 'tex1 B 8 8 0 0,0,0', 'tex2 C 8 8 0 0,0,0', 'tex3 D 8 8 0 0,0,0']);
  LSet := Load(False);
  Assert.AreEqual(4, Length(LSet.Textures), 'dovrebbe dare quattro texture');
  Assert.AreEqual('A', LSet.Textures[0].Name);
  Assert.AreEqual('B', LSet.Textures[1].Name);
  Assert.AreEqual('C', LSet.Textures[2].Name);
  Assert.AreEqual('D', LSet.Textures[3].Name);
end;

procedure TTestTextureDefsLoader.TestTagsEachTextureWithItsLump;
var
  LSet: TTextureDefsSet;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0', 'tex2 C 8 8 0 0,0,0', 'tex3 D 8 8 0 0,0,0']);
  LSet := Load(False);
  Assert.AreEqual(Ord(TTextureDefsOrigin.Texture1), Ord(LSet.Textures[0].Origin));
  Assert.AreEqual(Ord(TTextureDefsOrigin.Texture2), Ord(LSet.Textures[1].Origin));
  Assert.AreEqual(Ord(TTextureDefsOrigin.Texture3), Ord(LSet.Textures[2].Origin));
end;

procedure TTestTextureDefsLoader.TestTheLumpsTwoAndThreeAreOptional;
var
  LSet: TTextureDefsSet;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0']);
  LSet := Load(False);
  Assert.AreEqual(1, Length(LSet.Textures), 'dovrebbe bastare TEXTURE1');
end;

procedure TTestTextureDefsLoader.TestSkipsAnEmptySecondLump;
var
  LSet: TTextureDefsSet;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0', 'empty2', 'tex3 D 8 8 0 0,0,0']);
  LSet := Load(False);
  Assert.AreEqual(2, Length(LSet.Textures), 'dovrebbe saltare il lump vuoto');
  Assert.AreEqual('D', LSet.Textures[1].Name);
end;

procedure TTestTextureDefsLoader.TestAppendsTheTexturesOfThePk3WhenAsked;
var
  LSet: TTextureDefsSet;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0', 'pk3 PK3A 8 8 1 0 0']);
  LSet := Load(True);
  Assert.AreEqual(2, Length(LSet.Textures), 'dovrebbe aggiungere le texture del PK3');
  Assert.AreEqual('PK3A', LSet.Textures[1].Name, 'dovrebbe metterle in coda');
  Assert.AreEqual(Ord(TTextureDefsOrigin.Pk3), Ord(LSet.Textures[1].Origin));
end;

procedure TTestTextureDefsLoader.TestDoesNotReadTexture0Otherwise;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0', 'pk3 PK3A 8 8 1 0 0']);
  Assert.AreEqual(1, Length(Load(False).Textures), 'non dovrebbe leggere TEXTURE0');
  Assert.IsFalse(FSource.Reads.Contains('TEXTURE0'), 'non dovrebbe nemmeno chiederlo');
end;

procedure TTestTextureDefsLoader.TestGivesThePatchNames;
var
  LSet: TTextureDefsSet;
begin
  Fill(['pnames WALL1 DOOR', 'tex1 A 8 8 0 1,0,0']);
  LSet := Load(False);
  Assert.AreEqual(2, Length(LSet.PatchNames), 'dovrebbe dare i nomi di PNAMES');
  Assert.AreEqual('DOOR', LSet.PatchNames[1]);
  Assert.AreEqual('DOOR', LSet.Textures[0].Patches[0].PatchName);
end;

procedure TTestTextureDefsLoader.TestWorksForStrife;
var
  LSet: TTextureDefsSet;
begin
  Fill(['format strife', 'pnames P0 P1', 'tex1 A 8 8 0 1,2,3', 'tex2 B 8 8 0 0,0,0']);
  LSet := Load(False, TTextureDefsFormat.Strife);
  Assert.AreEqual(2, Length(LSet.Textures), 'dovrebbe leggere il layout di Strife');
  Assert.AreEqual(3, Integer(LSet.Textures[0].Patches[0].OriginY));
end;

procedure TTestTextureDefsLoader.TestMissingPnamesIsAnError;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0']);
  FSource := TFakeLumpSource.Create;
  FSourceIntf := FSource;
  FSource.SetLump('TEXTURE1', FCase.BuildTextureLumpNumber(1));
  try
    Load(False);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(TTextureDefsError.MissingLump), Ord(E.Code));
  end;
end;

procedure TTestTextureDefsLoader.TestMissingTexture1IsAnError;
begin
  Fill(['pnames P0']);
  FSource := TFakeLumpSource.Create;
  FSourceIntf := FSource;
  FSource.SetLump('PNAMES', FCase.BuildPatchNames);
  try
    Load(False);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(TTextureDefsError.MissingLump), Ord(E.Code));
  end;
end;

procedure TTestTextureDefsLoader.TestMissingTexture0IsAnErrorWhenAsked;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0']);
  try
    Load(True);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(TTextureDefsError.MissingLump), Ord(E.Code));
  end;
end;

procedure TTestTextureDefsLoader.TestReadsPnamesFirst;
begin
  Fill(['pnames P0', 'tex1 A 8 8 0 0,0,0']);
  Load(False);
  Assert.AreEqual('PNAMES', FSource.Reads[0], 'dovrebbe leggere PNAMES per primo');
  Assert.AreEqual('TEXTURE1', FSource.Reads[1]);
  Assert.AreEqual('TEXTURE2', FSource.Reads[2]);
  Assert.AreEqual('TEXTURE3', FSource.Reads[3]);
end;

end.
