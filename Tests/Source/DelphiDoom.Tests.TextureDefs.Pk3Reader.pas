{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - TEXTURE0 (PK3)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.Pk3Reader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.TextureDefs.Types;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsPk3Reader = class(TObject)
  private
    function ReadLines(const ALines: array of string; AFormat: TTextureDefsFormat): TArray<TTextureDefsTexture>;
  public
    [Test]
    procedure TestReadsNameAndSizeOfStandard;
    [Test]
    procedure TestReadsNameAndSizeOfStrife;
    [Test]
    procedure TestThePatchHasTheNameOfTheTexture;
    [Test]
    procedure TestThePatchHasNoPnamesIndex;
    [Test]
    procedure TestTheCountOfPatchesOfTheHeaderIsIgnored;
    [Test]
    procedure TestReadsTheOriginOfThePatch;
    [Test]
    procedure TestTheOriginIsPk3;
    [Test]
    procedure TestAnEntryThatDoesNotFitTheLumpIsAnError;
    [Test]
    procedure TestALumpWithoutCountIsAnError;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Factory, DelphiDoom.Tests.TextureDefs.Corpus;

{ TTestTextureDefsPk3Reader }

function TTestTextureDefsPk3Reader.ReadLines(const ALines: array of string;
  AFormat: TTextureDefsFormat): TArray<TTextureDefsTexture>;
var
  LCase: TTextureDefsCase;
begin
  LCase := TTextureDefsCorpus.FromLines(ALines);
  try
    Result := TTextureDefsFactory.CreatePk3Reader(AFormat).Read(LCase.BuildPk3Lump);
  finally
    LCase.Free;
  end;
end;

procedure TTestTextureDefsPk3Reader.TestReadsNameAndSizeOfStandard;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pk3 PK3A 64 32 1 0 0', 'pk3 PK3B 256 128 1 0 0'], TTextureDefsFormat.Standard);
  Assert.AreEqual(2, Length(LTextures), 'dovrebbe leggere due texture');
  Assert.AreEqual('PK3A', LTextures[0].Name);
  Assert.AreEqual(64, Integer(LTextures[0].Width));
  Assert.AreEqual(32, Integer(LTextures[0].Height));
  Assert.AreEqual('PK3B', LTextures[1].Name);
  Assert.AreEqual(256, Integer(LTextures[1].Width));
end;

procedure TTestTextureDefsPk3Reader.TestReadsNameAndSizeOfStrife;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['format strife', 'pk3 PK3A 64 32 1 1 2', 'pk3 PK3B 16 8 1 3 4'], TTextureDefsFormat.Strife);
  Assert.AreEqual(2, Length(LTextures), 'dovrebbe leggere due texture');
  Assert.AreEqual('PK3B', LTextures[1].Name, 'dovrebbe passare alla voce successiva di 24 byte');
  Assert.AreEqual(8, Integer(LTextures[1].Height));
  Assert.AreEqual(3, Integer(LTextures[1].Patches[0].OriginX));
end;

procedure TTestTextureDefsPk3Reader.TestThePatchHasTheNameOfTheTexture;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pk3 pk3a 8 8 1 0 0'], TTextureDefsFormat.Standard);
  Assert.AreEqual(1, Length(LTextures[0].Patches));
  Assert.AreEqual('PK3A', LTextures[0].Patches[0].PatchName, 'dovrebbe usare il nome della texture');
end;

procedure TTestTextureDefsPk3Reader.TestThePatchHasNoPnamesIndex;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pk3 PK3A 8 8 1 0 0'], TTextureDefsFormat.Standard);
  Assert.AreEqual(-1, LTextures[0].Patches[0].PatchIndex, 'dovrebbe dare -1');
end;

procedure TTestTextureDefsPk3Reader.TestTheCountOfPatchesOfTheHeaderIsIgnored;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pk3 PK3A 8 8 0 0 0', 'pk3 PK3B 8 8 9 0 0'], TTextureDefsFormat.Standard);
  Assert.AreEqual(1, Length(LTextures[0].Patches), 'dovrebbe dare sempre un patch');
  Assert.AreEqual(1, Length(LTextures[1].Patches), 'dovrebbe dare sempre un patch');
end;

procedure TTestTextureDefsPk3Reader.TestReadsTheOriginOfThePatch;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pk3 PK3A 8 8 1 -5 7'], TTextureDefsFormat.Standard);
  Assert.AreEqual(-5, Integer(LTextures[0].Patches[0].OriginX), 'dovrebbe leggere con il segno');
  Assert.AreEqual(7, Integer(LTextures[0].Patches[0].OriginY));
end;

procedure TTestTextureDefsPk3Reader.TestTheOriginIsPk3;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pk3 PK3A 8 8 1 0 0'], TTextureDefsFormat.Standard);
  Assert.AreEqual(Ord(TTextureDefsOrigin.Pk3), Ord(LTextures[0].Origin), 'dovrebbe dire PK3');
end;

procedure TTestTextureDefsPk3Reader.TestAnEntryThatDoesNotFitTheLumpIsAnError;
var
  LCase: TTextureDefsCase;
  LLump: TBytes;
begin
  LCase := TTextureDefsCorpus.FromLines(['pk3 PK3A 8 8 1 0 0', 'pk3 PK3B 8 8 1 0 0']);
  try
    LLump := LCase.BuildPk3Lump;
  finally
    LCase.Free;
  end;
  SetLength(LLump, Length(LLump) - 1);
  try
    TTextureDefsFactory.CreatePk3Reader(TTextureDefsFormat.Standard).Read(LLump);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(TTextureDefsError.TruncatedLump), Ord(E.Code));
  end;
end;

procedure TTestTextureDefsPk3Reader.TestALumpWithoutCountIsAnError;
begin
  try
    TTextureDefsFactory.CreatePk3Reader(TTextureDefsFormat.Standard).Read(nil);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(TTextureDefsError.TruncatedLump), Ord(E.Code));
  end;
end;

end.
