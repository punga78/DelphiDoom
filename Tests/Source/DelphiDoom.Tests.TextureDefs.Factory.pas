{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - the factory          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.Factory;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsFactory = class(TObject)
  public
    [Test]
    procedure TestCreatesThePatchNamesReader;
    [Test]
    procedure TestCreatesTheTextureLumpReaderForBothLayouts;
    [Test]
    procedure TestCreatesThePk3Reader;
    [Test]
    procedure TestCreatesTheFlatInfoParserWithoutLog;
    [Test]
    procedure TestCreatesALoaderThatWorksOnTheSourceItIsGiven;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Types, DelphiDoom.TextureDefs.Intf, DelphiDoom.TextureDefs.Factory,
  DelphiDoom.Tests.TextureDefs.Fakes, DelphiDoom.Tests.TextureDefs.Corpus;

{ TTestTextureDefsFactory }

procedure TTestTextureDefsFactory.TestCreatesThePatchNamesReader;
begin
  Assert.IsNotNull(TTextureDefsFactory.CreatePatchNamesReader, 'dovrebbe creare il lettore');
end;

procedure TTestTextureDefsFactory.TestCreatesTheTextureLumpReaderForBothLayouts;
begin
  Assert.IsNotNull(TTextureDefsFactory.CreateTextureLumpReader(TTextureDefsFormat.Standard));
  Assert.IsNotNull(TTextureDefsFactory.CreateTextureLumpReader(TTextureDefsFormat.Strife));
end;

procedure TTestTextureDefsFactory.TestCreatesThePk3Reader;
begin
  Assert.IsNotNull(TTextureDefsFactory.CreatePk3Reader(TTextureDefsFormat.Standard));
end;

procedure TTestTextureDefsFactory.TestCreatesTheFlatInfoParserWithoutLog;
begin
  Assert.IsNotNull(TTextureDefsFactory.CreateFlatInfoParser(nil));
end;

procedure TTestTextureDefsFactory.TestCreatesALoaderThatWorksOnTheSourceItIsGiven;
var
  LCase: TTextureDefsCase;
  LSource: TFakeLumpSource;
  LSourceIntf: ITextureDefsLumpSource;
begin
  LCase := TTextureDefsCorpus.FromLines(['pnames P0', 'tex1 A 8 8 0 0,0,0']);
  LSource := TFakeLumpSource.Create;
  LSourceIntf := LSource;
  try
    LSource.SetLump('PNAMES', LCase.BuildPatchNames);
    LSource.SetLump('TEXTURE1', LCase.BuildTextureLumpNumber(1));
    Assert.AreEqual(1, Length(TTextureDefsFactory.CreateLoader(LSourceIntf,
      TTextureDefsFormat.Standard).Load(False).Textures), 'dovrebbe leggere dalla sorgente');
  finally
    LCase.Free;
  end;
end;

end.
