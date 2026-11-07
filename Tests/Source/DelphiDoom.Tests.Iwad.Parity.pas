{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - parity with the old code             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.Parity;

interface

uses
  System.SysUtils, System.StrUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Iwad.Types,
  DelphiDoom.Iwad.Intf, DelphiDoom.Iwad.Games, DelphiDoom.Iwad.Factory, DelphiDoom.Tests.Iwad.Fakes;

type
  /// <summary>
  ///   Tests\Data\Iwad\iwad_golden.txt was written by a harness that ran the old
  ///   D_FileInDoomPath and IdentifyVersion of the four games (copied verbatim from the
  ///   d_main.pas files) on real files, variables and arguments. Each line is a scenario
  ///   (game, options, additional paths, variables, Steam, files, arguments) and what the old code
  ///   did after '=>'; the library must do the same on a fake disk. The BFG edition of Doom
  ///   (doombfg.wad) is not in the scenarios: the old code added doomu.wad for it (a defect,
  ///   tested apart in TTestIwadIdentifier)
  /// </summary>
  [TestFixture]
  [Category('iwad')]
  TTestIwadParity = class(TObject)
  strict private
    const
      FAKE_ROOT = 'R:\iwad';
    function DataPath: string;
    function Expand(const AText: string): string;
    function Normalize(const AText: string): string;
    function Run(const AFields: TArray<string>): string;
    procedure CheckGame(const AGameName: string);
  public
    [Test]
    procedure DovrebbeFareCioCheFacevaIlVecchioCodiceInDoom;
    [Test]
    procedure DovrebbeFareCioCheFacevaIlVecchioCodiceInHeretic;
    [Test]
    procedure DovrebbeFareCioCheFacevaIlVecchioCodiceInHexen;
    [Test]
    procedure DovrebbeFareCioCheFacevaIlVecchioCodiceInStrife;
  end;

implementation

const
  FIELD_GAME = 0;
  FIELD_OPTIONS = 1;
  FIELD_ADDITIONAL = 2;
  FIELD_ENVIRONMENT = 3;
  FIELD_STEAM = 4;
  FIELD_FILES = 5;
  FIELD_ARGUMENTS = 6;
  FIELD_RESULT = 8;

{ TTestIwadParity }

function TTestIwadParity.DataPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Iwad\iwad_golden.txt'));
end;

function TTestIwadParity.Expand(const AText: string): string;
begin
  Result := StringReplace(AText, '<R>', FAKE_ROOT, [rfReplaceAll]);
end;

function TTestIwadParity.Normalize(const AText: string): string;
begin
  Result := StringReplace(AText, FAKE_ROOT, '<R>', [rfReplaceAll, rfIgnoreCase]);
end;

function JoinOrDash(const AItems: TArray<string>): string;
var
  LItem: string;
begin
  Result := '';
  for LItem in AItems do
  begin
    if Result <> '' then
      Result := Result + '|';
    Result := Result + LItem;
  end;
  if Result = '' then
    Result := '-';
end;

function TTestIwadParity.Run(const AFields: TArray<string>): string;
var
  LGame: TIwadGame;
  LEnvironment: TFakeIwadEnvironment;
  LEnvironmentIntf: IIwadEnvironment;
  LFileSystem: TFakeIwadFileSystem;
  LFileSystemIntf: IIwadFileSystem;
  LSteam: TFakeIwadSteam;
  LSteamIntf: IIwadSteam;
  LOptions: TFakeIwadOptions;
  LOptionsIntf: IIwadOptions;
  LServices: TIwadServices;
  LProfile: IIwadProfile;
  LItem, LCustomName: string;
  LArguments: TArray<string>;
  LResult: TIwadIdentification;
  LFiles: TArray<string>;
  LProbes: TArray<string>;
  LFirstName: string;
  LIndex, LPosition: Integer;
  LMode, LMission, LDemo, LRegistered, LVoices: Integer;
begin
  Assert.IsTrue(TIwadGames.TryFromName(AFields[FIELD_GAME], LGame));
  LEnvironment := TFakeIwadEnvironment.Create;
  LEnvironmentIntf := LEnvironment;
  LFileSystem := TFakeIwadFileSystem.Create;
  LFileSystemIntf := LFileSystem;
  LFileSystem.CurrentDirectory := FAKE_ROOT + '\cwd';
  LSteam := TFakeIwadSteam.Create;
  LSteamIntf := LSteam;
  LOptions := TFakeIwadOptions.Create;
  LOptionsIntf := LOptions;

  LOptions.SearchWadDirectory := AFields[FIELD_OPTIONS][1] = '1';
  LOptions.SearchWadPath := AFields[FIELD_OPTIONS][2] = '1';
  LOptions.SearchSteamPaths := AFields[FIELD_OPTIONS][3] = '1';
  if AFields[FIELD_ADDITIONAL] <> '-' then
    LOptions.AdditionalPaths := Expand(AFields[FIELD_ADDITIONAL]);
  if AFields[FIELD_ENVIRONMENT] <> '-' then
    for LItem in AFields[FIELD_ENVIRONMENT].Split(['|']) do
    begin
      LPosition := Pos('=', LItem);
      LEnvironment.SetValue(Copy(LItem, 1, LPosition - 1), Trim(Expand(Copy(LItem, LPosition + 1, MaxInt))));
    end;
  if AFields[FIELD_STEAM] <> '-' then
    for LItem in AFields[FIELD_STEAM].Split(['|']) do
    begin
      LPosition := Pos('=', LItem);
      LSteam.Install(StrToInt(Copy(LItem, 1, LPosition - 1)), Expand(Copy(LItem, LPosition + 1, MaxInt)));
    end;
  if AFields[FIELD_FILES] <> '-' then
    for LItem in AFields[FIELD_FILES].Split([',']) do
      LFileSystem.AddFile(FAKE_ROOT + '\' + LItem);

  // what M_CheckParm and the facade do with the arguments: -mainwad, else -iwad, and a value after it
  SetLength(LArguments, 1);
  LArguments[0] := 'DOOM32.EXE';
  if AFields[FIELD_ARGUMENTS] <> '-' then
    for LItem in AFields[FIELD_ARGUMENTS].Split(['|']) do
    begin
      SetLength(LArguments, Length(LArguments) + 1);
      LArguments[High(LArguments)] := Expand(LItem);
    end;
  LPosition := 0;
  for LIndex := 1 to High(LArguments) do
    if SameText(LArguments[LIndex], '-mainwad') then
    begin
      LPosition := LIndex;
      Break;
    end;
  if LPosition = 0 then
    for LIndex := 1 to High(LArguments) do
      if SameText(LArguments[LIndex], '-iwad') then
      begin
        LPosition := LIndex;
        Break;
      end;
  LCustomName := '';
  if (LPosition > 0) and (LPosition < Length(LArguments) - 1) then
    LCustomName := LArguments[LPosition + 1];

  LProfile := TIwadGames.CreateProfile(LGame);
  LServices.Locator := TIwadFactory.CreateLocator(LProfile, LEnvironmentIntf, LFileSystemIntf,
    LSteamIntf, LOptionsIntf);
  LServices.Identifier := TIwadFactory.CreateIdentifier(LProfile, LServices.Locator,
    LFileSystemIntf, LEnvironmentIntf, LOptionsIntf);

  LFirstName := LProfile.Entries[0].FileName;
  case LGame of
    igHeretic: LFirstName := 'heretic1.wad';
    igHexen: LFirstName := 'hexen1.wad';
    igStrife: LFirstName := 'strife0.wad';
  end;
  LProbes := TArray<string>.Create(
    Normalize(LServices.Locator.Locate(LFirstName)),
    Normalize(LServices.Locator.Locate('custom.wad')),
    Normalize(LServices.Locator.Locate('sub\' + LFirstName)));

  if not LServices.Identifier.TryIdentifyCustom(LCustomName, LResult) then
    LResult := LServices.Identifier.IdentifyKnown;

  LFiles := nil;
  for LItem in LResult.Files do
  begin
    SetLength(LFiles, Length(LFiles) + 1);
    LFiles[High(LFiles)] := Normalize(LItem);
  end;
  if LResult.VoicesPath <> '' then
  begin
    SetLength(LFiles, Length(LFiles) + 1);
    LFiles[High(LFiles)] := Normalize(LResult.VoicesPath);
  end;

  // the numbers of the harness (the enumerations of the old engine plus "not set")
  case LResult.Mode of
    igmShareware: LMode := 1;
    igmRegistered: LMode := 2;
    igmCommercial: LMode := 3;
    igmRetail: LMode := 4;
    igmIndetermined: LMode := 5;
  else
    LMode := 0;
  end;
  case LResult.Mission of
    imsDoom: LMission := 1;
    imsDoom2: LMission := 2;
    imsTnt: LMission := 3;
    imsPlutonia: LMission := 4;
  else
    LMission := 0;
  end;
  // Strife sets these two itself when it takes its own file
  LDemo := 0;
  LRegistered := 0;
  if (LGame = igStrife) and LResult.Found and not LResult.Custom then
  begin
    LDemo := Ord(LResult.Mode = igmShareware);
    LRegistered := Ord(LResult.Mode = igmRegistered);
  end;
  LVoices := Ord(LResult.VoicesPath <> '');
  Result := Format('mode=%d'#9'mission=%d'#9'lang=%d'#9'custom=%d'#9'demo=%d'#9'reg=%d'#9'voices=%d'#9'cw=%s'#9'files=%s'#9'probes=%s',
    [LMode, LMission, Ord(LResult.IsFrench), Ord(LResult.IsBfg2), LDemo, LRegistered, LVoices,
     IfThen(LGame = igStrife, '*', Normalize(LResult.CustomPath)), JoinOrDash(LFiles),
     JoinOrDash(LProbes)]);
end;

procedure TTestIwadParity.CheckGame(const AGameName: string);
var
  LLines: TStringList;
  LLine, LExpected, LActual: string;
  LFields: TArray<string>;
  LCount, LFailures: Integer;
  LFirstFailure: string;
begin
  if not TFile.Exists(DataPath) then
  begin
    Assert.Pass('golden file not found');
    Exit;
  end;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(DataPath);
    LCount := 0;
    LFailures := 0;
    LFirstFailure := '';
    for LLine in LLines do
    begin
      LFields := LLine.Split([#9]);
      if (Length(LFields) < 9) or (LFields[FIELD_GAME] <> AGameName) then
        Continue;
      LExpected := Copy(LLine, Pos(#9'=>'#9, LLine) + 4, MaxInt);
      LActual := Run(LFields);
      Inc(LCount);
      if LActual <> LExpected then
      begin
        Inc(LFailures);
        if LFirstFailure = '' then
          LFirstFailure := LLine + sLineBreak + 'ACTUAL: ' + LActual;
      end;
    end;
    Assert.IsTrue(LCount > 0, 'no scenarios for ' + AGameName);
    Assert.AreEqual(0, LFailures, Format('%d of %d scenarios differ; first: %s',
      [LFailures, LCount, LFirstFailure]));
  finally
    LLines.Free;
  end;
end;

procedure TTestIwadParity.DovrebbeFareCioCheFacevaIlVecchioCodiceInDoom;
begin
  CheckGame('DOOM');
end;

procedure TTestIwadParity.DovrebbeFareCioCheFacevaIlVecchioCodiceInHeretic;
begin
  CheckGame('HERETIC');
end;

procedure TTestIwadParity.DovrebbeFareCioCheFacevaIlVecchioCodiceInHexen;
begin
  CheckGame('HEXEN');
end;

procedure TTestIwadParity.DovrebbeFareCioCheFacevaIlVecchioCodiceInStrife;
begin
  CheckGame('STRIFE');
end;

end.
