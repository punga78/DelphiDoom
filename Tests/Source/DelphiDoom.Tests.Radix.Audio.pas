{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the radix library - the sounds that the game asks for  }
{  and the music of the levels                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.Audio;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GameData.Intf;

type
  /// <summary>
  ///   The names of the sounds that the actors of Radix ask for (IdTech1\Radix\Data\RADIXDEF.txt) against
  ///   the table of the sounds of RADIX.DAT, and, on the real RADIX.DAT 2.0 shareware (skipped when
  ///   the file is not there), the sounds and the music that the translated WAD gives to the engine
  /// </summary>
  [TestFixture]
  [Category('radix')]
  TTestRadixAudio = class(TObject)
  strict private
    function ActorSoundNames: TArray<string>;
    function FindData: string;
    function TranslatedWad: IGameWadComposer;
    function IsKnownSound(const AName: string): Boolean;
  public
    [Test]
    procedure OgniSuonoDegliAttoriDovrebbeEssereNellaTabellaDeiSuoni;
    [Test]
    procedure ISuoniDellaNavettaDovrebberoEssereNellaTabellaDeiSuoni;
    [Test]
    procedure OgniSuonoDegliAttoriDovrebbeAvereIlSuoLumpNelloShareware;
    [Test]
    procedure IlSndInfoDovrebbeNominareOgniSuonoTradotto;
    [Test]
    procedure LaMusicaDelTitoloEDiOgniLivelloDovrebbeEssereUnModuloCheIlTrackerCarica;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  DelphiDoom.Radix.Types,
  DelphiDoom.Radix.Intf,
  DelphiDoom.Radix.Factory,
  DelphiDoom.Radix.SoundPart,
  DelphiDoom.Tracker.Types,
  DelphiDoom.Tracker.Loader.ProTracker;

const
  SOUND_PREFIX = 'radix/';
  SHAREWARE_LEVELS = 9;

function TTestRadixAudio.ActorSoundNames: TArray<string>;
var
  LText: string;
  LList: TList<string>;
  LPosition: Integer;
  LEnd: Integer;
  LName: string;
begin
  LText := TFile.ReadAllText(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\IdTech1\Radix\Data\RADIXDEF.txt')));
  LList := TList<string>.Create;
  try
    LPosition := Pos(SOUND_PREFIX, LowerCase(LText));
    while LPosition > 0 do
    begin
      LEnd := LPosition + Length(SOUND_PREFIX);
      while (LEnd <= Length(LText)) and CharInSet(LText[LEnd], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
        Inc(LEnd);
      LName := Copy(LText, LPosition + Length(SOUND_PREFIX), LEnd - LPosition - Length(SOUND_PREFIX));
      if (LName <> '') and not LList.Contains(LName) then
        LList.Add(LName);
      LPosition := Pos(SOUND_PREFIX, LowerCase(LText), LEnd);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TTestRadixAudio.FindData: string;
var
  LRoot: string;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  for LCandidate in TArray<string>.Create(
    TPath.Combine(LRoot, 'bin\Radix\RADIX.DAT'),
    TPath.Combine(LRoot, 'Reference\_dati\radix\v20\game\RADIX.DAT'),
    // the worktrees of the repository are under .claude\worktrees\<name>
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\Reference\_dati\radix\v20\game\RADIX.DAT'))) do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

function TTestRadixAudio.TranslatedWad: IGameWadComposer;
var
  LPath: string;
begin
  LPath := FindData;
  if LPath = '' then
    Assert.Pass('RADIX.DAT is not there');
  Result := TRadixFactory.CreateTranslator(TRadixLumpNames.Doom).Translate(TRadixFactory.OpenContainer(LPath));
end;

function TTestRadixAudio.IsKnownSound(const AName: string): Boolean;
var
  LKnown: string;
begin
  for LKnown in TRadixSoundPart.SoundNames do
    if SameText(LKnown, AName) then
      Exit(True);
  Result := False;
end;

procedure TTestRadixAudio.OgniSuonoDegliAttoriDovrebbeEssereNellaTabellaDeiSuoni;
var
  LNames: TArray<string>;
  LName: string;
begin
  LNames := ActorSoundNames;
  Assert.IsTrue(Length(LNames) >= 10, 'the actors ask for their sounds by name');
  for LName in LNames do
    Assert.IsTrue(IsKnownSound(LName), 'the sound ' + LName + ' of the actors is not a sound of RADIX.DAT');
end;

procedure TTestRadixAudio.ISuoniDellaNavettaDovrebberoEssereNellaTabellaDeiSuoni;
var
  LName: string;
begin
  // radix_pilotsound, radix_walls, radix_weapons, radix_teleport ask for these by name
  for LName in TArray<string>.Create('SndEngine', 'SndEngineAfter', 'SndSiren', 'SndPlaneHit', 'SndExplode',
    'SndPlasmaBomb', 'SndTelePort') do
    Assert.IsTrue(IsKnownSound(LName), LName);
end;

procedure TTestRadixAudio.OgniSuonoDegliAttoriDovrebbeAvereIlSuoLumpNelloShareware;
var
  LWad: IGameWadComposer;
  LSounds: TArray<string>;
  LName: string;
  LIndex: Integer;
  LLump: Integer;
begin
  LWad := TranslatedWad;
  LSounds := TRadixSoundPart.SoundNames;
  for LName in ActorSoundNames do
    for LIndex := 0 to High(LSounds) do
      if SameText(LSounds[LIndex], LName) then
      begin
        LLump := LWad.IndexOf(Format('DS_%.5d', [LIndex]));
        Assert.IsTrue(LLump >= 0, 'RADIX.DAT has no sound ' + LName);
        Assert.IsTrue(Length(LWad.LumpData[LLump]) > 0, 'the sound ' + LName + ' is empty');
      end;
end;

procedure TTestRadixAudio.IlSndInfoDovrebbeNominareOgniSuonoTradotto;
var
  LWad: IGameWadComposer;
  LSounds: TArray<string>;
  LInfo: string;
  LIndex: Integer;
  LLumpName: string;
  LTranslated: Integer;
begin
  LWad := TranslatedWad;
  LIndex := LWad.IndexOf('SNDINFO');
  Assert.IsTrue(LIndex >= 0, 'SNDINFO');
  LInfo := TEncoding.ANSI.GetString(LWad.LumpData[LIndex]);
  LSounds := TRadixSoundPart.SoundNames;
  LTranslated := 0;
  for LIndex := 0 to High(LSounds) do
  begin
    LLumpName := Format('DS_%.5d', [LIndex]);
    if LWad.IndexOf(LLumpName) >= 0 then
    begin
      Inc(LTranslated);
      Assert.IsTrue(LInfo.Contains(SOUND_PREFIX + LSounds[LIndex] + ' ' + LLumpName),
        'SNDINFO names ' + LSounds[LIndex]);
    end;
  end;
  Assert.AreEqual(Integer(Length(LSounds)), LTranslated, 'the 2.0 shareware has every sound of the table');
end;

procedure TTestRadixAudio.LaMusicaDelTitoloEDiOgniLivelloDovrebbeEssereUnModuloCheIlTrackerCarica;
var
  LWad: IGameWadComposer;
  LNames: TArray<string>;
  LName: string;
  LMap: Integer;
  LLump: Integer;
  LData: TBytes;
  LModule: TTrackerModule;
begin
  LWad := TranslatedWad;
  LNames := ['D_INTRO'];
  for LMap := 1 to SHAREWARE_LEVELS do
    LNames := LNames + [Format('D_E1M%d', [LMap])];
  for LName in LNames do
  begin
    LLump := LWad.IndexOf(LName);
    Assert.IsTrue(LLump >= 0, 'the music ' + LName + ' is in the translated WAD');
    LData := LWad.LumpData[LLump];
    Assert.IsTrue(TTrackerModLoader.Detect(LData), LName + ' is a ProTracker module');
    LModule := TTrackerModLoader.Load(LData);
    try
      Assert.IsTrue(LModule.Channels >= 4, LName + ' has its channels');
      Assert.IsTrue(LModule.Patterns.Count > 0, LName + ' has its patterns');
    finally
      LModule.Free;
    end;
  end;
end;

end.
