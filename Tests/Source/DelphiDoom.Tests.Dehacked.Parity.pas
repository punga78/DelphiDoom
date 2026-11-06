{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Dehacked library - parity with the old parser      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Dehacked.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Generics.Collections,
  DUnitX.TestFramework, DelphiDoom.Dehacked.Games;

type
  /// <summary>
  ///   The files *.golden.txt in Tests\Data\Dehacked were made by the old DEH_Parse of Doom, running in
  ///   the engine on the patches *.deh of the same folder: the warnings it gave and the lines of the
  ///   dump of DEH_CurrentSettings that the patch changed. The library has to give the same warnings (the
  ///   ones that the library can give: the ones that need the tables of the engine are for the
  ///   engine) and TDumpApplier, which stands for the engine, has to explain the same changes
  /// </summary>
  [TestFixture]
  [Category('dehacked')]
  TTestDehackedParity = class(TObject)
  private
    function DataPath(const AFileName: string): string;
    procedure Check(AGame: TDehackedGame; const ASample: string);
    function IsEngineWarning(const ALine: string): Boolean;
    function Lines(const AText: string): TArray<string>;
  public
    [Test]
    [TestCase('header_comments', 'header_comments')]
    [TestCase('thing_numeric', 'thing_numeric')]
    [TestCase('thing_fixed', 'thing_fixed')]
    [TestCase('thing_flags', 'thing_flags')]
    [TestCase('thing_states', 'thing_states')]
    [TestCase('thing_misc', 'thing_misc')]
    [TestCase('frame_basic', 'frame_basic')]
    [TestCase('frame_new', 'frame_new')]
    [TestCase('weapon_ammo_misc', 'weapon_ammo_misc')]
    [TestCase('bex_sections', 'bex_sections')]
    [TestCase('text_pointer_codeptr', 'text_pointer_codeptr')]
    procedure TestSameChangesAndWarningsAsTheOldParser(const ASample: string);

    /// <summary>The same patches for the other games: the things, the frames, Misc and Ammo, which have the same dump</summary>
    [Test]
    [TestCase('Heretic_header_comments', 'Heretic,header_comments')]
    [TestCase('Heretic_thing_numeric', 'Heretic,thing_numeric')]
    [TestCase('Heretic_thing_fixed', 'Heretic,thing_fixed')]
    [TestCase('Heretic_thing_flags', 'Heretic,thing_flags')]
    [TestCase('Heretic_thing_states', 'Heretic,thing_states')]
    [TestCase('Heretic_thing_misc', 'Heretic,thing_misc')]
    [TestCase('Heretic_frame_basic', 'Heretic,frame_basic')]
    [TestCase('Heretic_frame_new', 'Heretic,frame_new')]
    [TestCase('Heretic_weapon_ammo_misc', 'Heretic,weapon_ammo_misc')]
    [TestCase('Heretic_bex_sections', 'Heretic,bex_sections')]
    [TestCase('Heretic_text_pointer_codeptr', 'Heretic,text_pointer_codeptr')]
    [TestCase('Hexen_header_comments', 'Hexen,header_comments')]
    [TestCase('Hexen_thing_numeric', 'Hexen,thing_numeric')]
    [TestCase('Hexen_thing_fixed', 'Hexen,thing_fixed')]
    [TestCase('Hexen_thing_flags', 'Hexen,thing_flags')]
    [TestCase('Hexen_thing_states', 'Hexen,thing_states')]
    [TestCase('Hexen_thing_misc', 'Hexen,thing_misc')]
    [TestCase('Hexen_frame_basic', 'Hexen,frame_basic')]
    [TestCase('Hexen_frame_new', 'Hexen,frame_new')]
    [TestCase('Hexen_weapon_ammo_misc', 'Hexen,weapon_ammo_misc')]
    [TestCase('Hexen_bex_sections', 'Hexen,bex_sections')]
    [TestCase('Hexen_text_pointer_codeptr', 'Hexen,text_pointer_codeptr')]
    [TestCase('Strife_header_comments', 'Strife,header_comments')]
    [TestCase('Strife_thing_numeric', 'Strife,thing_numeric')]
    [TestCase('Strife_thing_fixed', 'Strife,thing_fixed')]
    [TestCase('Strife_thing_flags', 'Strife,thing_flags')]
    [TestCase('Strife_thing_states', 'Strife,thing_states')]
    [TestCase('Strife_thing_misc', 'Strife,thing_misc')]
    [TestCase('Strife_frame_basic', 'Strife,frame_basic')]
    [TestCase('Strife_frame_new', 'Strife,frame_new')]
    [TestCase('Strife_weapon_ammo_misc', 'Strife,weapon_ammo_misc')]
    [TestCase('Strife_bex_sections', 'Strife,bex_sections')]
    [TestCase('Strife_text_pointer_codeptr', 'Strife,text_pointer_codeptr')]
    procedure TestSameChangesAndWarningsAsTheOldParserOtherGames(const AGame, ASample: string);
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder,
  DelphiDoom.Logging.Factory, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.Factory, DelphiDoom.Dehacked.GameData, DelphiDoom.Dehacked.Types,
  DelphiDoom.Dehacked.Data.Doom, DelphiDoom.Dehacked.Data.Heretic, DelphiDoom.Dehacked.Data.Hexen,
  DelphiDoom.Dehacked.Data.Strife, DelphiDoom.Tests.Dehacked.DumpApplier;

{ TTestDehackedParity }

function FolderOf(AGame: TDehackedGame): string;
begin
  if AGame = dgDoom then
    Result := ''
  else
    Result := TDehackedGames.NameOf(AGame).Substring(0, 1) + LowerCase(TDehackedGames.NameOf(AGame)).Substring(1) + '\';
end;

function DataOf(AGame: TDehackedGame): TDehackedGameData;
begin
  case AGame of
    dgDoom: Result := TDehackedDoomData.Build;
    dgHeretic: Result := TDehackedHereticData.Build;
    dgHexen: Result := TDehackedHexenData.Build;
  else
    Result := TDehackedStrifeData.Build;
  end;
end;

function KindsOf(AGame: TDehackedGame): TDehackedSectionKinds;
begin
  if AGame = dgDoom then
    Result := [Low(TDehackedSectionKind)..High(TDehackedSectionKind)]
  else
    Result := [dskThing, dskFrame, dskMisc, dskAmmo, dskSubmitNewStates];
end;

function TTestDehackedParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Dehacked\' + AFileName));
end;

function TTestDehackedParity.Lines(const AText: string): TArray<string>;
var
  LList: TStringList;
  LIndex: Integer;
  LItems: TList<string>;
begin
  LList := TStringList.Create;
  LItems := TList<string>.Create;
  try
    LList.Text := AText;
    for LIndex := 0 to LList.Count - 1 do
      if LList[LIndex] <> '' then
        LItems.Add(LList[LIndex]);
    Result := LItems.ToArray;
  finally
    LItems.Free;
    LList.Free;
  end;
end;

// what the engine says about a patch because it has the tables: the numbers of things and states that
// are out of the tables, the names that do not exist, the strings that are not found
function TTestDehackedParity.IsEngineWarning(const ALine: string): Boolean;
const
  PATTERNS: array[0..10] of string = (
    'Wrong think number', 'Wrong state number', 'Can not find setable text',
    'Unknown action function', 'Wrong action number', 'Invalid state number',
    'Can not find sprite', 'Wrong sound number', 'New sounds can only', 'Wrong weapon number',
    'Sprite name with');
var
  LPattern: string;
begin
  // a message with a line break goes on in the next line: that line is part of the one before
  if Copy(ALine, 1, 11) <> 'I_Warning: ' then
    Exit(True);
  for LPattern in PATTERNS do
    if Pos(LPattern, ALine) > 0 then
      Exit(True);
  Result := False;
end;

procedure TTestDehackedParity.TestSameChangesAndWarningsAsTheOldParser(const ASample: string);
begin
  Check(dgDoom, ASample);
end;

procedure TTestDehackedParity.TestSameChangesAndWarningsAsTheOldParserOtherGames(const AGame,
  ASample: string);
var
  LGame: TDehackedGame;
begin
  Assert.IsTrue(TDehackedGames.TryFromName(AGame, LGame));
  Check(LGame, ASample);
end;

procedure TTestDehackedParity.Check(AGame: TDehackedGame; const ASample: string);
var
  LGolden: TStringList;
  LSection, LLine, LKey, LValue, LHeader: string;
  LBase, LPos: Integer;
  LGoldenWarnings, LGoldenChanges: TList<string>;
  LOld: TDictionary<string, string>;
  LRecorder: TLogRecorder;
  LSink: ILogSink;
  LParser: IDehackedParser;
  LPatch: IDehackedPatch;
  LApplier: TDumpApplier;
  LChanges: TDictionary<string, string>;
  LMine, LTheirs: TArray<string>;
  LWarning: string;
  LPair: TPair<string, string>;
  LText: string;
  LGoldenMap: TDictionary<string, string>;

  function Ignored(const AKey: string): Boolean;
  begin
    Result := Pos('|Codep Frame', AKey) > 0;
    // the other games have other dumps of weapons, strings, music and sounds: the headers that are
    // the same in all of them are compared
    if (AGame <> dgDoom) and not (StartsStr('Thing ', AKey) or StartsStr('Frame ', AKey) or
      StartsStr('Misc|', AKey) or StartsStr('Ammo ', AKey)) then
      Result := True;
  end;

  function Soft(const AKey: string): Boolean;
  begin
    Result := LApplier.SoftHeaders.Contains(Copy(AKey, 1, Pos('|', AKey) - 1));
  end;

begin
  LGolden := TStringList.Create;
  LGoldenWarnings := TList<string>.Create;
  LGoldenChanges := TList<string>.Create;
  LGoldenMap := TDictionary<string, string>.Create;
  LOld := TDictionary<string, string>.Create;
  LRecorder := TLogRecorder.Create;
  LSink := LRecorder;
  LBase := 0;
  try
    LGolden.LoadFromFile(DataPath(FolderOf(AGame) + ASample + '.golden.txt'));
    LSection := '';
    for LLine in LGolden do
    begin
      if (LLine <> '') and (LLine[1] = '[') and (Pos('|', LLine) = 0) and
        (MatchStr(LLine, ['[numstates]', '[warnings]', '[changes]', '[old]'])) then
      begin
        LSection := LLine;
        Continue;
      end;
      if LSection = '[numstates]' then
        LBase := StrToInt(LLine)
      else if LSection = '[warnings]' then
      begin
        if LLine <> '' then
          LGoldenWarnings.Add(LLine);
      end
      else if LSection = '[changes]' then
      begin
        LPos := Pos('=', LLine);
        LGoldenChanges.Add(LLine);
        LGoldenMap.AddOrSetValue(Copy(LLine, 1, LPos - 1), Copy(LLine, LPos + 1, MaxInt));
      end
      else if LSection = '[old]' then
      begin
        LPos := Pos('=', LLine);
        LKey := Copy(LLine, 1, LPos - 1);
        LValue := Copy(LLine, LPos + 1, MaxInt);
        LOld.AddOrSetValue(Copy(LKey, Pos('|', LKey) + 1, MaxInt), LValue);
      end;
    end;

    LParser := TDehackedFactory.CreateParser(AGame,
      TLogFactory.CreateLog(TArray<ILogSink>.Create(LSink), nil));
    LPatch := LParser.Parse(TFile.ReadAllText(DataPath(ASample + '.deh'), TEncoding.ANSI));

    // the warnings: every one of the library is in the old ones, and the old ones that do not
    // need the engine are all in the library
    LMine := Lines(LRecorder.TextOf(TLogChannel.Output));
    LTheirs := LGoldenWarnings.ToArray;
    for LWarning in LMine do
      Assert.IsTrue(MatchStr(LWarning, LTheirs), 'warning that the old parser did not give: ' + LWarning);
    for LWarning in LTheirs do
      if not IsEngineWarning(LWarning) then
        Assert.IsTrue(MatchStr(LWarning, LMine), 'warning that the library does not give: ' + LWarning);

    // the changes
    LApplier := TDumpApplier.Create(DataOf(AGame), LBase, LOld, KindsOf(AGame));
    try
      LApplier.Apply(LPatch);
      LChanges := LApplier.Changes;
      for LLine in LGoldenChanges do
      begin
        LPos := Pos('=', LLine);
        LKey := Copy(LLine, 1, LPos - 1);
        LValue := Copy(LLine, LPos + 1, MaxInt);
        if Ignored(LKey) then
          Continue;
        // the dump of the engine changes this field of every thing, with or without a patch
        if (Copy(LKey, Length(LKey) - 13, 14) = '|Weave Index Z') and (LValue = '0') and
          not LChanges.ContainsKey(LKey) then
          Continue;
        if LChanges.TryGetValue(LKey, LText) then
          Assert.AreEqual(LValue, LText, 'value of ' + LKey)
        else
          Assert.IsTrue(Soft(LKey), 'change that the library does not explain: ' + LLine);
      end;
      for LPair in LChanges do
      begin
        if Ignored(LPair.Key) then
          Continue;
        if not LGoldenMap.ContainsKey(LPair.Key) then
          Assert.IsTrue(Soft(LPair.Key),
            'change that the old parser did not make: ' + LPair.Key + '=' + LPair.Value);
      end;
    finally
      LApplier.Free;
    end;
  finally
    LOld.Free;
    LSink := nil;
    LRecorder := nil;
    LGoldenMap.Free;
    LGoldenChanges.Free;
    LGoldenWarnings.Free;
    LGolden.Free;
  end;
end;

end.
