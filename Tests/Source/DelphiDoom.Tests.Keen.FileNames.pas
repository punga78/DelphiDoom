{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the names of the files               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.FileNames;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.MemoryFiles;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenFileNames = class(TObject)
  private
    FMemory: TKeenMemoryFiles;
    FFiles: IKeenDataFiles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeUsareIINomiDelSorgente;
    [Test]
    procedure DovrebbeTrovareIlNomeDelPrimoDellaLista;
    [Test]
    procedure DovrebbeProvareINomiAlternativi;
    [Test]
    procedure DovrebbePreferireIlNomeDelSorgenteSeCeNeSonoDue;
    [Test]
    procedure DovrebbeSollevareUnErroreConIlNomeDelFileMancante;
    [Test]
    procedure DovrebbeSollevareUnErroreConTuttiINomiProvati;
  end;

implementation

uses
  DelphiDoom.Keen.FileNames;

{ TTestKeenFileNames }

procedure TTestKeenFileNames.Setup;
begin
  FMemory := TKeenMemoryFiles.Create;
  FFiles := FMemory;
end;

procedure TTestKeenFileNames.TearDown;
begin
  FFiles := nil;
end;

procedure TTestKeenFileNames.DovrebbeUsareIINomiDelSorgente;
begin
  // id_ca.c opens KDREAMS.EGA, KDREAMS.MAP and KDREAMS.AUD; the headers are the .KDR of the folder "static"
  Assert.AreEqual('KDREAMS.EGA', TKeenFileNames.GraphicsData[0]);
  Assert.AreEqual('KDREAMS.MAP', TKeenFileNames.MapData[0]);
  Assert.AreEqual('KDREAMS.AUD', TKeenFileNames.AudioData[0]);
  Assert.AreEqual('EGAHEAD.KDR', TKeenFileNames.GraphicsHeader[0]);
  Assert.AreEqual('EGADICT.KDR', TKeenFileNames.GraphicsDictionary[0]);
  Assert.AreEqual('MAPHEAD.KDR', TKeenFileNames.MapHeader[0]);
  Assert.AreEqual('MAPDICT.KDR', TKeenFileNames.MapDictionary[0]);
  Assert.AreEqual('AUDIOHHD.KDR', TKeenFileNames.AudioHeader[0]);
  Assert.AreEqual('AUDIODCT.KDR', TKeenFileNames.AudioDictionary[0]);
end;

procedure TTestKeenFileNames.DovrebbeTrovareIlNomeDelPrimoDellaLista;
begin
  FMemory.Add('KDREAMS.EGA', TBytes.Create(1));
  Assert.AreEqual('KDREAMS.EGA', TKeenFileNames.Resolve(FFiles, TKeenFileNames.GraphicsData));
end;

procedure TTestKeenFileNames.DovrebbeProvareINomiAlternativi;
begin
  FMemory.Add('EGAGRAPH.KDR', TBytes.Create(1));
  Assert.AreEqual('EGAGRAPH.KDR', TKeenFileNames.Resolve(FFiles, TKeenFileNames.GraphicsData));
end;

procedure TTestKeenFileNames.DovrebbePreferireIlNomeDelSorgenteSeCeNeSonoDue;
begin
  FMemory.Add('EGAGRAPH.KDR', TBytes.Create(1));
  FMemory.Add('KDREAMS.EGA', TBytes.Create(1));
  Assert.AreEqual('KDREAMS.EGA', TKeenFileNames.Resolve(FFiles, TKeenFileNames.GraphicsData));
end;

procedure TTestKeenFileNames.DovrebbeSollevareUnErroreConIlNomeDelFileMancante;
var
  LMessage: string;
begin
  LMessage := '';
  try
    TKeenFileNames.Resolve(FFiles, TKeenFileNames.MapHeader);
  except
    on E: EKeenFileNotFoundException do
      LMessage := E.Message;
  end;
  Assert.Contains(LMessage, 'MAPHEAD.KDR');
end;

procedure TTestKeenFileNames.DovrebbeSollevareUnErroreConTuttiINomiProvati;
var
  LMessage: string;
begin
  LMessage := '';
  try
    TKeenFileNames.Resolve(FFiles, TKeenFileNames.GraphicsData);
  except
    on E: EKeenFileNotFoundException do
      LMessage := E.Message;
  end;
  Assert.Contains(LMessage, 'KDREAMS.EGA');
  Assert.Contains(LMessage, 'EGAGRAPH.KDR');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenFileNames);

end.
