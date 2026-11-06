{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - TEXTUREx lumps       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.TextureLumpReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.TextureDefs.Types;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsTextureLumpReader = class(TObject)
  private
    function ReadLines(const ALines: array of string; AFormat: TTextureDefsFormat;
      AOrigin: TTextureDefsOrigin = TTextureDefsOrigin.Texture1): TArray<TTextureDefsTexture>;
    procedure ExpectError(const ALump: TBytes; AFormat: TTextureDefsFormat;
      const APatchNames: TArray<string>; AExpected: TTextureDefsError);
  public
    [Test]
    procedure TestReadsNameSizeAndPatchesOfStandard;
    [Test]
    procedure TestReadsNameSizeAndPatchesOfStrife;
    [Test]
    procedure TestMakesTheNameUpperCase;
    [Test]
    procedure TestResolvesThePatchNamesOfPnames;
    [Test]
    procedure TestKeepsTheOriginAndTheMaskedFlag;
    [Test]
    procedure TestAllowsATextureWithoutPatches;
    [Test]
    procedure TestReadsNegativeOffsets;
    [Test]
    procedure TestAnEmptyLumpGivesNoTextures;
    [Test]
    procedure TestADirectoryOffsetPastTheEndIsAnError;
    [Test]
    procedure TestATextureThatDoesNotFitTheLumpIsAnError;
    [Test]
    procedure TestAPatchIndexOutsidePnamesIsAnError;
    [Test]
    procedure TestALumpWithoutCountIsAnError;
    [Test]
    procedure TestACountThatDoesNotFitTheDirectoryIsAnError;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Factory, DelphiDoom.Tests.TextureDefs.Corpus;

{ TTestTextureDefsTextureLumpReader }

function TTestTextureDefsTextureLumpReader.ReadLines(const ALines: array of string;
  AFormat: TTextureDefsFormat; AOrigin: TTextureDefsOrigin): TArray<TTextureDefsTexture>;
var
  LCase: TTextureDefsCase;
begin
  LCase := TTextureDefsCorpus.FromLines(ALines);
  try
    Result := TTextureDefsFactory.CreateTextureLumpReader(AFormat).Read(
      LCase.BuildTextureLumpNumber(1), AOrigin, TTextureDefsFactory.CreatePatchNamesReader.Read(
        LCase.BuildPatchNames));
  finally
    LCase.Free;
  end;
end;

procedure TTestTextureDefsTextureLumpReader.ExpectError(const ALump: TBytes; AFormat: TTextureDefsFormat;
  const APatchNames: TArray<string>; AExpected: TTextureDefsError);
begin
  try
    TTextureDefsFactory.CreateTextureLumpReader(AFormat).Read(ALump, TTextureDefsOrigin.Texture1,
      APatchNames);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(AExpected), Ord(E.Code), 'dovrebbe dare il codice giusto');
  end;
end;

procedure TTestTextureDefsTextureLumpReader.TestReadsNameSizeAndPatchesOfStandard;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pnames A B', 'tex1 STARTAN 128 96 0 0,1,2 1,-3,4'], TTextureDefsFormat.Standard);
  Assert.AreEqual(1, Length(LTextures), 'dovrebbe leggere una texture');
  Assert.AreEqual('STARTAN', LTextures[0].Name);
  Assert.AreEqual(128, Integer(LTextures[0].Width));
  Assert.AreEqual(96, Integer(LTextures[0].Height));
  Assert.AreEqual(2, Length(LTextures[0].Patches));
  Assert.AreEqual(1, Integer(LTextures[0].Patches[0].OriginX));
  Assert.AreEqual(2, Integer(LTextures[0].Patches[0].OriginY));
  Assert.AreEqual(-3, Integer(LTextures[0].Patches[1].OriginX));
  Assert.AreEqual(4, Integer(LTextures[0].Patches[1].OriginY));
end;

procedure TTestTextureDefsTextureLumpReader.TestReadsNameSizeAndPatchesOfStrife;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['format strife', 'pnames A B', 'tex1 STARTAN 128 96 0 0,1,2 1,-3,4',
    'tex1 SECOND 64 64 0 1,0,0'], TTextureDefsFormat.Strife);
  Assert.AreEqual(2, Length(LTextures), 'dovrebbe leggere due texture');
  Assert.AreEqual('STARTAN', LTextures[0].Name);
  Assert.AreEqual(96, Integer(LTextures[0].Height));
  Assert.AreEqual(-3, Integer(LTextures[0].Patches[1].OriginX));
  Assert.AreEqual('SECOND', LTextures[1].Name, 'dovrebbe trovare la seconda dopo i patch di 6 byte');
  Assert.AreEqual('B', LTextures[1].Patches[0].PatchName);
end;

procedure TTestTextureDefsTextureLumpReader.TestMakesTheNameUpperCase;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pnames A', 'tex1 sTaRtAn 8 8 0 0,0,0'], TTextureDefsFormat.Standard);
  Assert.AreEqual('STARTAN', LTextures[0].Name, 'dovrebbe dare le maiuscole');
end;

procedure TTestTextureDefsTextureLumpReader.TestResolvesThePatchNamesOfPnames;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pnames WALL1 WALL2 DOOR', 'tex1 T 8 8 0 2,0,0 0,0,0'], TTextureDefsFormat.Standard);
  Assert.AreEqual(2, LTextures[0].Patches[0].PatchIndex);
  Assert.AreEqual('DOOR', LTextures[0].Patches[0].PatchName, 'dovrebbe dare il nome del patch');
  Assert.AreEqual('WALL1', LTextures[0].Patches[1].PatchName);
end;

procedure TTestTextureDefsTextureLumpReader.TestKeepsTheOriginAndTheMaskedFlag;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pnames A', 'tex1 T 8 8 1 0,0,0'], TTextureDefsFormat.Standard,
    TTextureDefsOrigin.Texture3);
  Assert.AreEqual(Ord(TTextureDefsOrigin.Texture3), Ord(LTextures[0].Origin), 'dovrebbe tenere l''origine');
  Assert.AreEqual(1, LTextures[0].Masked, 'dovrebbe tenere il flag masked');
end;

procedure TTestTextureDefsTextureLumpReader.TestAllowsATextureWithoutPatches;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pnames A', 'tex1 EMPTYTEX 8 8 0', 'tex1 NEXT 8 8 0 0,0,0'], TTextureDefsFormat.Standard);
  Assert.AreEqual(0, Length(LTextures[0].Patches), 'dovrebbe ammettere zero patch');
  Assert.AreEqual('NEXT', LTextures[1].Name);
end;

procedure TTestTextureDefsTextureLumpReader.TestReadsNegativeOffsets;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pnames A', 'tex1 T 8 8 0 0,-32768,32767'], TTextureDefsFormat.Standard);
  Assert.AreEqual(-32768, Integer(LTextures[0].Patches[0].OriginX), 'dovrebbe leggere con il segno');
  Assert.AreEqual(32767, Integer(LTextures[0].Patches[0].OriginY));
end;

procedure TTestTextureDefsTextureLumpReader.TestAnEmptyLumpGivesNoTextures;
var
  LTextures: TArray<TTextureDefsTexture>;
begin
  LTextures := ReadLines(['pnames A'], TTextureDefsFormat.Standard);
  Assert.AreEqual(0, Length(LTextures), 'dovrebbe dare zero texture');
end;

procedure TTestTextureDefsTextureLumpReader.TestADirectoryOffsetPastTheEndIsAnError;
var
  LCase: TTextureDefsCase;
  LLump: TBytes;
begin
  LCase := TTextureDefsCorpus.FromLines(['pnames A', 'tex1 T 8 8 0 0,0,0', 'badoffset1 0']);
  try
    LLump := LCase.BuildTextureLumpNumber(1);
  finally
    LCase.Free;
  end;
  ExpectError(LLump, TTextureDefsFormat.Standard, ['A'], TTextureDefsError.BadDirectory);
end;

procedure TTestTextureDefsTextureLumpReader.TestATextureThatDoesNotFitTheLumpIsAnError;
var
  LCase: TTextureDefsCase;
  LLump: TBytes;
begin
  LCase := TTextureDefsCorpus.FromLines(['pnames A', 'tex1 T 8 8 0 0,0,0 0,1,1']);
  try
    LLump := LCase.BuildTextureLumpNumber(1);
  finally
    LCase.Free;
  end;
  SetLength(LLump, Length(LLump) - 5); // the second patch is cut
  ExpectError(LLump, TTextureDefsFormat.Standard, ['A'], TTextureDefsError.BadDirectory);
end;

procedure TTestTextureDefsTextureLumpReader.TestAPatchIndexOutsidePnamesIsAnError;
var
  LCase: TTextureDefsCase;
  LLump: TBytes;
begin
  LCase := TTextureDefsCorpus.FromLines(['pnames A', 'tex1 T 8 8 0 5,0,0']);
  try
    LLump := LCase.BuildTextureLumpNumber(1);
  finally
    LCase.Free;
  end;
  ExpectError(LLump, TTextureDefsFormat.Standard, ['A'], TTextureDefsError.BadPatchIndex);
end;

procedure TTestTextureDefsTextureLumpReader.TestALumpWithoutCountIsAnError;
begin
  ExpectError(nil, TTextureDefsFormat.Standard, nil, TTextureDefsError.TruncatedLump);
end;

procedure TTestTextureDefsTextureLumpReader.TestACountThatDoesNotFitTheDirectoryIsAnError;
var
  LLump: TBytes;
begin
  SetLength(LLump, 8);
  LLump[0] := 3; // three offsets, room for one
  ExpectError(LLump, TTextureDefsFormat.Standard, nil, TTextureDefsError.TruncatedLump);
end;

end.
