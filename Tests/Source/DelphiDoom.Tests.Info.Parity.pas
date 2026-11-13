{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the info tables library against the old code (DUnitX)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Info.Parity;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Info.DoomedNumbers,
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.MobjAliases,
  DelphiDoom.Info.MobjLookup,
  DelphiDoom.Tests.InfoTables.Tables;

type
  [TestFixture]
  [Category('info')]
  TTestInfoParity = class
  strict private
    FTables: IInfoMobjSource;
    FStates: IInfoStateSource;
    FSprites: IInfoSpriteSource;
    FAliases: TInfoMobjAliases;
    FLookup: TInfoMobjLookup;
    procedure Begin_(const ASeed: Integer);
    procedure End_;
  public
    [Test]
    procedure DovrebbeTrovareLeStesseCosePerNumeroDelVecchioCodice;
    [Test]
    procedure DovrebbeTrovareLeStesseCosePerNomeEPerAliasDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLaStessaRadiceDiEreditarietaDelVecchioCodice;
    [Test]
    procedure DovrebbeDareGliStessiStatiDiUnaCosaDelVecchioCodice;
    [Test]
    procedure DovrebbeSegnalareLeStesseCatenePerpetueDelVecchioCodice;
    [Test]
    procedure DovrebbeDareGliStessiNomiESpriteDelVecchioCodice;
    [Test]
    procedure DovrebbeTrovareGliStessiStatiDiUnoSpriteDelVecchioCodice;
    [Test]
    procedure DovrebbeDareGliStessiNomiDeiGruppiDelVecchioCodice;
    [Test]
    procedure DovrebbeScegliereGliStessiMostriACasoDelVecchioCodice;
    [Test]
    procedure DovrebbeDareGliStessiStatiPerNomeDelVecchioCodice;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  d_delphi,
  DelphiDoom.ActorDef.ParamList.Intf,
  DelphiDoom.ActorDef.ParamString,
  DelphiDoom.Info.GroupNames,
  DelphiDoom.Info.RandomMonsters,
  DelphiDoom.Info.SpriteNames,
  DelphiDoom.Info.SpriteStates,
  DelphiDoom.Info.StateNames,
  DelphiDoom.Info.StateWalker,
  DelphiDoom.Info.Types,
  DelphiDoom.Tests.InfoTables.Fakes,
  DelphiDoom.Tests.InfoTables.LegacyInfo,
  DelphiDoom.Tests.InfoTables.LegacyParams,
  DelphiDoom.Tests.InfoTables.LegacyTokens;

const
  Rounds = 150;

type
  TTestThingNames = class(TInterfacedObject, IInfoThingNames)
  strict private
    FLookup: TInfoMobjLookup;
  public
    constructor Create(const ALookup: TInfoMobjLookup);
    function NumForName(const AName: string): Integer;
  end;

  TTestStateTokens = class(TInterfacedObject, IInfoStateTokens)
  public
    function IndexOfToken(const AToken: string): Integer;
  end;

  TTestStateText = class(TInterfacedObject, IInfoStateText)
  strict private
    FRandom: IActorDefParamRandom;
  public
    constructor Create(const ARandom: IActorDefParamRandom);
    function Evaluate(const AText: string): string;
  end;

  TTestNameList = class(TInterfacedObject, IInfoNameList)
  strict private
    FList: TDTextList;
  public
    constructor Create(const AList: TDTextList);
    function Count: Integer;
    function Name(const AIndex: Integer): string;
    function IndexOf(const AName: string): Integer;
    function Add(const AName: string): Integer;
  end;

  TTestConstSink = class(TInterfacedObject, IInfoConstSink)
  strict private
    FLog: TStringList;
  public
    constructor Create(const ALog: TStringList);
    procedure AddConst(const AName: string; const AValue: Integer);
  end;

  TTestRandomRules = class(TInterfacedObject, IInfoRandomRules)
  public
    function Thresholds: TArray<Integer>;
    function IsMonster(const AMobj: TInfoMobj): Boolean;
    function IsValidThing(const ADoomedNum: Integer): Boolean;
    function DiscardCount: Integer;
  end;

{ TTestThingNames }

constructor TTestThingNames.Create(const ALookup: TInfoMobjLookup);
begin
  inherited Create;
  FLookup := ALookup;
end;

function TTestThingNames.NumForName(const AName: string): Integer;
begin
  Result := FLookup.NumForName(AName);
end;

{ TTestStateTokens }

function TTestStateTokens.IndexOfToken(const AToken: string): Integer;
begin
  Result := legacy_statenames.IndexOfToken(AToken);
end;

{ TTestStateText }

constructor TTestStateText.Create(const ARandom: IActorDefParamRandom);
begin
  inherited Create;
  FRandom := ARandom;
end;

function TTestStateText.Evaluate(const AText: string): string;
begin
  Result := TActorDefParamString.Evaluate(AText, FRandom);
end;

{ TTestNameList }

constructor TTestNameList.Create(const AList: TDTextList);
begin
  inherited Create;
  FList := AList;
end;

function TTestNameList.Count: Integer;
begin
  Result := FList.Count;
end;

function TTestNameList.Name(const AIndex: Integer): string;
begin
  Result := FList.Strings[AIndex];
end;

function TTestNameList.IndexOf(const AName: string): Integer;
begin
  Result := FList.IndexOf(AName);
end;

function TTestNameList.Add(const AName: string): Integer;
begin
  Result := FList.Add(AName);
end;

{ TTestConstSink }

constructor TTestConstSink.Create(const ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TTestConstSink.AddConst(const AName: string; const AValue: Integer);
begin
  FLog.Add('const ' + AName + ' ' + IntToStr(AValue));
end;

{ TTestRandomRules }

function TTestRandomRules.Thresholds: TArray<Integer>;
begin
  Result := [80, 400, 1200, 2500];
end;

function TTestRandomRules.IsMonster(const AMobj: TInfoMobj): Boolean;
begin
  // the Doom rule of info_rnd
  Result := (AMobj.DoomedNum > MAXPLAYERS) and (AMobj.Flags and MF_SHOOTABLE <> 0) and
    ((AMobj.Flags and MF_COUNTKILL <> 0) or (AMobj.MissileState <> 0) or (AMobj.MeleeState <> 0));
end;

function TTestRandomRules.IsValidThing(const ADoomedNum: Integer): Boolean;
begin
  Result := Legacy_ValidFunc(ADoomedNum);
end;

function TTestRandomRules.DiscardCount: Integer;
begin
  Result := Legacy_SeedValue;
end;

function TestGroup(const AName: string; const AValue: Integer): TInfoGroupName;
begin
  Result.Name := AName;
  Result.Value := AValue;
end;

// what Info_GetSpriteNameForNum of the facade does with the library
function NewSpriteName(const AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= numsprites) then
    Result := ''
  else
    Result := TInfoSpriteNames.NameOfCode(sprnames[AIndex]);
end;

{ TTestInfoParity }

procedure TTestInfoParity.Begin_(const ASeed: Integer);
begin
  BuildScenario(ASeed);
  FTables := TTestInfoTables.Create;
  FStates := FTables as IInfoStateSource;
  FSprites := FTables as IInfoSpriteSource;
  FAliases := TInfoMobjAliases.Create;
  FLookup := TInfoMobjLookup.Create(FTables, FAliases, MOBJINFONAMESIZE);
  Legacy_Info_InitDnLookUp;
end;

procedure TTestInfoParity.End_;
begin
  Legacy_Info_ShutDownDnLookUp;
  FLookup.Free;
  FAliases.Free;
  FStates := nil;
  FSprites := nil;
  FTables := nil;
  FreeScenario;
end;

procedure TTestInfoParity.DovrebbeTrovareLeStesseCosePerNumeroDelVecchioCodice;
var
  LRound: Integer;
  LQuery: Integer;
  LDoomed: TInfoDoomedNumbers;
  LNumber: Integer;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(1000 + LRound);
    LDoomed := TInfoDoomedNumbers.Create(FTables);
    try
      for LQuery := 1 to 80 do
      begin
        // a negative number made the old code write before its table: not asked here
        LNumber := Random(34);
        if Random(5) = 0 then
          LNumber := LNumber + 65536 * Random(3);
        Assert.AreEqual(Legacy_Info_GetMobjNumForDoomNum(LNumber), LDoomed.ThingForNumber(LNumber),
          'round ' + IntToStr(LRound) + ' number ' + IntToStr(LNumber));
      end;
    finally
      LDoomed.Free;
      End_;
    end;
  end;
end;

procedure TTestInfoParity.DovrebbeTrovareLeStesseCosePerNomeEPerAliasDelVecchioCodice;
const
  Texts: array[0..21] of string = (
    'ZOMBIE', 'zombie', ' Imp ', 'imp0', 'SHOTGUN GUY', 'shotgunguy', 'demon', '', '-1', '3', '999', '0x2',
    'DEH_ACTOR_4', 'DEH_ACTOR_900', 'deh_actor_x', 'Lost Soul', 'LOSTSOUL', 'a b', 'AB', 'X-1', 'S P A C E',
    'nothing');
var
  LRound: Integer;
  LStep: Integer;
  LFirst: string;
  LSecond: string;
  LOld: Boolean;
  LNew: Boolean;
  LNumber1: Integer;
  LNumber2: Integer;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(2000 + LRound);
    try
      for LStep := 1 to 60 do
      begin
        LFirst := Texts[Random(Length(Texts))];
        LSecond := Texts[Random(Length(Texts))];
        if Random(3) = 0 then
        begin
          LOld := Legacy_Info_AddMobjNameAlias(LFirst, LSecond);
          // what TEngineInfoThings.AddAlias does
          LNumber1 := FLookup.NumForName(LFirst);
          if LNumber1 >= 0 then
            FAliases.Add(LSecond, LNumber1);
          LNumber2 := FLookup.NumForName(LSecond);
          if LNumber2 >= 0 then
            FAliases.Add(LFirst, LNumber2);
          LNew := (LNumber1 >= 0) or (LNumber2 >= 0);
          Assert.AreEqual(LOld, LNew, 'alias ' + LFirst + ' ' + LSecond);
        end
        else
          Assert.AreEqual(Legacy_Info_GetMobjNumForName(LFirst), FLookup.NumForName(LFirst),
            'round ' + IntToStr(LRound) + ' name "' + LFirst + '"');
      end;
    finally
      End_;
    end;
  end;
end;

procedure TTestInfoParity.DovrebbeDareLaStessaRadiceDiEreditarietaDelVecchioCodice;
var
  LRound: Integer;
  LIndex: Integer;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(3000 + LRound);
    try
      for LIndex := 0 to nummobjtypes - 1 do
        Assert.AreEqual(Legacy_Info_GetInheritance(@mobjinfo[LIndex]), FLookup.RootOf(LIndex),
          'round ' + IntToStr(LRound) + ' thing ' + IntToStr(LIndex));
    finally
      End_;
    end;
  end;
end;

procedure TTestInfoParity.DovrebbeDareGliStessiStatiDiUnaCosaDelVecchioCodice;
var
  LRound: Integer;
  LIndex: Integer;
  LWalker: TInfoStateWalker;
  LOld: TDNumberList;
  LNew: TArray<Integer>;
  LNumber: Integer;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(4000 + LRound);
    LWalker := TInfoStateWalker.Create(FTables, FStates);
    try
      for LIndex := 0 to nummobjtypes - 1 do
      begin
        LOld := Legacy_Info_GetStatesForMobjInfo(LIndex);
        try
          LNew := LWalker.StatesOf(LIndex);
          Assert.AreEqual(LOld.Count, Length(LNew), 'round ' + IntToStr(LRound) + ' thing ' + IntToStr(LIndex));
          for LNumber := 0 to LOld.Count - 1 do
            Assert.AreEqual(LOld.Numbers[LNumber], LNew[LNumber]);
        finally
          LOld.Free;
        end;
      end;
      Assert.AreEqual(0, Length(LWalker.StatesOf(-1)));
    finally
      LWalker.Free;
      End_;
    end;
  end;
end;

procedure TTestInfoParity.DovrebbeSegnalareLeStesseCatenePerpetueDelVecchioCodice;
var
  LRound: Integer;
  LWalker: TInfoStateWalker;
  LNew: TArray<Integer>;
  LIndex: Integer;
  LOldLines: string;
  LNewLines: string;
  LFoundLoop: Boolean;
begin
  LFoundLoop := False;
  for LRound := 1 to Rounds do
  begin
    Begin_(5000 + LRound);
    LWalker := TInfoStateWalker.Create(FTables, FStates);
    try
      Legacy_Info_CheckStates;
      LNew := LWalker.StatesWithEndlessChain;
      LOldLines := '';
      for LIndex := 0 to LegacyLog.Count - 1 do
        LOldLines := LOldLines + Copy(LegacyLog[LIndex], Pos('State ', LegacyLog[LIndex]) + 6,
          Pos(' has', LegacyLog[LIndex]) - Pos('State ', LegacyLog[LIndex]) - 6) + '|';
      LNewLines := '';
      for LIndex := 0 to High(LNew) do
        LNewLines := LNewLines + IntToStr(LNew[LIndex]) + '|';
      Assert.AreEqual(LOldLines, LNewLines, 'round ' + IntToStr(LRound));
      LFoundLoop := LFoundLoop or (Length(LNew) > 0);
    finally
      LWalker.Free;
      End_;
    end;
  end;
  Assert.IsTrue(LFoundLoop, 'the scenarios must have loops');
end;

procedure TTestInfoParity.DovrebbeDareGliStessiNomiESpriteDelVecchioCodice;
const
  Texts: array[0..13] of string = (
    'AAAR', 'ABRS', 'abrs', 'ZZZZ', 'abc', 'abcde', '', '1', '99', '-1', '0x1', '#2', 'S_SK', 'aars');
var
  LRound: Integer;
  LIndex: Integer;
  LText: string;
  LOld: Integer;
  LNew: Integer;
  LCode: Integer;
  LOldError: Boolean;
  LNewError: Boolean;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(6000 + LRound);
    try
      for LIndex := -1 to numsprites do
        Assert.AreEqual(Legacy_Info_GetSpriteNameForNum(LIndex),
          NewSpriteName(LIndex), 'name ' + IntToStr(LIndex));
      for LText in Texts do
      begin
        LOldError := False;
        LNewError := False;
        LOld := 0;
        LNew := 0;
        try
          LOld := Legacy_Info_CheckSpriteNumForName(LText);
        except
          on Exception do
            LOldError := True;
        end;
        if not TInfoSpriteNames.TryParseIndex(LText, numsprites, LNew) then
        begin
          if not TInfoSpriteNames.TryCode(LText, LCode) then
            LNewError := True
          else
          begin
            LNew := -1;
            for LIndex := 0 to numsprites - 1 do
              if sprnames[LIndex] = LCode then
              begin
                LNew := LIndex;
                Break;
              end;
          end;
        end;
        Assert.AreEqual(LOldError, LNewError, 'error ' + LText);
        if not LOldError then
          Assert.AreEqual(LOld, LNew, 'sprite ' + LText);
      end;
    finally
      End_;
    end;
  end;
end;

procedure TTestInfoParity.DovrebbeTrovareGliStessiStatiDiUnoSpriteDelVecchioCodice;
const
  Texts: array[0..11] of string = ('AAAR', 'ABRS', 'abrs', 'AAARA', 'AAARb', 'ABRSz', 'ZZZZ', 'ZZZZA', 'abc', '', 'AAARAA', 'acrsC');
var
  LRound: Integer;
  LText: string;
  LFinder: TInfoSpriteStates;
  LOld: TDNumberList;
  LNew: TArray<Integer>;
  LIndex: Integer;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(7000 + LRound);
    LFinder := TInfoSpriteStates.Create(FSprites, FStates);
    try
      for LText in Texts do
      begin
        LOld := Legacy_Info_FindStatesFromSprite(LText);
        try
          LNew := LFinder.Find(LText);
          Assert.AreEqual(LOld.Count, Length(LNew), 'round ' + IntToStr(LRound) + ' sprite ' + LText);
          for LIndex := 0 to LOld.Count - 1 do
            Assert.AreEqual(LOld.Numbers[LIndex], LNew[LIndex]);
        finally
          LOld.Free;
        end;
      end;
    finally
      LFinder.Free;
      End_;
    end;
  end;
end;

procedure TTestInfoParity.DovrebbeDareGliStessiNomiDeiGruppiDelVecchioCodice;
const
  Texts: array[0..13] of string = (
    'IG_DEFAULT', 'default', 'INVALID', 'IG_ONE', 'one', '5', '-3', '7', 'ig_9', '', ' x', 'PG_BARON', 'baron',
    'SG_NEW');
var
  LRound: Integer;
  LStep: Integer;
  LGroups: array[0..2] of TInfoGroupNames;
  LLists: array[0..2] of TDTextList;
  LLog: TStringList;
  LKind: Integer;
  LText: string;
  LValue: Integer;
  LOldList: TDTextList;
  LIndex: Integer;
  LOldLogged: string;
  LNewLogged: string;
  LLine: string;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(8000 + LRound);
    LLog := TStringList.Create;
    for LKind := 0 to 2 do
    begin
      LLists[LKind] := TDTextList.Create;
      case LKind of
        0: LOldList := infighting_groups;
        1: LOldList := projectile_groups;
      else
        LOldList := splash_groups;
      end;
      for LIndex := 0 to LOldList.Count - 1 do
        LLists[LKind].Add(LOldList[LIndex]);
    end;
    LGroups[0] := TInfoGroupNames.Create('IG_', IG_INVALID,
      [TestGroup('IG_DEFAULT', IG_DEFAULT), TestGroup('IG_INVALID', IG_INVALID)],
      TTestNameList.Create(LLists[0]), TTestConstSink.Create(LLog));
    LGroups[1] := TInfoGroupNames.Create('PG_', PG_GROUPLESS,
      [TestGroup('PG_GROUPLESS', PG_GROUPLESS), TestGroup('PG_INVALID', PG_INVALID),
       TestGroup('PG_DEFAULT', PG_DEFAULT), TestGroup('PG_BARON', PG_BARON)],
      TTestNameList.Create(LLists[1]), TTestConstSink.Create(LLog));
    LGroups[2] := TInfoGroupNames.Create('SG_', SG_INVALID,
      [TestGroup('SG_DEFAULT', SG_DEFAULT), TestGroup('SG_INVALID', SG_INVALID)],
      TTestNameList.Create(LLists[2]), TTestConstSink.Create(LLog));
    try
      for LStep := 1 to 80 do
      begin
        LKind := Random(3);
        if Random(2) = 0 then
        begin
          LText := Texts[Random(Length(Texts))];
          case LKind of
            0: LValue := Legacy_Info_InfightingGroupToInt(LText);
            1: LValue := Legacy_Info_ProjectileGroupToInt(LText);
          else
            LValue := Legacy_Info_SplashGroupToInt(LText);
          end;
          Assert.AreEqual(LValue, LGroups[LKind].ToValue(LText), 'value ' + LText + ' kind ' + IntToStr(LKind));
        end
        else
        begin
          LValue := Random(16) - 4;
          if Random(6) = 0 then
            LValue := Low(Integer);
          case LKind of
            0: LText := Legacy_Info_InfightingGroupToString(LValue);
            1: LText := Legacy_Info_ProjectileGroupToString(LValue);
          else
            LText := Legacy_Info_SplashGroupToString(LValue);
          end;
          Assert.AreEqual(LText, LGroups[LKind].ToText(LValue), 'text ' + IntToStr(LValue) + ' kind ' + IntToStr(LKind));
        end;
      end;
      LOldLogged := '';
      LNewLogged := '';
      for LLine in LegacyLog do
        if LLine.StartsWith('const ') then
          LOldLogged := LOldLogged + LLine + '|';
      for LLine in LLog do
        LNewLogged := LNewLogged + LLine + '|';
      Assert.AreEqual(LOldLogged, LNewLogged, 'constants added');
      Assert.AreEqual(infighting_groups.Count, LLists[0].Count);
      Assert.AreEqual(projectile_groups.Count, LLists[1].Count);
      Assert.AreEqual(splash_groups.Count, LLists[2].Count);
    finally
      for LKind := 0 to 2 do
      begin
        LGroups[LKind].Free;
        LLists[LKind].Free;
      end;
      LLog.Free;
      End_;
    end;
  end;
end;

procedure TTestInfoParity.DovrebbeScegliereGliStessiMostriACasoDelVecchioCodice;
var
  LRound: Integer;
  LType: Integer;
  LOldRandom: TFakeParamRandom;
  LOldRef: IInfoRandom;
  LNewRandom: TFakeParamRandom;
  LNewRef: IInfoRandom;
  LMonsters: TInfoRandomMonsters;
  LOld: Integer;
  LNew: Integer;
  LOldError: Boolean;
  LNewError: Boolean;
  LSeed: Cardinal;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(9000 + LRound);
    Legacy_ValidFunc := function(ADoomedNum: Integer): Boolean begin Result := ADoomedNum mod 5 <> 2; end;
    Legacy_SeedValue := Random(4);
    LNewRandom := TFakeParamRandom.Create(0);
    LNewRef := LNewRandom;
    LMonsters := TInfoRandomMonsters.Create(FTables, TTestRandomRules.Create, LNewRef);
    try
      Legacy_Info_InitRandomMonsters;
      LMonsters.Initialize;
      LMonsters.Initialize;
      for LType := 0 to nummobjtypes - 1 do
      begin
        Assert.AreEqual(Legacy_Info_IsMonster(LType), LMonsters.IsMonster(LType));
        LSeed := Cardinal(LType * 7 + LRound);
        LOldRandom := TFakeParamRandom.Create(LSeed);
        LOldRef := LOldRandom;
        Legacy_NRandomFunc := function: Integer begin Result := LOldRandom.Next; end;
        LNewRandom := TFakeParamRandom.Create(LSeed);
        LNewRef := LNewRandom;
        LMonsters.Shutdown;
        LMonsters.Free;
        LMonsters := TInfoRandomMonsters.Create(FTables, TTestRandomRules.Create, LNewRef);
        LMonsters.Initialize;
        LOldError := False;
        LNewError := False;
        LOld := 0;
        LNew := 0;
        try
          LOld := Legacy_Info_SelectRandomMonster(LType);
        except
          on Exception do
            LOldError := True;
        end;
        try
          LNew := LMonsters.Select(LType);
        except
          on EInfoException do
            LNewError := True;
        end;
        Assert.AreEqual(LOldError, LNewError, 'error type ' + IntToStr(LType));
        if not LOldError then
        begin
          Assert.AreEqual(LOld, LNew, 'round ' + IntToStr(LRound) + ' type ' + IntToStr(LType));
          Assert.AreEqual(LOldRandom.Draws, LNewRandom.Draws, 'draws');
        end;
      end;
    finally
      Legacy_Info_ShutDownRandomMonsters;
      LMonsters.Free;
      End_;
    end;
  end;
end;

procedure TTestInfoParity.DovrebbeDareGliStessiStatiPerNomeDelVecchioCodice;
const
  Texts: array[0..29] of string = (
    'SPAWN', 'see', 'Death', 'XDEATH', 'melee', 'MISSILE', 'pain', 'raise', 'crash', 'crush', 'interact', 'heal',
    'SUPER::SPAWN', 'SELF::SEE', 'ZOMBIE::DEATH', 'imp::pain', '::spawn', '1', '+3', '-2', 'SPAWN+2', 'SEE - 1',
    'RANDOMPICK(SPAWN, SEE)', 'random(1, 3)', '', 'xyz', 'S_X3', 's_alias5', '12', 'x + 2');
var
  LRound: Integer;
  LStep: Integer;
  LNames: TInfoStateNames;
  LThings: IInfoThingNames;
  LActorIndex: Integer;
  LStateIndex: Integer;
  LActor: DelphiDoom.Tests.InfoTables.LegacyInfo.mobj_t;
  LText: string;
  LSeed: Cardinal;
  LOldRandom: TFakeParamRandom;
  LOldRef: IInfoRandom;
  LNewRandom: TFakeParamRandom;
  LNewRef: IActorDefParamRandom;
  LOld: Integer;
  LNew: Integer;
begin
  for LRound := 1 to Rounds do
  begin
    Begin_(10000 + LRound);
    LThings := TTestThingNames.Create(FLookup);
    try
      for LStep := 1 to 60 do
      begin
        LText := Texts[Random(Length(Texts))];
        LActorIndex := Random(nummobjtypes);
        LStateIndex := Random(numstates);
        LActor.info := @mobjinfo[LActorIndex];
        LActor.state := @states[LStateIndex];
        LSeed := Cardinal(LStep * 31 + LRound);
        LOldRandom := TFakeParamRandom.Create(LSeed);
        LOldRef := LOldRandom;
        Legacy_NRandomSource := function: Integer begin Result := LOldRandom.Next; end;
        LNewRandom := TFakeParamRandom.Create(LSeed);
        LNewRef := LNewRandom;
        LNames := TInfoStateNames.Create(TTestStateTokens.Create, FTables, LThings, TTestStateText.Create(LNewRef));
        try
          if Random(2) = 0 then
          begin
            LOld := Legacy_P_GetStateFromName(@LActor, LText);
            LNew := LNames.StateFromName(FTables.Get(LActorIndex), LText);
          end
          else
          begin
            LOld := Legacy_P_GetStateFromNameWithOffsetCheck(@LActor, LText);
            LNew := LNames.StateFromNameWithOffset(FTables.Get(LActorIndex), LStateIndex, LText);
          end;
          Assert.AreEqual(LOld, LNew, 'round ' + IntToStr(LRound) + ' text "' + LText + '" thing ' + IntToStr(LActorIndex));
          Assert.AreEqual(LOldRandom.Draws, LNewRandom.Draws, 'draws ' + LText);
        finally
          LNames.Free;
        end;
      end;
    finally
      LThings := nil;
      End_;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestInfoParity);

end.
