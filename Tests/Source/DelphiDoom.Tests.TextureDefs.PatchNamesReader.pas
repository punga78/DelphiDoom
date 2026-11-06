{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - PNAMES               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.PatchNamesReader;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TextureDefs.Intf;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsPatchNamesReader = class(TObject)
  private
    FReader: ITextureDefsPatchNamesReader;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestReadsTheNamesInOrder;
    [Test]
    procedure TestMakesTheNamesUpperCase;
    [Test]
    procedure TestCutsTheSpacesAroundAName;
    [Test]
    procedure TestAnEmptyListIsValid;
    [Test]
    procedure TestALumpWithoutCountIsAnError;
    [Test]
    procedure TestACountThatDoesNotFitTheLumpIsAnError;
    [Test]
    procedure TestANegativeCountIsAnError;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TextureDefs.Factory, DelphiDoom.TextureDefs.Types,
  DelphiDoom.Tests.TextureDefs.Corpus;

{ TTestTextureDefsPatchNamesReader }

procedure TTestTextureDefsPatchNamesReader.Setup;
begin
  FReader := TTextureDefsFactory.CreatePatchNamesReader;
end;

procedure TTestTextureDefsPatchNamesReader.TestReadsTheNamesInOrder;
var
  LCase: TTextureDefsCase;
  LNames: TArray<string>;
begin
  LCase := TTextureDefsCorpus.FromLines(['pnames WALL1 WALL2 DOOR']);
  try
    LNames := FReader.Read(LCase.BuildPatchNames);
  finally
    LCase.Free;
  end;
  Assert.AreEqual(3, Length(LNames), 'dovrebbe leggere tre nomi');
  Assert.AreEqual('WALL1', LNames[0]);
  Assert.AreEqual('WALL2', LNames[1]);
  Assert.AreEqual('DOOR', LNames[2]);
end;

procedure TTestTextureDefsPatchNamesReader.TestMakesTheNamesUpperCase;
var
  LCase: TTextureDefsCase;
  LNames: TArray<string>;
begin
  LCase := TTextureDefsCorpus.FromLines(['pnames wall1']);
  try
    LNames := FReader.Read(LCase.BuildPatchNames);
  finally
    LCase.Free;
  end;
  Assert.AreEqual('WALL1', LNames[0], 'dovrebbe dare le maiuscole');
end;

procedure TTestTextureDefsPatchNamesReader.TestCutsTheSpacesAroundAName;
var
  LCase: TTextureDefsCase;
  LNames: TArray<string>;
begin
  LCase := TTextureDefsCorpus.FromLines(['pnames ~AB~']);
  try
    LNames := FReader.Read(LCase.BuildPatchNames);
  finally
    LCase.Free;
  end;
  Assert.AreEqual('AB', LNames[0], 'dovrebbe tagliare gli spazi');
end;

procedure TTestTextureDefsPatchNamesReader.TestAnEmptyListIsValid;
var
  LCase: TTextureDefsCase;
  LNames: TArray<string>;
begin
  LCase := TTextureDefsCorpus.FromLines(['pnames']);
  try
    LNames := FReader.Read(LCase.BuildPatchNames);
  finally
    LCase.Free;
  end;
  Assert.AreEqual(0, Length(LNames), 'dovrebbe dare una lista vuota');
end;

procedure TTestTextureDefsPatchNamesReader.TestALumpWithoutCountIsAnError;
begin
  try
    FReader.Read(nil);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(TTextureDefsError.TruncatedLump), Ord(E.Code));
  end;
end;

procedure TTestTextureDefsPatchNamesReader.TestACountThatDoesNotFitTheLumpIsAnError;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 4 + 8);
  LBytes[0] := 2; // two names, room for one
  try
    FReader.Read(LBytes);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(TTextureDefsError.BadDirectory), Ord(E.Code));
  end;
end;

procedure TTestTextureDefsPatchNamesReader.TestANegativeCountIsAnError;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 4);
  LBytes[0] := $FF;
  LBytes[1] := $FF;
  LBytes[2] := $FF;
  LBytes[3] := $FF;
  try
    FReader.Read(LBytes);
    Assert.Fail('dovrebbe dare un errore');
  except
    on E: ETextureDefsException do
      Assert.AreEqual(Ord(TTextureDefsError.BadDirectory), Ord(E.Code));
  end;
end;

end.
