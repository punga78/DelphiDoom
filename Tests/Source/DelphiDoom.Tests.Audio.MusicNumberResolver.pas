{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMusicNumberResolver, TPk3SoundNames and TSoundNames    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.MusicNumberResolver;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Audio.Sound.Intf, DelphiDoom.Audio.SoundNames,
  DelphiDoom.Audio.MusicNumberResolver, DelphiDoom.Audio.Pk3SoundNames,
  DelphiDoom.Tests.Audio.OldSoundTables;

type
  /// <summary>An ILog that keeps the warnings (the text is the one the old I_Warning received)</summary>
  TSoundTestLog = class(TInterfacedObject, ILog)
  public
    Warnings: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

  TTestMusicTable = class(TInterfacedObject, IMusicTable)
  public
    Names: array of string;
    Lumps: array of Integer;
    Used: Integer;
    constructor Create(ACapacity: Integer);
    function GetCount: Integer;
    procedure SetCount(AValue: Integer);
    function Capacity: Integer;
    function FindByName(const AUpperName: string): Integer;
    procedure Define(AIndex: Integer; const AName: string; ALumpNumber: Integer);
  end;

  [TestFixture]
  [Category('audio')]
  TTestAudioMusicNumberResolver = class(TObject)
  private
    FOld: TOldSoundTables;
    FTable: TTestMusicTable;
    FTableIntf: IMusicTable;
    FLog: TSoundTestLog;
    FLogIntf: ILog;
    FResolver: IMusicNumberResolver;
    procedure Build(ACapacity, AUsed: Integer);
    procedure CompareCall(const AName: string);
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseRispostePerNomiENumeriNoti;
    [Test]
    procedure DovrebbeDareLeStesseRisposteSuNomiCasualiFinoAlLimite;
    [Test]
    procedure DovrebbeAvvisareEDareZeroSeIlNomeEVuoto;
    [Test]
    procedure DovrebbeAggiungereUnBranoCol_D_DelLump;
    [Test]
    procedure DovrebbeLanciareSeMancaUnaDipendenza;
  end;

  [TestFixture]
  [Category('audio')]
  TTestAudioPk3SoundNames = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeStesseListeDelVecchioCodiceSuNomiCasuali;
    [Test]
    procedure DovrebbeTenereSoloIFileSonori;
    [Test]
    procedure DovrebbeSaltareIlSuonoCheHaGiaUnLump;
    [Test]
    procedure DovrebbeTenereUnSoloLumpPerWavEOgg;
    [Test]
    procedure DovrebbeFermarsiAlPrimoPunto;
    [Test]
    procedure DovrebbeScartareINomiOltreOttoCaratteri;
    [Test]
    procedure DovrebbeLanciareSeMancaIlRicercatore;
  end;

  [TestFixture]
  [Category('audio')]
  TTestAudioSoundNames = class(TObject)
  public
    [Test]
    [TestCase('zero', '0,True,0', ',')]
    [TestCase('canonico', '12,True,12', ',')]
    [TestCase('meno uno', '-1,True,-1', ',')]
    [TestCase('zero iniziale', '05,False,5', ',')]
    [TestCase('piu', '+5,False,5', ',')]
    [TestCase('esadecimale', '0x10,False,16', ',')]
    [TestCase('cancelletto', '#5,False,5', ',')]
    [TestCase('non numero', 'abc,False,-1', ',')]
    procedure DovrebbeRiconoscereUnNumeroSoloSeEScrittoComeLoScriveIlMotore(const AText: string;
      AIsNumber: Boolean; ANumber: Integer);
    [Test]
    procedure DovrebbeMaiuscolareSoloLeLettereAsciiDelleMinuscole;
    [Test]
    procedure DovrebbeVedereUnPrefissoSoloAllInizio;
  end;

implementation

{ TSoundTestLog }

constructor TSoundTestLog.Create;
begin
  inherited Create;
  Warnings := TStringList.Create;
end;

destructor TSoundTestLog.Destroy;
begin
  Warnings.Free;
  inherited Destroy;
end;

procedure TSoundTestLog.Info(const AText: string);
begin
end;

procedure TSoundTestLog.Warning(const AText: string);
begin
  Warnings.Add(AText);
end;

procedure TSoundTestLog.DevWarning(const AText: string);
begin
end;

procedure TSoundTestLog.Error(const AText: string);
begin
end;

{ TTestMusicTable }

constructor TTestMusicTable.Create(ACapacity: Integer);
begin
  inherited Create;
  SetLength(Names, ACapacity);
  SetLength(Lumps, ACapacity);
end;

function TTestMusicTable.GetCount: Integer;
begin
  Result := Used;
end;

procedure TTestMusicTable.SetCount(AValue: Integer);
begin
  Used := AValue;
end;

function TTestMusicTable.Capacity: Integer;
begin
  Result := Length(Names);
end;

function TTestMusicTable.FindByName(const AUpperName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 1 to Used - 1 do
    if TSoundNames.MusicMatches(Names[LIndex], AUpperName) then
    begin
      Result := LIndex;
      Exit;
    end;
  Result := -1;
end;

procedure TTestMusicTable.Define(AIndex: Integer; const AName: string; ALumpNumber: Integer);
begin
  Names[AIndex] := AName;
  Lumps[AIndex] := ALumpNumber;
end;

{ TTestAudioMusicNumberResolver }

procedure TTestAudioMusicNumberResolver.Build(ACapacity, AUsed: Integer);
var
  LIndex: Integer;
  LName: string;
begin
  FOld := TOldSoundTables.Create(ACapacity);
  FTable := TTestMusicTable.Create(ACapacity);
  FTableIntf := FTable;
  FLog := TSoundTestLog.Create;
  FLogIntf := FLog;
  FOld.LumpNames.AddStrings(['D_FOO', 'BAR', 'D_BAZ', 'D_E1M1', 'QUX', 'D_NEW1']);
  FOld.nummusic := AUsed;
  FTable.Used := AUsed;
  for LIndex := 0 to AUsed - 1 do
  begin
    LName := Format('song%d', [LIndex]);
    FOld.MusicNames[LIndex] := LName;
    FOld.MusicLumps[LIndex] := LIndex;
    FTable.Names[LIndex] := LName;
    FTable.Lumps[LIndex] := LIndex;
  end;
  FResolver := TMusicNumberResolver.Create(FTableIntf,
    function(const AName: string): Integer
    begin
      Result := FOld.W_CheckNumForName(AName);
    end, FLogIntf);
end;

procedure TTestAudioMusicNumberResolver.TearDown;
begin
  FResolver := nil;
  FTableIntf := nil;
  FLogIntf := nil;
  FreeAndNil(FOld);
end;

procedure TTestAudioMusicNumberResolver.CompareCall(const AName: string);
var
  LIndex: Integer;
  LExpected: Integer;
  LActual: Integer;
begin
  FOld.Warnings.Clear;
  FLog.Warnings.Clear;
  LExpected := FOld.S_GetMusicNumForName(AName);
  LActual := FResolver.NumberForName(AName);
  Assert.AreEqual(LExpected, LActual, 'result of "' + AName + '"');
  Assert.AreEqual(FOld.nummusic, FTable.Used, 'count after "' + AName + '"');
  Assert.AreEqual(FOld.Warnings.Text, FLog.Warnings.Text, 'warnings of "' + AName + '"');
  for LIndex := 0 to FTable.Used - 1 do
  begin
    Assert.AreEqual(FOld.MusicNames[LIndex], FTable.Names[LIndex], 'name');
    Assert.AreEqual(FOld.MusicLumps[LIndex], FTable.Lumps[LIndex], 'lump');
  end;
end;

procedure TTestAudioMusicNumberResolver.DovrebbeDareLeStesseRispostePerNomiENumeriNoti;
const
  NAMES: array[0..27] of string = ('', '0', '1', '3', '5', '-1', '07', '0x2', '#2', '+2',
    '2147483648', 'song2', 'SONG2', 'D_SONG2', 'd_song3', 'foo', 'D_FOO', 'bar', 'D_BAR',
    'D_', 'd_', 'ds_x', 'new1', 'D_NEW1', 'zzz', 'D_baz', 'e1m1', ' 5');
var
  LName: string;
begin
  Build(40, 4);
  for LName in NAMES do
    CompareCall(LName);
end;

procedure TTestAudioMusicNumberResolver.DovrebbeDareLeStesseRisposteSuNomiCasualiFinoAlLimite;
const
  POOL: array[0..13] of string = ('foo', 'D_FOO', 'bar', 'qux', 'new1', 'x1', 'x2', 'x3',
    'x4', 'D_x5', 'D_', '3', '9', 'song1');
var
  LScenario: Integer;
  LStep: Integer;
begin
  RandSeed := 243;
  for LScenario := 1 to 60 do
  begin
    Build(6 + Random(6), 1 + Random(4));
    try
      for LStep := 1 to 25 do
        CompareCall(POOL[Random(Length(POOL))]);
    finally
      TearDown;
    end;
  end;
end;

procedure TTestAudioMusicNumberResolver.DovrebbeAvvisareEDareZeroSeIlNomeEVuoto;
begin
  Build(10, 3);
  Assert.AreEqual(0, FResolver.NumberForName(''));
  Assert.AreEqual('S_GetMusicNumForName(): No music name specified, using default'#13#10,
    FLog.Warnings[0]);
end;

procedure TTestAudioMusicNumberResolver.DovrebbeAggiungereUnBranoCol_D_DelLump;
begin
  Build(10, 3);
  Assert.AreEqual(3, FResolver.NumberForName('foo'));
  Assert.AreEqual('FOO', FTable.Names[3]);
  Assert.AreEqual(0, FOld.LumpNames.IndexOf('D_FOO'));
  Assert.AreEqual(0, FTable.Lumps[3]);
  Assert.AreEqual(4, FTable.Used);
end;

procedure TTestAudioMusicNumberResolver.DovrebbeLanciareSeMancaUnaDipendenza;
var
  LNoTable: IMusicTable;
begin
  Build(4, 1);
  LNoTable := nil;
  Assert.WillRaise(
    procedure
    begin
      TMusicNumberResolver.Create(LNoTable,
        function(const AName: string): Integer
        begin
          Result := -1;
        end, FLogIntf);
    end, EArgumentNilException);
end;

{ TTestAudioPk3SoundNames }

procedure TTestAudioPk3SoundNames.DovrebbeDareLeStesseListeDelVecchioCodiceSuNomiCasuali;
const
  BASES: array[0..9] of string = ('pistol', 'dspistol', 'DSSHOTGN', 'longername1', 'a', 'ds',
    'dsx', 'two.dots.here', 'Sound', 'abcdef');
  EXTENSIONS: array[0..11] of string = ('.wav', '.ogg', '.WAV', '.flac', '.oga', '.au',
    '.voc', '.snd', '.txt', '.png', '', '.wavx');
  FOLDERS: array[0..3] of string = ('', 'sounds/', 'sounds\x\', 'a/b/');
var
  LScenario: Integer;
  LStep: Integer;
  LOld: TOldSoundTables;
  LOldNames: TStringList;
  LNew: TPk3SoundNames;
  LFile: string;
  LActual: TArray<string>;
  LIndex: Integer;
begin
  RandSeed := 2430;
  for LScenario := 1 to 200 do
  begin
    LOld := TOldSoundTables.Create(2);
    LOldNames := TStringList.Create;
    try
      if Random(2) = 0 then
        LOld.LumpNames.AddStrings(['PISTOL', 'DSSHOTGN', 'DSSOUND', 'ABCDEF']);
      LNew := TPk3SoundNames.Create(
        function(const AName: string): Integer
        begin
          Result := LOld.W_CheckNumForName(AName);
        end);
      try
        for LStep := 1 to 12 do
        begin
          LFile := FOLDERS[Random(Length(FOLDERS))] + BASES[Random(Length(BASES))] +
            EXTENSIONS[Random(Length(EXTENSIONS))];
          LOld.S_AddFileName(LFile, LOldNames);
          LNew.AddFile(LFile);
          LActual := LNew.Names;
          Assert.AreEqual<Integer>(LOldNames.Count, Length(LActual), 'count after ' + LFile);
          for LIndex := 0 to LOldNames.Count - 1 do
            Assert.AreEqual(LOldNames[LIndex], LActual[LIndex], 'name after ' + LFile);
        end;
      finally
        LNew.Free;
      end;
    finally
      LOldNames.Free;
      LOld.Free;
    end;
  end;
end;

procedure TTestAudioPk3SoundNames.DovrebbeTenereSoloIFileSonori;
var
  LNames: TPk3SoundNames;
begin
  LNames := TPk3SoundNames.Create(function(const AName: string): Integer begin Result := -1 end);
  try
    LNames.AddFile('a.txt');
    LNames.AddFile('b.png');
    LNames.AddFile('c.wav');
    Assert.AreEqual<Integer>(1, Length(LNames.Names));
    Assert.AreEqual('DSC', LNames.Names[0]);
  finally
    LNames.Free;
  end;
end;

procedure TTestAudioPk3SoundNames.DovrebbeSaltareIlSuonoCheHaGiaUnLump;
var
  LNames: TPk3SoundNames;
begin
  LNames := TPk3SoundNames.Create(
    function(const AName: string): Integer
    begin
      if AName = 'DSPISTOL' then
        Result := 7
      else
        Result := -1;
    end);
  try
    LNames.AddFile('pistol.wav');
    LNames.AddFile('other.wav');
    Assert.AreEqual<Integer>(1, Length(LNames.Names));
    Assert.AreEqual('DSOTHER', LNames.Names[0]);
  finally
    LNames.Free;
  end;
end;

procedure TTestAudioPk3SoundNames.DovrebbeTenereUnSoloLumpPerWavEOgg;
var
  LNames: TPk3SoundNames;
begin
  LNames := TPk3SoundNames.Create(function(const AName: string): Integer begin Result := -1 end);
  try
    LNames.AddFile('pistol.wav');
    LNames.AddFile('pistol.ogg');
    LNames.AddFile('dspistol.flac');
    Assert.AreEqual<Integer>(1, Length(LNames.Names));
  finally
    LNames.Free;
  end;
end;

procedure TTestAudioPk3SoundNames.DovrebbeFermarsiAlPrimoPunto;
var
  LNames: TPk3SoundNames;
begin
  LNames := TPk3SoundNames.Create(function(const AName: string): Integer begin Result := -1 end);
  try
    LNames.AddFile('sounds\two.dots.here.wav');
    Assert.AreEqual('DSTWO', LNames.Names[0]);
  finally
    LNames.Free;
  end;
end;

procedure TTestAudioPk3SoundNames.DovrebbeScartareINomiOltreOttoCaratteri;
var
  LNames: TPk3SoundNames;
begin
  LNames := TPk3SoundNames.Create(function(const AName: string): Integer begin Result := -1 end);
  try
    LNames.AddFile('abcdefghi.wav');
    LNames.AddFile('abcdefgh.wav');
    Assert.AreEqual<Integer>(1, Length(LNames.Names));
    Assert.AreEqual('ABCDEFGH', LNames.Names[0]);
  finally
    LNames.Free;
  end;
end;

procedure TTestAudioPk3SoundNames.DovrebbeLanciareSeMancaIlRicercatore;
var
  LFinder: TSoundLumpFinder;
begin
  LFinder := nil;
  Assert.WillRaise(
    procedure
    begin
      TPk3SoundNames.Create(LFinder);
    end, EArgumentNilException);
end;

{ TTestAudioSoundNames }

procedure TTestAudioSoundNames.DovrebbeRiconoscereUnNumeroSoloSeEScrittoComeLoScriveIlMotore(
  const AText: string; AIsNumber: Boolean; ANumber: Integer);
var
  LNumber: Integer;
begin
  Assert.AreEqual(AIsNumber, TSoundNames.IsNumber(AText, LNumber));
  Assert.AreEqual(ANumber, LNumber);
end;

procedure TTestAudioSoundNames.DovrebbeMaiuscolareSoloLeLettereAsciiDelleMinuscole;
begin
  Assert.AreEqual('ABC-Z_09 '#$E9, TSoundNames.Upper('abc-z_09 '#$E9));
end;

procedure TTestAudioSoundNames.DovrebbeVedereUnPrefissoSoloAllInizio;
begin
  Assert.IsTrue(TSoundNames.HasPrefix('DS', 'DSPISTOL'));
  Assert.IsFalse(TSoundNames.HasPrefix('DS', 'XDS'));
  Assert.IsFalse(TSoundNames.HasPrefix('DS', 'D'));
end;

end.
