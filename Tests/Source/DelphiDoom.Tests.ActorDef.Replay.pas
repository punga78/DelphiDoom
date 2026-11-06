{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ActorDef library - the engine that is replayed     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ActorDef.Replay;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.Intf;

type
  /// <summary>The engine answered something else than what the test expected</summary>
  EReplayMismatch = class(Exception);

  /// <summary>The text of the files of the golden data: one byte per character, the odd ones as %XX</summary>
  TReplayText = class
  public
    class function Encode(const AText: string): string; static;
    class function Decode(const AText: string): string; static;
    /// <summary>The bytes of a file as characters; the line breaks are LF</summary>
    class function ReadAnsi(const AFileName: string): string; static;
    /// <summary>The line breaks become CR LF, as in the lumps</summary>
    class function ToLump(const AText: string): string; static;
    class function ToLf(const AText: string): string; static;
  end;

  /// <summary>
  ///   The old parser ran in an engine (the harness of the tests) that wrote down every question
  ///   that it asked the tables of the engine and the answers (*.engine.txt), and the lists of
  ///   flags of the game (vocab.txt). This class answers the questions of the library with the
  ///   same answers, in the same order, and fails when the library asks something else
  /// </summary>
  TReplayEngine = class(TInterfacedObject, IActorDefFlagCatalog, IActorDefNameCatalog,
    IActorDefActorCatalog, IActorDefStateCatalog)
  private
    type
      TFind = record
        Name: string;
        Index: Integer;
        Actor: TActorDefActor;
      end;
  private
    FVocabulary: array[TActorDefFlagCategory] of TArray<string>;
    FFinds: TList<TFind>;
    FFindPosition: Integer;
    FEvents: TDictionary<string, TList<TArray<string>>>;
    FPositions: TDictionary<string, Integer>;
    procedure LoadVocabulary(const AFileName: string);
    procedure LoadEngine(const AFileName: string);
    procedure ApplyField(var AActor: TActorDefActor; const AKey, AValue: string);
    function Next(const AKind: string): TArray<string>;
    function Query(const AKind, AArgument: string): string;
  public
    constructor Create(const AVocabularyFile, AEngineFile: string);
    destructor Destroy; override;
    /// <summary>What was recorded and the library did not ask; empty if it asked everything</summary>
    function Remaining: string;
    function Flags(ACategory: TActorDefFlagCategory): TArray<string>;
    function WeaponType(const AName: string): Integer;
    function AmmoType(const AName: string): Integer;
    function PlayerClass(const AName: string): Integer;
    function RenderStyleToken(const AName: string): string;
    function GenderName(const AName: string): string;
    function Find(const AName: string; out AIndex: Integer; out AActor: TActorDefActor): Boolean;
    function NameOf(AIndex: Integer): string;
    function AddAlias(const AName, AOtherName: string): Boolean;
    function IndexOfToken(const AToken: string): Integer;
    procedure Add(const AEntry: string);
  end;

  /// <summary>
  ///   Writes in the log what the engine does with the thinkers, the scripts and the patches, in
  ///   the lines of the golden files (@ THINKER ..., @ DEH-BEGIN ...)
  /// </summary>
  TEventRecorder = class(TInterfacedObject, IActorDefThinkerSink, IActorDefScriptSink,
    IActorDefDehConsumer)
  private
    FLog: ILog;
    procedure Event(const AText: string);
    function TypeName(AType: TActorDefScriptType): string;
  public
    constructor Create(const ALog: ILog);
    procedure SubmitThinker(const AThinker: TActorDefThinker);
    procedure AddSourceScript(const AName, ASource: string; AType: TActorDefScriptType);
    procedure AddExternalScript(const AName, AFileName: string; AType: TActorDefScriptType);
    procedure AddCompiledScript(const AName, AFileName: string);
    procedure ParseDehFile(const AFileName: string);
    procedure ParseAllDehFiles(const AFileName: string);
    procedure ParseText(const AText: string);
  end;

implementation

{ TReplayText }

class function TReplayText.Encode(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
    if (Ord(AText[LIndex]) > 32) and (Ord(AText[LIndex]) < 127) and (AText[LIndex] <> '%') and
      (AText[LIndex] <> '|') then
      Result := Result + AText[LIndex]
    else
      Result := Result + '%' + IntToHex(Ord(AText[LIndex]) and $FF, 2);
end;

class function TReplayText.Decode(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] = '%') and (LIndex + 2 <= Length(AText)) then
    begin
      Result := Result + Char(StrToInt('$' + Copy(AText, LIndex + 1, 2)));
      Inc(LIndex, 3);
    end
    else
    begin
      Result := Result + AText[LIndex];
      Inc(LIndex);
    end;
  end;
end;

class function TReplayText.ReadAnsi(const AFileName: string): string;
var
  LBytes: TBytes;
  LAnsi: AnsiString;
begin
  LBytes := TFile.ReadAllBytes(AFileName);
  SetLength(LAnsi, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], LAnsi[1], Length(LBytes));
  Result := ToLf(string(LAnsi));
end;

class function TReplayText.ToLump(const AText: string): string;
begin
  Result := ToLf(AText).Replace(#10, #13#10);
end;

class function TReplayText.ToLf(const AText: string): string;
begin
  Result := AText.Replace(#13#10, #10).Replace(#13, #10);
end;

{ TReplayEngine }

constructor TReplayEngine.Create(const AVocabularyFile, AEngineFile: string);
begin
  inherited Create;
  FFinds := TList<TFind>.Create;
  FEvents := TDictionary<string, TList<TArray<string>>>.Create;
  FPositions := TDictionary<string, Integer>.Create;
  LoadVocabulary(AVocabularyFile);
  LoadEngine(AEngineFile);
end;

destructor TReplayEngine.Destroy;
var
  LList: TList<TArray<string>>;
begin
  for LList in FEvents.Values do
    LList.Free;
  FEvents.Free;
  FPositions.Free;
  FFinds.Free;
  inherited Destroy;
end;

procedure TReplayEngine.LoadVocabulary(const AFileName: string);
var
  LLine: string;
  LCategory: TActorDefFlagCategory;
  LHasCategory: Boolean;
  LName: string;
begin
  LHasCategory := False;
  LCategory := TActorDefFlagCategory.Flags;
  for LLine in TReplayText.ReadAnsi(AFileName).Split([#10]) do
  begin
    if LLine = '' then
      Continue;
    if LLine[1] = '[' then
    begin
      LName := Copy(LLine, 2, Length(LLine) - 2);
      LHasCategory := True;
      if LName = 'flags' then
        LCategory := TActorDefFlagCategory.Flags
      else if LName = 'flags2' then
        LCategory := TActorDefFlagCategory.Flags2
      else if LName = 'flags_ex' then
        LCategory := TActorDefFlagCategory.FlagsEx
      else if LName = 'flags2_ex' then
        LCategory := TActorDefFlagCategory.Flags2Ex
      else if LName = 'flags3_ex' then
        LCategory := TActorDefFlagCategory.Flags3Ex
      else if LName = 'flags4_ex' then
        LCategory := TActorDefFlagCategory.Flags4Ex
      else if LName = 'flags5_ex' then
        LCategory := TActorDefFlagCategory.Flags5Ex
      else if LName = 'flags6_ex' then
        LCategory := TActorDefFlagCategory.Flags6Ex
      else if LName = 'weapon' then
        LCategory := TActorDefFlagCategory.Weapon
      else
        LHasCategory := False;
    end
    else if LHasCategory then
    begin
      SetLength(FVocabulary[LCategory], Length(FVocabulary[LCategory]) + 1);
      FVocabulary[LCategory][High(FVocabulary[LCategory])] := LLine;
    end;
  end;
end;

procedure TReplayEngine.ApplyField(var AActor: TActorDefActor; const AKey, AValue: string);

  function Int: Integer;
  begin
    Result := StrToInt(AValue);
  end;

  function Str: string;
  begin
    Result := TReplayText.Decode(AValue);
  end;

  function Float: Single;
  var
    LBits: Cardinal;
  begin
    LBits := Cardinal(StrToInt64('$' + AValue));
    Move(LBits, Result, SizeOf(Result));
  end;

begin
  if AKey = 'name' then AActor.Name := Str
  else if AKey = 'doomednum' then AActor.DoomedNum := Int
  else if AKey = 'spawnhealth' then AActor.SpawnHealth := Int
  else if AKey = 'seesound' then AActor.SeeSound := Str
  else if AKey = 'reactiontime' then AActor.ReactionTime := Int
  else if AKey = 'attacksound' then AActor.AttackSound := Str
  else if AKey = 'painchance' then AActor.PainChance := Int
  else if AKey = 'painsound' then AActor.PainSound := Str
  else if AKey = 'deathsound' then AActor.DeathSound := Str
  else if AKey = 'speed' then AActor.Speed := Int
  else if AKey = 'radius' then AActor.Radius := Int
  else if AKey = 'height' then AActor.Height := Int
  else if AKey = 'mass' then AActor.Mass := Int
  else if AKey = 'damage' then AActor.Damage := Int
  else if AKey = 'activesound' then AActor.ActiveSound := Str
  else if AKey = 'flags' then AActor.Flags := Str
  else if AKey = 'flags2' then AActor.Flags2 := Str
  else if AKey = 'flags_ex' then AActor.FlagsEx := Str
  else if AKey = 'flags2_ex' then AActor.Flags2Ex := Str
  else if AKey = 'flags3_ex' then AActor.Flags3Ex := Str
  else if AKey = 'flags4_ex' then AActor.Flags4Ex := Str
  else if AKey = 'flags5_ex' then AActor.Flags5Ex := Str
  else if AKey = 'flags6_ex' then AActor.Flags6Ex := Str
  else if AKey = 'customsound1' then AActor.CustomSound1 := Str
  else if AKey = 'customsound2' then AActor.CustomSound2 := Str
  else if AKey = 'customsound3' then AActor.CustomSound3 := Str
  else if AKey = 'dropitem' then AActor.DropItem := Str
  else if AKey = 'missiletype' then AActor.MissileType := Str
  else if AKey = 'explosiondamage' then AActor.ExplosionDamage := Int
  else if AKey = 'explosionradius' then AActor.ExplosionRadius := Int
  else if AKey = 'meleedamage' then AActor.MeleeDamage := Int
  else if AKey = 'meleesound' then AActor.MeleeSound := Str
  else if AKey = 'renderstyle' then AActor.RenderStyle := Str
  else if AKey = 'alpha' then AActor.Alpha := Int
  else if AKey = 'missileheight' then AActor.MissileHeight := Int
  else if AKey = 'meleethreshold' then AActor.MeleeThreshold := Int
  else if AKey = 'vspeed' then AActor.VSpeed := Float
  else if AKey = 'pushfactor' then AActor.PushFactor := Float
  else if AKey = 'scale' then AActor.Scale := Float
  else if AKey = 'gravity' then AActor.Gravity := Float
  else if AKey = 'minmissilechance' then AActor.MinMissileChance := Int
  else if AKey = 'floatspeed' then AActor.FloatSpeed := Int
  else if AKey = 'normalspeed' then AActor.NormalSpeed := Int
  else if AKey = 'fastspeed' then AActor.FastSpeed := Int
  else if AKey = 'obituary' then AActor.Obituary := Str
  else if AKey = 'hitobituary' then AActor.HitObituary := Str
  else if AKey = 'gender' then AActor.Gender := Str
  else if AKey = 'meleerange' then AActor.MeleeRange := Int
  else if AKey = 'maxstepheight' then AActor.MaxStepHeight := Int
  else if AKey = 'maxdropoffheight' then AActor.MaxDropoffHeight := Int
  else if AKey = 'gibhealth' then AActor.GibHealth := Int
  else if AKey = 'maxtargetrange' then AActor.MaxTargetRange := Int
  else if AKey = 'weaveindexxy' then AActor.WeaveIndexXY := Int
  else if AKey = 'weaveindexz' then AActor.WeaveIndexZ := Int
  else if AKey = 'spritedx' then AActor.SpriteDX := Float
  else if AKey = 'spritedy' then AActor.SpriteDY := Float
  else if AKey = 'ripsound' then AActor.RipSound := Str
  else if AKey = 'bloodcolor' then AActor.BloodColor := Str
  else if AKey = 'translation' then AActor.Translation := Str
  else if AKey = 'spawnstate' then AActor.SpawnState := Int
  else if AKey = 'seestate' then AActor.SeeState := Int
  else if AKey = 'painstate' then AActor.PainState := Int
  else if AKey = 'meleestate' then AActor.MeleeState := Int
  else if AKey = 'missilestate' then AActor.MissileState := Int
  else if AKey = 'deathstate' then AActor.DeathState := Int
  else if AKey = 'xdeathstate' then AActor.XDeathState := Int
  else if AKey = 'raisestate' then AActor.RaiseState := Int
  else if AKey = 'healstate' then AActor.HealState := Int
  else if AKey = 'crashstate' then AActor.CrashState := Int
  else if AKey = 'crushstate' then AActor.CrushState := Int
  else if AKey = 'interactstate' then AActor.InteractState := Int
  else if AKey = 'statesdefined' then AActor.StatesDefined := Cardinal(Int)
  else
    raise EReplayMismatch.Create('unknown field ' + AKey);
end;

procedure TReplayEngine.LoadEngine(const AFileName: string);
var
  LLines: TArray<string>;
  LIndex: Integer;
  LLine: string;
  LKind: string;
  LRest: string;
  LPosition: Integer;
  LFind: TFind;
  LList: TList<TArray<string>>;
  LEqual: Integer;
begin
  LLines := TReplayText.ReadAnsi(AFileName).Split([#10]);
  LIndex := 0;
  while LIndex <= High(LLines) do
  begin
    LLine := LLines[LIndex];
    Inc(LIndex);
    if LLine = '' then
      Continue;
    LPosition := Pos(' ', LLine);
    LKind := Copy(LLine, 1, LPosition - 1);
    LRest := Copy(LLine, LPosition + 1, MaxInt);
    if LKind = 'FIND' then
    begin
      LFind := Default(TFind);
      LPosition := Pos('|', LRest);
      LFind.Name := TReplayText.Decode(Copy(LRest, 1, LPosition - 1));
      LFind.Index := StrToInt(Copy(LRest, LPosition + 1, MaxInt));
      if LFind.Index >= 0 then
      begin
        while (LIndex <= High(LLines)) and (LLines[LIndex] <> 'END') do
        begin
          LEqual := Pos('=', LLines[LIndex]);
          ApplyField(LFind.Actor, Trim(Copy(LLines[LIndex], 1, LEqual - 1)),
            Copy(LLines[LIndex], LEqual + 1, MaxInt));
          Inc(LIndex);
        end;
        Inc(LIndex); // END
      end;
      FFinds.Add(LFind);
    end
    else
    begin
      if not FEvents.TryGetValue(LKind, LList) then
      begin
        LList := TList<TArray<string>>.Create;
        FEvents.Add(LKind, LList);
      end;
      LList.Add(LRest.Split(['|']));
    end;
  end;
end;

function TReplayEngine.Next(const AKind: string): TArray<string>;
var
  LList: TList<TArray<string>>;
  LPosition: Integer;
begin
  if not FEvents.TryGetValue(AKind, LList) then
    raise EReplayMismatch.Create('the old engine was not asked ' + AKind);
  if not FPositions.TryGetValue(AKind, LPosition) then
    LPosition := 0;
  if LPosition >= LList.Count then
    raise EReplayMismatch.Create('the old engine was asked ' + AKind + ' fewer times');
  FPositions.AddOrSetValue(AKind, LPosition + 1);
  Result := LList[LPosition];
end;

function TReplayEngine.Query(const AKind, AArgument: string): string;
var
  LEntry: TArray<string>;
begin
  LEntry := Next(AKind);
  if TReplayText.Decode(LEntry[0]) <> AArgument then
    raise EReplayMismatch.Create(AKind + ' expected for "' + TReplayText.Decode(LEntry[0]) +
      '" but asked for "' + AArgument + '"');
  Result := LEntry[1];
end;

function TReplayEngine.Remaining: string;
var
  LKind: string;
  LPosition: Integer;
begin
  Result := '';
  if FFindPosition < FFinds.Count then
    Result := Result + 'FIND x' + IntToStr(FFinds.Count - FFindPosition) + ' ';
  for LKind in FEvents.Keys do
  begin
    if not FPositions.TryGetValue(LKind, LPosition) then
      LPosition := 0;
    if LPosition < FEvents[LKind].Count then
      Result := Result + LKind + ' x' + IntToStr(FEvents[LKind].Count - LPosition) + ' ';
  end;
end;

function TReplayEngine.Flags(ACategory: TActorDefFlagCategory): TArray<string>;
begin
  Result := FVocabulary[ACategory];
end;

function TReplayEngine.WeaponType(const AName: string): Integer;
begin
  Result := StrToInt(Query('WEAPONTYPE', AName));
end;

function TReplayEngine.AmmoType(const AName: string): Integer;
begin
  Result := StrToInt(Query('AMMOTYPE', AName));
end;

function TReplayEngine.PlayerClass(const AName: string): Integer;
begin
  Result := StrToInt(Query('PLAYERCLASS', AName));
end;

function TReplayEngine.RenderStyleToken(const AName: string): string;
begin
  Result := TReplayText.Decode(Query('RENDERSTYLE', AName));
end;

function TReplayEngine.GenderName(const AName: string): string;
begin
  Result := TReplayText.Decode(Query('GENDER', AName));
end;

function TReplayEngine.Find(const AName: string; out AIndex: Integer; out AActor: TActorDefActor): Boolean;
var
  LFind: TFind;
begin
  if FFindPosition >= FFinds.Count then
    raise EReplayMismatch.Create('the old engine was asked FIND fewer times (' + AName + ')');
  LFind := FFinds[FFindPosition];
  Inc(FFindPosition);
  if LFind.Name <> AName then
    raise EReplayMismatch.Create('FIND expected for "' + LFind.Name + '" but asked for "' + AName + '"');
  AIndex := LFind.Index;
  AActor := LFind.Actor;
  Result := LFind.Index >= 0;
end;

function TReplayEngine.NameOf(AIndex: Integer): string;
var
  LEntry: TArray<string>;
begin
  LEntry := Next('MOBJNAME');
  if StrToInt(LEntry[0]) <> AIndex then
    raise EReplayMismatch.Create('MOBJNAME expected for ' + LEntry[0] + ' but asked for ' + IntToStr(AIndex));
  Result := TReplayText.Decode(LEntry[1]);
end;

function TReplayEngine.AddAlias(const AName, AOtherName: string): Boolean;
var
  LEntry: TArray<string>;
begin
  LEntry := Next('ALIAS');
  if (TReplayText.Decode(LEntry[0]) <> AName) or (TReplayText.Decode(LEntry[1]) <> AOtherName) then
    raise EReplayMismatch.Create('ALIAS expected for "' + TReplayText.Decode(LEntry[0]) + '" and "' +
      TReplayText.Decode(LEntry[1]) + '" but asked for "' + AName + '" and "' + AOtherName + '"');
  Result := LEntry[2] = '1';
end;

function TReplayEngine.IndexOfToken(const AToken: string): Integer;
begin
  Result := StrToInt(Query('STATEIDX', AToken));
end;

procedure TReplayEngine.Add(const AEntry: string);
var
  LEntry: TArray<string>;
begin
  LEntry := Next('STATEADD');
  if TReplayText.Decode(LEntry[0]) <> AEntry then
    raise EReplayMismatch.Create('STATEADD expected for "' + TReplayText.Decode(LEntry[0]) +
      '" but asked for "' + AEntry + '"');
end;

{ TEventRecorder }

constructor TEventRecorder.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TEventRecorder.Event(const AText: string);
begin
  FLog.Info('@ ' + AText + #13#10);
end;

function TEventRecorder.TypeName(AType: TActorDefScriptType): string;
begin
  if AType = TActorDefScriptType.Global then
    Result := 'global'
  else
    Result := 'normal';
end;

procedure TEventRecorder.SubmitThinker(const AThinker: TActorDefThinker);
begin
  Event('THINKER ' + TReplayText.Encode(AThinker.Name) + '|' + TReplayText.Encode(AThinker.Script) +
    '|' + IntToStr(AThinker.Dn) + '|' + IntToStr(AThinker.RepeatCount) + '|' +
    IntToStr(AThinker.Interval));
end;

procedure TEventRecorder.AddSourceScript(const AName, ASource: string; AType: TActorDefScriptType);
begin
  Event('SCRIPT ' + TReplayText.Encode(AName) + '|' + TypeName(AType) + '|' +
    TReplayText.Encode(ASource));
end;

procedure TEventRecorder.AddExternalScript(const AName, AFileName: string; AType: TActorDefScriptType);
begin
  Event('EXTSCRIPT ' + TReplayText.Encode(AName) + '|' + TReplayText.Encode(AFileName) + '|' +
    TypeName(AType));
end;

procedure TEventRecorder.AddCompiledScript(const AName, AFileName: string);
begin
  Event('COMPILEDSCRIPT ' + TReplayText.Encode(AName) + '|' + TReplayText.Encode(AFileName));
end;

procedure TEventRecorder.ParseDehFile(const AFileName: string);
begin
  Event('DEHFILE ' + TReplayText.Encode(AFileName) + '|0');
end;

procedure TEventRecorder.ParseAllDehFiles(const AFileName: string);
begin
  Event('DEHFILE ' + TReplayText.Encode(AFileName) + '|1');
end;

procedure TEventRecorder.ParseText(const AText: string);
begin
  Event('DEH-BEGIN');
  FLog.Info(AText);
  Event('DEH-END');
end;

end.
