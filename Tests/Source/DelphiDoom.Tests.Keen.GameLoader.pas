{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - opening the game                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.GameLoader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf,
  DelphiDoom.Tests.Keen.Builders;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenGameLoader = class(TObject)
  private
    FGame: TTestGame;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAprireIlGiocoConITreFile;
    [Test]
    procedure DovrebbeAprireIlGiocoConINomiAlternativi;
    [Test]
    procedure DovrebbeDireQualeFileManca;
    [Test]
    procedure DovrebbeDireQualeIntestazioneManca;
    [Test]
    procedure DovrebbeRifiutareUnDizionarioRotto;
    [Test]
    procedure DovrebbeRifiutareUnGiocoSenzaFile;
    [Test]
    procedure DovrebbeVolerOgniParteDelGioco;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.MemoryFiles, DelphiDoom.Keen.GameData;

const
  ALL_FILES: array[0..8] of string = ('KDREAMS.EGA', 'EGAHEAD.KDR', 'EGADICT.KDR', 'KDREAMS.MAP',
    'MAPHEAD.KDR', 'MAPDICT.KDR', 'KDREAMS.AUD', 'AUDIOHHD.KDR', 'AUDIODCT.KDR');

{ TTestKeenGameLoader }

procedure TTestKeenGameLoader.Setup;
begin
  FGame := TTestGame.Create(4);
end;

procedure TTestKeenGameLoader.TearDown;
begin
  FGame.Free;
end;

procedure TTestKeenGameLoader.DovrebbeAprireIlGiocoConITreFile;
var
  LData: IKeenGameData;
begin
  LData := TKeenFactory.OpenGameData(FGame.Files);
  Assert.AreEqual(KEEN_NUMCHUNKS, LData.Graphics.Chunks.ChunkCount);
  Assert.AreEqual(2, Length(LData.Maps.MapNumbers));
  Assert.AreEqual(KEEN_NUMSNDCHUNKS, LData.Audio.ChunkCount);
  Assert.AreEqual(300, Length(LData.Audio.Read(5)));
end;

procedure TTestKeenGameLoader.DovrebbeAprireIlGiocoConINomiAlternativi;
var
  LFiles: TKeenMemoryFiles;
  LFilesIntf: IKeenDataFiles;
  LName: string;
  LAlternative: string;
begin
  LFiles := TKeenMemoryFiles.Create;
  LFilesIntf := LFiles;
  for LName in ALL_FILES do
  begin
    LAlternative := LName;
    if LName = 'KDREAMS.EGA' then
      LAlternative := 'EGAGRAPH.KDR'
    else if LName = 'KDREAMS.MAP' then
      LAlternative := 'GAMEMAPS.KDR'
    else if LName = 'KDREAMS.AUD' then
      LAlternative := 'AUDIOT.KDR';
    LFiles.Add(LAlternative, FGame.Files.ReadAll(LName));
  end;
  Assert.AreEqual(2, Length(TKeenFactory.OpenGameData(LFilesIntf).Maps.MapNumbers));
end;

procedure TTestKeenGameLoader.DovrebbeDireQualeFileManca;
var
  LFiles: TKeenMemoryFiles;
  LFilesIntf: IKeenDataFiles;
  LName: string;
  LMessage: string;
begin
  for LName in ALL_FILES do
  begin
    LFiles := TKeenMemoryFiles.Create;
    LFilesIntf := LFiles;
    for LMessage in ALL_FILES do
      if LMessage <> LName then
        LFiles.Add(LMessage, FGame.Files.ReadAll(LMessage));
    LMessage := '';
    try
      TKeenFactory.OpenGameData(LFilesIntf);
    except
      on E: EKeenFileNotFoundException do
        LMessage := E.Message;
    end;
    Assert.IsTrue(LMessage <> '', 'senza ' + LName + ' non deve aprire');
    if LName = 'KDREAMS.EGA' then
      Assert.Contains(LMessage, 'EGAGRAPH.KDR')
    else if LName = 'KDREAMS.MAP' then
      Assert.Contains(LMessage, 'GAMEMAPS.KDR')
    else if LName = 'KDREAMS.AUD' then
      Assert.Contains(LMessage, 'AUDIOT.KDR')
    else
      Assert.Contains(LMessage, LName);
  end;
end;

procedure TTestKeenGameLoader.DovrebbeDireQualeIntestazioneManca;
var
  LFiles: TKeenMemoryFiles;
  LFilesIntf: IKeenDataFiles;
  LName: string;
  LMessage: string;
begin
  LFiles := TKeenMemoryFiles.Create;
  LFilesIntf := LFiles;
  for LName in ALL_FILES do
    if LName <> 'MAPHEAD.KDR' then
      LFiles.Add(LName, FGame.Files.ReadAll(LName));
  LMessage := '';
  try
    TKeenFactory.OpenGameData(LFilesIntf);
  except
    on E: EKeenFileNotFoundException do
      LMessage := E.Message;
  end;
  Assert.Contains(LMessage, 'MAPHEAD.KDR');
end;

procedure TTestKeenGameLoader.DovrebbeRifiutareUnDizionarioRotto;
var
  LFiles: TKeenMemoryFiles;
  LFilesIntf: IKeenDataFiles;
  LName: string;
begin
  LFiles := TKeenMemoryFiles.Create;
  LFilesIntf := LFiles;
  for LName in ALL_FILES do
    LFiles.Add(LName, FGame.Files.ReadAll(LName));
  LFiles.Add('MAPDICT.KDR', TBytes.Create(1, 2, 3));
  Assert.WillRaise(procedure begin TKeenFactory.OpenGameData(LFilesIntf); end, EKeenDataException);
  // the graphics file was opened before the dictionary of the maps was read: nothing stays open, the test
  // would show a leak at the end
  LFiles.Add('MAPDICT.KDR', FGame.Files.ReadAll('MAPDICT.KDR'));
  LFiles.Add('AUDIOHHD.KDR', TBytes.Create(1, 2, 3, 4));
  Assert.WillRaise(procedure begin TKeenFactory.OpenGameData(LFilesIntf); end, EKeenDataException);
end;

procedure TTestKeenGameLoader.DovrebbeRifiutareUnGiocoSenzaFile;
begin
  Assert.WillRaise(procedure begin TKeenFactory.OpenGameData(nil); end, EArgumentNilException);
end;

procedure TTestKeenGameLoader.DovrebbeVolerOgniParteDelGioco;
var
  LData: IKeenGameData;
begin
  LData := TKeenFactory.OpenGameData(FGame.Files);
  Assert.WillRaise(procedure begin TKeenGameData.Create(nil, LData.Maps, LData.Audio); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenGameData.Create(LData.Graphics, nil, LData.Audio); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenGameData.Create(LData.Graphics, LData.Maps, nil); end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenGameLoader);

end.
