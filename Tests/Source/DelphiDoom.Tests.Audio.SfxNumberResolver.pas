{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSfxNumberResolver and TSfxRandomGroup                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.SfxNumberResolver;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Audio.Sound.Intf, DelphiDoom.Audio.SoundNames,
  DelphiDoom.Audio.SfxNumberResolver, DelphiDoom.Audio.SfxRandomGroup,
  DelphiDoom.Tests.Audio.OldSoundTables, DelphiDoom.Tests.Audio.MusicNumberResolver;

type
  /// <summary>
  ///   ISfxTable on the records of the test, written as the table of the engine of each game:
  ///   the tag name only for Hexen, the numbers of DEHEXTRA and the free slots only for Doom
  /// </summary>
  TTestSfxTable = class(TInterfacedObject, ISfxTable)
  strict private
    FGame: TOldSoundGame;
    FDefault: Integer;
  public
    Sfx: array of TSfxRecord;
    Used: Integer;
    constructor Create(AGame: TOldSoundGame; ACapacity, ADefault: Integer);
    function GetCount: Integer;
    procedure SetCount(AValue: Integer);
    function Capacity: Integer;
    function NameOf(AIndex: Integer): string;
    function DefaultSfx: Integer;
    function HasDynamicSlots: Boolean;
    function FindByName(const AUpperName: string): Integer;
    function FindEmptySlot(AFirst: Integer): Integer;
    procedure Define(AIndex: Integer; const AName, ATagName: string);
  end;

  [TestFixture]
  [Category('audio')]
  TTestAudioSfxNumberResolver = class(TObject)
  private
    FOld: TOldSoundTables;
    FTable: TTestSfxTable;
    FTableIntf: ISfxTable;
    FLog: TSoundTestLog;
    FLogIntf: ILog;
    FResolver: ISfxNumberResolver;
    procedure Build(AGame: TOldSoundGame; ACapacity, AUsed: Integer);
    procedure Release;
    procedure CompareTables(const AContext: string);
    function CompareCall(const AName: string): Integer;
    procedure RunNames(AGame: TOldSoundGame; ACapacity, AUsed: Integer;
      const ANames: array of string);
    // the glue of S_GetRandomSoundList of Base\sounds.pas on the table of the test
    function NewRandomList(ASfxNumber: Integer): TList<Integer>;
    procedure CompareRandom(ASfxNumber: Integer);
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDiDoomPerNomiENumeri;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDiHereticPerNomiENumeri;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDiHexenPerNomiENumeri;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDiStrifePerNomiENumeri;
    [Test]
    procedure DovrebbeDareLeStesseRisposteSuNomiCasualiFinoAlLimiteInOgniGioco;
    [Test]
    procedure DovrebbeDareLeStesseListeCasualiDiUnGruppoDiSuoni;
    [Test]
    procedure DovrebbeUsareLoSlotDelDehExtraSoloSeHaIlNomeAtteso;
    [Test]
    procedure DovrebbeRiusareGliSlotVuotiDiDoomSenzaTornareIndietro;
    [Test]
    procedure DovrebbeDareIlSuonoDiDefaultSeIlNomeEVuoto;
    [Test]
    procedure DovrebbeTenereIlNomeGrezzoComeTagDiHexen;
    [Test]
    procedure DovrebbeTogliereIlPrefissoDsSoloQuandoAggiungeUnSuono;
    [Test]
    procedure DovrebbeDareIlNomeInMaiuscoloODiVuotoFuoriDallaTabella;
    [Test]
    procedure DovrebbeTrovareIlGruppoConLeCifreMancanti;
    [Test]
    procedure DovrebbeTroncareAOttoCaratteriINomiDelGruppo;
    [Test]
    procedure DovrebbeLanciareSeMancaUnaDipendenza;
  end;

implementation

{ TTestSfxTable }

constructor TTestSfxTable.Create(AGame: TOldSoundGame; ACapacity, ADefault: Integer);
begin
  inherited Create;
  FGame := AGame;
  FDefault := ADefault;
  SetLength(Sfx, ACapacity);
end;

function TTestSfxTable.GetCount: Integer;
begin
  Result := Used;
end;

procedure TTestSfxTable.SetCount(AValue: Integer);
begin
  Used := AValue;
end;

function TTestSfxTable.Capacity: Integer;
begin
  Result := Length(Sfx);
end;

function TTestSfxTable.NameOf(AIndex: Integer): string;
begin
  Result := Sfx[AIndex].Name;
end;

function TTestSfxTable.DefaultSfx: Integer;
begin
  Result := FDefault;
end;

function TTestSfxTable.HasDynamicSlots: Boolean;
begin
  Result := FGame = osgDoom;
end;

function TTestSfxTable.FindByName(const AUpperName: string): Integer;
var
  LIndex: Integer;
  LMatch: Boolean;
begin
  for LIndex := 1 to Used - 1 do
  begin
    if FGame = osgHexen then
      LMatch := TSoundNames.SfxMatchesTagged(Sfx[LIndex].TagName, Sfx[LIndex].Name, AUpperName)
    else
      LMatch := TSoundNames.SfxMatches(Sfx[LIndex].Name, AUpperName);
    if LMatch then
    begin
      Result := LIndex;
      Exit;
    end;
  end;
  Result := -1;
end;

function TTestSfxTable.FindEmptySlot(AFirst: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := AFirst to Used - 1 do
    if Sfx[LIndex].Name = '' then
    begin
      Result := LIndex;
      Exit;
    end;
  Result := -1;
end;

procedure TTestSfxTable.Define(AIndex: Integer; const AName, ATagName: string);
begin
  if FGame = osgHexen then
    Sfx[AIndex].TagName := ATagName;
  Sfx[AIndex].Name := AName;
  Sfx[AIndex].Priority := 72;
  Sfx[AIndex].Pitch := -1;
  Sfx[AIndex].HasData := False;
  Sfx[AIndex].Usefulness := 0;
  Sfx[AIndex].LumpNum := -1;
  Sfx[AIndex].RandomList := nil;
  if FGame = osgHexen then
  begin
    Sfx[AIndex].NumChannels := 1;
    Sfx[AIndex].ChangePitch := False;
  end
  else
  begin
    Sfx[AIndex].Singularity := False;
    Sfx[AIndex].HasLink := False;
    Sfx[AIndex].Volume := -1;
  end;
end;

{ TTestAudioSfxNumberResolver }

function Describe(const ARecord: TSfxRecord): string;
begin
  Result := Format('%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d',
    [ARecord.Name, ARecord.TagName, Ord(ARecord.Singularity), ARecord.Priority,
     Ord(ARecord.HasLink), ARecord.Pitch, ARecord.Volume, Ord(ARecord.HasData),
     ARecord.Usefulness, ARecord.LumpNum, ARecord.NumChannels, Ord(ARecord.ChangePitch),
     Ord(Assigned(ARecord.RandomList))]);
end;

procedure TTestAudioSfxNumberResolver.Build(AGame: TOldSoundGame; ACapacity, AUsed: Integer);
const
  DEFAULTS: array[TOldSoundGame] of Integer = (1, 2, 3, 4);
var
  LIndex: Integer;
begin
  FOld := TOldSoundTables.Create(2);
  FOld.InitSounds(AGame, ACapacity, AUsed, DEFAULTS[AGame]);
  FTable := TTestSfxTable.Create(AGame, ACapacity, DEFAULTS[AGame]);
  FTableIntf := FTable;
  FTable.Used := AUsed;
  for LIndex := 0 to AUsed - 1 do
  begin
    if AGame = osgHexen then
      FOld.Sfxs[LIndex].TagName := Format('tag%d', [LIndex]);
    FTable.Sfx[LIndex] := FOld.Sfxs[LIndex];
  end;
  // slots beyond the used ones: the DEHEXTRA names of the patches, and others that are not
  if ACapacity > 700 then
  begin
    FOld.Sfxs[500].Name := 'fre500';
    FOld.Sfxs[510].Name := 'fre510';
    FOld.Sfxs[520].Name := 'fre519';
    FOld.Sfxs[600].Name := 'other';
    FOld.Sfxs[699].Name := 'fre699';
    FOld.Sfxs[700].Name := 'fre700';
    for LIndex := 500 to 700 do
      FTable.Sfx[LIndex] := FOld.Sfxs[LIndex];
  end;
  FOld.Aliases.Add('player/pain=dspldeth');
  FOld.Aliases.Add('ali/ds=DS');
  FOld.Aliases.Add('ali/dsx=dsx');
  FOld.Aliases.Add('ali/zero=0');
  FOld.Aliases.Add('ali/tag=tag4');
  FOld.LumpNames.AddStrings(['DSPAIN0', 'DSPAIN1', 'DSPAIN3', 'DSPAIN7', 'TAIL1', 'TAIL2',
    'DSLONGER1', 'LONGERN3', 'DSSND3', 'DSTAG6']);
  FLog := TSoundTestLog.Create;
  FLogIntf := FLog;
  FResolver := TSfxNumberResolver.Create(FTableIntf,
    function(const AName: string): string
    begin
      Result := FOld.Resolve(AName);
    end, FLogIntf);
end;

procedure TTestAudioSfxNumberResolver.Release;
var
  LLists: TList<TList<Integer>>;
  LList: TList<Integer>;

  procedure Collect(const ASource: array of TSfxRecord);
  var
    LIndex: Integer;
  begin
    for LIndex := 0 to Length(ASource) - 1 do
      if Assigned(ASource[LIndex].RandomList) and
        (LLists.IndexOf(ASource[LIndex].RandomList) < 0) then
        LLists.Add(ASource[LIndex].RandomList);
  end;

begin
  // the lists are shared by the records of a group: free each one once
  LLists := TList<TList<Integer>>.Create;
  try
    Collect(FOld.Sfxs);
    Collect(FTable.Sfx);
    for LList in LLists do
      LList.Free;
  finally
    LLists.Free;
  end;
  FResolver := nil;
  FTableIntf := nil;
  FLogIntf := nil;
  FreeAndNil(FOld);
end;

procedure TTestAudioSfxNumberResolver.TearDown;
begin
  if Assigned(FOld) then
    Release;
end;

procedure TTestAudioSfxNumberResolver.CompareTables(const AContext: string);
var
  LIndex: Integer;
begin
  Assert.AreEqual(FOld.numsfx, FTable.Used, 'count ' + AContext);
  for LIndex := 0 to Length(FTable.Sfx) - 1 do
    Assert.AreEqual(Describe(FOld.Sfxs[LIndex]), Describe(FTable.Sfx[LIndex]),
      Format('slot %d %s', [LIndex, AContext]));
end;

function TTestAudioSfxNumberResolver.CompareCall(const AName: string): Integer;
var
  LActual: Integer;
begin
  FOld.Warnings.Clear;
  FLog.Warnings.Clear;
  Result := FOld.S_GetSoundNumForName(AName);
  LActual := FResolver.NumberForName(AName);
  Assert.AreEqual(Result, LActual, 'result of "' + AName + '"');
  Assert.AreEqual(FOld.Warnings.Text, FLog.Warnings.Text, 'warnings of "' + AName + '"');
  CompareTables('after "' + AName + '"');
end;

procedure TTestAudioSfxNumberResolver.RunNames(AGame: TOldSoundGame; ACapacity, AUsed: Integer;
  const ANames: array of string);
var
  LName: string;
begin
  Build(AGame, ACapacity, AUsed);
  try
    for LName in ANames do
      CompareCall(LName);
  finally
    Release;
  end;
end;

const
  KNOWN_NAMES: array[0..46] of string = ('', '0', '1', '3', '5', '12', '-1', '07', '0x2',
    '#2', '+2', '2147483648', '500', '510', '519', '520', '599', '600', '699', '700', '9999',
    'snd2', 'SND2', 'dssnd3', 'DSSND3', 'newsound', 'NEWSOUND', 'dsnewsnd', 'player/pain',
    'ali/ds', 'ali/dsx', 'ali/zero', 'ali/tag', 'ds', 'DS', 'x', 'tag4', 'TAG4', 'dstag4',
    'longername1', 'abcdefghijkl', 'dsabc', 'newsound', 'snd4', ' 5', 'a/b', 'D');

procedure TTestAudioSfxNumberResolver.DovrebbeDareLeStesseRisposteDiDoomPerNomiENumeri;
begin
  RunNames(osgDoom, 800, 30, KNOWN_NAMES);
end;

procedure TTestAudioSfxNumberResolver.DovrebbeDareLeStesseRisposteDiHereticPerNomiENumeri;
begin
  RunNames(osgHeretic, 800, 30, KNOWN_NAMES);
end;

procedure TTestAudioSfxNumberResolver.DovrebbeDareLeStesseRisposteDiHexenPerNomiENumeri;
begin
  RunNames(osgHexen, 800, 30, KNOWN_NAMES);
end;

procedure TTestAudioSfxNumberResolver.DovrebbeDareLeStesseRisposteDiStrifePerNomiENumeri;
begin
  RunNames(osgStrife, 800, 30, KNOWN_NAMES);
end;

procedure TTestAudioSfxNumberResolver.DovrebbeDareLeStesseRisposteSuNomiCasualiFinoAlLimiteInOgniGioco;
const
  POOL: array[0..19] of string = ('snd1', 'dssnd2', 'a1', 'a2', 'a3', 'a4', 'dsb5', 'b6', 'b7',
    'DS', '', '3', '9', '14', 'tag2', 'player/pain', 'ali/zero', 'x8', 'dsx9', 'snd13');
var
  LGame: TOldSoundGame;
  LScenario: Integer;
  LStep: Integer;
begin
  RandSeed := 2431;
  for LGame := Low(TOldSoundGame) to High(TOldSoundGame) do
    for LScenario := 1 to 30 do
    begin
      // a table that fills up after a few registrations
      Build(LGame, 705 + Random(3), 695 + Random(6));
      try
        for LStep := 1 to 20 do
          CompareCall(POOL[Random(Length(POOL))]);
      finally
        Release;
      end;
    end;
end;

procedure TTestAudioSfxNumberResolver.CompareRandom(ASfxNumber: Integer);
var
  LExpected: TList<Integer>;
  LActual: TList<Integer>;
  LIndex: Integer;
begin
  FOld.Warnings.Clear;
  FLog.Warnings.Clear;
  LExpected := FOld.S_GetRandomSoundList(ASfxNumber);
  LActual := NewRandomList(ASfxNumber);
  Assert.AreEqual(Assigned(LExpected), Assigned(LActual), 'list of ' + IntToStr(ASfxNumber));
  if Assigned(LExpected) then
  begin
    Assert.AreEqual(LExpected.Count, LActual.Count, 'members of ' + IntToStr(ASfxNumber));
    for LIndex := 0 to LExpected.Count - 1 do
      Assert.AreEqual(LExpected[LIndex], LActual[LIndex], 'member');
  end;
  Assert.AreEqual(FOld.Warnings.Text, FLog.Warnings.Text);
  CompareTables('after the list of ' + IntToStr(ASfxNumber));
end;

function TTestAudioSfxNumberResolver.NewRandomList(ASfxNumber: Integer): TList<Integer>;
var
  LName: string;
  LNumber: Integer;
  LMembers: TArray<TSfxRandomMember>;
  LIndex: Integer;
begin
  LName := FResolver.NameForNumber(ASfxNumber);
  if LName = '' then
  begin
    Result := nil;
    Exit;
  end;
  if FTable.Sfx[ASfxNumber].RandomList = nil then
    FTable.Sfx[ASfxNumber].RandomList := TList<Integer>.Create;
  Result := FTable.Sfx[ASfxNumber].RandomList;
  if Result.Count > 0 then
    Exit;
  if not TSfxRandomGroup.IsGroupName(LName) then
  begin
    Result.Add(ASfxNumber);
    Exit;
  end;
  LMembers := TSfxRandomGroup.Members(LName,
    function(const AName: string): Integer
    begin
      Result := FOld.W_CheckNumForName(AName);
    end);
  for LIndex := 0 to Length(LMembers) - 1 do
  begin
    LNumber := FResolver.NumberForName(LMembers[LIndex].Name);
    Result.Add(LNumber);
    FTable.Sfx[LNumber].LumpNum := LMembers[LIndex].LumpNumber;
    if FTable.Sfx[LNumber].RandomList = nil then
      FTable.Sfx[LNumber].RandomList := Result;
  end;
end;

procedure TTestAudioSfxNumberResolver.DovrebbeDareLeStesseListeCasualiDiUnGruppoDiSuoni;
const
  NAMES: array[0..9] of string = ('pain3', 'dspain0', 'tail2', 'longername1', 'dslonger1',
    'snd3', 'newname', 'abc5', 'DSSND3', 'dspain7');
var
  LGame: TOldSoundGame;
  LScenario: Integer;
  LStep: Integer;
  LNumber: Integer;
begin
  RandSeed := 2432;
  for LGame := Low(TOldSoundGame) to High(TOldSoundGame) do
    for LScenario := 1 to 12 do
    begin
      Build(LGame, 800, 30);
      try
        for LStep := 1 to 8 do
        begin
          // the same name on both sides first, then the list of the sound that came out
          LNumber := CompareCall(NAMES[Random(Length(NAMES))]);
          CompareRandom(LNumber);
          CompareRandom(Random(FOld.numsfx + 2) - 1);
        end;
      finally
        Release;
      end;
    end;
end;

procedure TTestAudioSfxNumberResolver.DovrebbeUsareLoSlotDelDehExtraSoloSeHaIlNomeAtteso;
begin
  Build(osgDoom, 800, 30);
  Assert.AreEqual(510, FResolver.NumberForName('510'));
  Assert.AreEqual(511, FTable.Used);
  Assert.AreEqual(-1, FTable.Sfx[510].LumpNum);
  Assert.AreEqual(72, FTable.Sfx[510].Priority);
  // 520 has another number in its name and 600 another name: both are searched as names
  // (and take the empty slots 5 and 12), and 700 is outside the range of DEHEXTRA
  Assert.AreEqual(5, FResolver.NumberForName('520'));
  Assert.AreEqual(12, FResolver.NumberForName('600'));
  Assert.AreEqual(19, FResolver.NumberForName('700'));
end;

procedure TTestAudioSfxNumberResolver.DovrebbeRiusareGliSlotVuotiDiDoomSenzaTornareIndietro;
begin
  Build(osgDoom, 800, 30);
  // the slots 5, 12, 19 and 26 of the table of the test have no name
  Assert.AreEqual(5, FResolver.NumberForName('one'));
  Assert.AreEqual(12, FResolver.NumberForName('two'));
  Assert.AreEqual('ONE', FTable.Sfx[5].Name);
  Assert.AreEqual(30, FTable.Used);
  // a later name takes the next empty slot, never one before
  FTable.Sfx[7].Name := '';
  Assert.AreEqual(19, FResolver.NumberForName('three'));
end;

procedure TTestAudioSfxNumberResolver.DovrebbeDareIlSuonoDiDefaultSeIlNomeEVuoto;
begin
  Build(osgHexen, 800, 30);
  Assert.AreEqual(3, FResolver.NumberForName(''));
  Assert.AreEqual('S_GetSoundNumForName(): No sound name specified, using default'#13#10,
    FLog.Warnings[0]);
end;

procedure TTestAudioSfxNumberResolver.DovrebbeTenereIlNomeGrezzoComeTagDiHexen;
begin
  Build(osgHexen, 800, 30);
  Assert.AreEqual(30, FResolver.NumberForName('Foo/Bar'));
  Assert.AreEqual('Foo/Bar', FTable.Sfx[30].TagName);
  Assert.AreEqual('FOO/BAR', FTable.Sfx[30].Name);
  Assert.AreEqual(1, FTable.Sfx[30].NumChannels);
end;

procedure TTestAudioSfxNumberResolver.DovrebbeTogliereIlPrefissoDsSoloQuandoAggiungeUnSuono;
begin
  Build(osgHeretic, 800, 30);
  Assert.AreEqual(30, FResolver.NumberForName('dsfoo'));
  Assert.AreEqual('FOO', FTable.Sfx[30].Name);
  Assert.AreEqual(30, FResolver.NumberForName('foo'));
  Assert.AreEqual(30, FResolver.NumberForName('dsfoo'));
end;

procedure TTestAudioSfxNumberResolver.DovrebbeDareIlNomeInMaiuscoloODiVuotoFuoriDallaTabella;
begin
  Build(osgDoom, 800, 30);
  Assert.AreEqual('SND2', FResolver.NameForNumber(2));
  Assert.AreEqual('', FResolver.NameForNumber(-1));
  Assert.AreEqual('', FResolver.NameForNumber(30));
end;

procedure TTestAudioSfxNumberResolver.DovrebbeTrovareIlGruppoConLeCifreMancanti;
var
  LMembers: TArray<TSfxRandomMember>;
begin
  LMembers := TSfxRandomGroup.Members('DSPAIN3',
    function(const AName: string): Integer
    begin
      if (AName = 'DSPAIN0') or (AName = 'DSPAIN3') then
        Result := 10 + Ord(AName[7]) - Ord('0')
      else if AName = 'PAIN7' then
        Result := 77
      else
        Result := -1;
    end);
  Assert.AreEqual<Integer>(3, Length(LMembers));
  Assert.AreEqual('DSPAIN0', LMembers[0].Name);
  Assert.AreEqual(10, LMembers[0].LumpNumber);
  Assert.AreEqual('DSPAIN3', LMembers[1].Name);
  Assert.AreEqual('PAIN7', LMembers[2].Name);
  Assert.AreEqual(77, LMembers[2].LumpNumber);
end;

procedure TTestAudioSfxNumberResolver.DovrebbeTroncareAOttoCaratteriINomiDelGruppo;
var
  LAsked: TStringList;
  LMembers: TArray<TSfxRandomMember>;
begin
  LAsked := TStringList.Create;
  try
    LMembers := TSfxRandomGroup.Members('LONGERNAME5',
      function(const AName: string): Integer
      begin
        LAsked.Add(AName);
        Result := -1;
      end);
    Assert.AreEqual<Integer>(0, Length(LMembers));
    // 'DS' + the name cut to 8 loses the characters after 'DSLONGER'
    Assert.AreEqual('DSLONGE0', LAsked[0]);
    Assert.AreEqual('LONGERN0', LAsked[1]);
  finally
    LAsked.Free;
  end;
end;

procedure TTestAudioSfxNumberResolver.DovrebbeLanciareSeMancaUnaDipendenza;
var
  LNoTable: ISfxTable;
  LNoAliases: TSoundNameResolver;
begin
  Build(osgDoom, 800, 5);
  LNoTable := nil;
  LNoAliases := nil;
  Assert.WillRaise(
    procedure
    begin
      TSfxNumberResolver.Create(LNoTable,
        function(const AName: string): string
        begin
          Result := AName;
        end, FLogIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TSfxNumberResolver.Create(FTableIntf, LNoAliases, FLogIntf);
    end, EArgumentNilException);
end;

end.
