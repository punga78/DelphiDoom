{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the game, texture and keyboard functions of PS_GAME    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.GameSections;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Game.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  /// <summary>A keyboard that the test sets</summary>
  TFakeKeyboard = class(TInterfacedObject, IScriptKeyboardSource)
  public
    Blocked: Boolean;
    Values: array[TScriptKey] of Integer;
    KeysDown: array[0..255] of Boolean;
    MouseDown: array[0..2] of Boolean;
    JoyDown: array[0..11] of Boolean;
    function IsInputBlocked: Boolean;
    function KeyValue(const AKey: TScriptKey): Integer;
    function KeyCount: Integer;
    function JoyButtonCount: Integer;
    function IsKeyDown(const AIndex: Integer): Boolean;
    function IsMouseButtonDown(const AIndex: Integer): Boolean;
    function IsJoyButtonDown(const AIndex: Integer): Boolean;
  end;

  TFakeGameInfo = class(TInterfacedObject, IScriptGameInfoSource)
  public
    Name: string;
    SkillValue: Integer;
    MapValue: Integer;
    EpisodeValue: Integer;
    Calls: string;
    function GameName: string;
    function Skill: Integer;
    function MapNumber: Integer;
    function Episode: Integer;
    procedure GlobalEarthQuake(const ATics: Integer);
    procedure LocalEarthQuake(const X, Y, Z: Integer; const ATics: Integer; const AIntensity: Integer;
      const AMaxDistance: Integer);
  end;

  /// <summary>Textures 1 to 3: "wall" (64x128), "door" (32x72), "sky" (256x128)</summary>
  TFakeTextures = class(TInterfacedObject, IScriptTextureSource)
  public
    function TextureId(const AName: string): Integer;
    function TextureCount: Integer;
    function TextureWidth(const AId: Integer): Integer;
    function TextureHeight(const AId: Integer): Integer;
  end;

  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostGameSections = class(TObject)
  strict private
    FKeyboard: TFakeKeyboard;
    FKeyboardRef: IScriptKeyboardSource;
    FGameInfo: TFakeGameInfo;
    FGameInfoRef: IScriptGameInfoSource;
    FTables: TList<IScriptFunctionTable>;
    FSections: TList<IScriptFunctionSection>;
    function Describe(const ASection: IScriptFunctionSection): TFakeFunctionTable;
    function KeysOf(const AGame: TScriptGame): IScriptFunctionSection;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDellaTastieraDiOgniGioco;
    [Test]
    procedure DovrebbeAvereLaTabellaDellaTastieraDi56Funzioni;
    [Test]
    procedure DovrebbeNonRipetereUnNomeNellaTastieraDiUnGioco;
    [Test]
    procedure DovrebbeIniziareLaTastieraConLeTreFunzioniConParametro;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDiStrifeCheDoomNonHa;
    [Test]
    procedure DovrebbeDareIlTastoDiOgniAzioneConLoStessoMetodoESelfDiversi;
    [Test]
    procedure DovrebbeDareZeroAiTastiInUnaDemoOInRete;
    [Test]
    procedure DovrebbeDareIlTastoDelMouseAnchoraInUnaDemo;
    [Test]
    procedure DovrebbeLeggereITastiPremutiNeiLimiti;
    [Test]
    procedure DovrebbeDareFalsoPerUnTastoFuoriDaiLimiti;
    [Test]
    procedure DovrebbeLeggereIPulsantiDelMouseEDelJoystick;
    [Test]
    procedure DovrebbeDareFalsoPerUnPulsanteFuoriDaiLimiti;
    [Test]
    procedure DovrebbeDareFalsoATuttiITastiInUnaDemo;
    [Test]
    procedure DovrebbeDareErroreSeLaSorgenteDellaTastieraEnil;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDellaPartitaDiDoomEHeretic;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDellaPartitaDiHexenEStrifeSenzaEpisodio;
    [Test]
    procedure DovrebbeInoltrareLeFunzioniDellaPartita;
    [Test]
    procedure DovrebbeDareErroreSeLaSorgenteDellaPartitaEnil;
    [Test]
    procedure DovrebbeDescrivereLeTreFunzioniDelleTexture;
    [Test]
    procedure DovrebbeDareLeDimensioniDiUnaTexture;
    [Test]
    procedure DovrebbeDareZeroPerUnaTextureCheNonCe;
    [Test]
    procedure DovrebbeDareZeroPerLaTextureVuota;
    [Test]
    procedure DovrebbeDareErroreSeLaSorgenteDelleTextureEnil;
    [Test]
    procedure DovrebbeChiamareLeFunzioniDaUnoScriptVero;
    [Test]
    procedure DovrebbeTrovareIlGiocoDalNome;
  end;

implementation

uses
  ps_defs,
  ps_utils,
  ps_keywords,
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.FunctionList,
  DelphiDoom.ScriptHost.Games,
  DelphiDoom.ScriptHost.Keys,
  DelphiDoom.ScriptHost.Keys.Table,
  DelphiDoom.ScriptHost.Game.Info,
  DelphiDoom.ScriptHost.Game.Textures;

var
  GUsedList: TScriptFunctionList;

function OnUsesGameList(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
  if Result then
  begin
    Sender.AddTypeS('fixed_t', 'Integer');
    GUsedList.RegisterCompiler(Sender);
  end;
end;

{ TFakeKeyboard }

function TFakeKeyboard.IsInputBlocked: Boolean;
begin
  Result := Blocked;
end;

function TFakeKeyboard.KeyValue(const AKey: TScriptKey): Integer;
begin
  Result := Values[AKey];
end;

function TFakeKeyboard.KeyCount: Integer;
begin
  Result := Length(KeysDown);
end;

function TFakeKeyboard.JoyButtonCount: Integer;
begin
  Result := Length(JoyDown);
end;

function TFakeKeyboard.IsKeyDown(const AIndex: Integer): Boolean;
begin
  Result := KeysDown[AIndex];
end;

function TFakeKeyboard.IsMouseButtonDown(const AIndex: Integer): Boolean;
begin
  Result := MouseDown[AIndex];
end;

function TFakeKeyboard.IsJoyButtonDown(const AIndex: Integer): Boolean;
begin
  Result := JoyDown[AIndex];
end;

{ TFakeGameInfo }

function TFakeGameInfo.GameName: string;
begin
  Result := Name;
end;

function TFakeGameInfo.Skill: Integer;
begin
  Result := SkillValue;
end;

function TFakeGameInfo.MapNumber: Integer;
begin
  Result := MapValue;
end;

function TFakeGameInfo.Episode: Integer;
begin
  Result := EpisodeValue;
end;

procedure TFakeGameInfo.GlobalEarthQuake(const ATics: Integer);
begin
  Calls := Calls + Format('G(%d)', [ATics]);
end;

procedure TFakeGameInfo.LocalEarthQuake(const X, Y, Z: Integer; const ATics: Integer;
  const AIntensity: Integer; const AMaxDistance: Integer);
begin
  Calls := Calls + Format('L(%d,%d,%d,%d,%d,%d)', [X, Y, Z, ATics, AIntensity, AMaxDistance]);
end;

{ TFakeTextures }

function TFakeTextures.TextureId(const AName: string): Integer;
begin
  if (AName = '') or (AName = '-') then
    Result := 0
  else if AName = 'wall' then
    Result := 1
  else if AName = 'door' then
    Result := 2
  else if AName = 'sky' then
    Result := 3
  else
    Result := MaxInt;
end;

function TFakeTextures.TextureCount: Integer;
begin
  Result := 4;
end;

function TFakeTextures.TextureWidth(const AId: Integer): Integer;
begin
  case AId of
    1: Result := 64;
    2: Result := 32;
  else
    Result := 256;
  end;
end;

function TFakeTextures.TextureHeight(const AId: Integer): Integer;
begin
  case AId of
    1: Result := 128;
    2: Result := 72;
  else
    Result := 128;
  end;
end;

{ TTestScriptHostGameSections }

procedure TTestScriptHostGameSections.Setup;
begin
  FKeyboard := TFakeKeyboard.Create;
  FKeyboardRef := FKeyboard;
  FGameInfo := TFakeGameInfo.Create;
  FGameInfoRef := FGameInfo;
  FTables := TList<IScriptFunctionTable>.Create;
  FSections := TList<IScriptFunctionSection>.Create;
end;

procedure TTestScriptHostGameSections.TearDown;
begin
  // the objects that the interpreter calls live as long as their section
  FTables.Free;
  FSections.Free;
  FGameInfoRef := nil;
  FGameInfo := nil;
  FKeyboardRef := nil;
  FKeyboard := nil;
end;

function TTestScriptHostGameSections.Describe(const ASection: IScriptFunctionSection): TFakeFunctionTable;
var
  LRef: IScriptFunctionTable;
begin
  Result := TFakeFunctionTable.Create;
  LRef := Result;
  FTables.Add(LRef);
  FSections.Add(ASection);
  ASection.Describe(LRef);
end;

function TTestScriptHostGameSections.KeysOf(const AGame: TScriptGame): IScriptFunctionSection;
begin
  Result := TScriptHostFactory.CreateKeys(FKeyboardRef, AGame);
end;

procedure TTestScriptHostGameSections.DovrebbeDescrivereLeFunzioniDellaTastieraDiOgniGioco;
var
  LSection: IScriptFunctionSection;
  LTable: TFakeFunctionTable;
begin
  // 3 with a parameter plus the actions of the game: the same count as the variables of g_game
  LSection := KeysOf(sgDoom);
  LTable := Describe(LSection);
  Assert.AreEqual(40, LTable.Declarations.Count);
  LSection := KeysOf(sgHeretic);
  LTable := Describe(LSection);
  Assert.AreEqual(46, LTable.Declarations.Count);
  LSection := KeysOf(sgHexen);
  LTable := Describe(LSection);
  Assert.AreEqual(42, LTable.Declarations.Count);
  LSection := KeysOf(sgStrife);
  LTable := Describe(LSection);
  Assert.AreEqual(52, LTable.Declarations.Count);
end;

procedure TTestScriptHostGameSections.DovrebbeAvereLaTabellaDellaTastieraDi56Funzioni;
begin
  Assert.AreEqual(56, Length(SCRIPT_KEY_ENTRIES));
end;

procedure TTestScriptHostGameSections.DovrebbeNonRipetereUnNomeNellaTastieraDiUnGioco;
var
  LGame: TScriptGame;
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LSeen: TStringList;
begin
  for LGame := Low(TScriptGame) to High(TScriptGame) do
  begin
    LTable := Describe(KeysOf(LGame));
    LSeen := TStringList.Create;
    try
      for LIndex := 0 to LTable.Declarations.Count - 1 do
      begin
        Assert.AreEqual(-1, LSeen.IndexOf(LTable.Declarations[LIndex]), LTable.Declarations[LIndex]);
        LSeen.Add(LTable.Declarations[LIndex]);
      end;
    finally
      LSeen.Free;
    end;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeIniziareLaTastieraConLeTreFunzioniConParametro;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(KeysOf(sgDoom));
  Assert.AreEqual('function gamekeydown(const kkey: integer): boolean;', LTable.Declarations[0]);
  Assert.AreEqual('function mousebuttons(const mkey: integer): boolean;', LTable.Declarations[1]);
  Assert.AreEqual('function joybuttons(const jkey: integer): boolean;', LTable.Declarations[2]);
  Assert.AreEqual('function key_right: integer;', LTable.Declarations[3]);
  Assert.AreEqual('function joyblright: integer;', LTable.Declarations[LTable.Declarations.Count - 1]);
end;

procedure TTestScriptHostGameSections.DovrebbeDescrivereLeFunzioniDiStrifeCheDoomNonHa;
var
  LDoom: TFakeFunctionTable;
  LStrife: TFakeFunctionTable;
begin
  LDoom := Describe(KeysOf(sgDoom));
  LStrife := Describe(KeysOf(sgStrife));
  Assert.IsTrue(LDoom.Declarations.IndexOf('function key_lookforward: integer;') >= 0);
  Assert.IsTrue(LStrife.Declarations.IndexOf('function key_lookforward: integer;') < 0);
  Assert.IsTrue(LDoom.Declarations.IndexOf('function key_invdrop: integer;') < 0);
  Assert.IsTrue(LStrife.Declarations.IndexOf('function key_invdrop: integer;') >= 0);
  Assert.IsTrue(LDoom.Declarations.IndexOf('function key_weapon4: integer;') >= 0);
  Assert.IsTrue(LStrife.Declarations.IndexOf('function key_flyup: integer;') < 0);
end;

procedure TTestScriptHostGameSections.DovrebbeDareIlTastoDiOgniAzioneConLoStessoMetodoESelfDiversi;
var
  LSection: IScriptFunctionSection;
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LKey: TScriptKey;
  LCode: Pointer;
begin
  for LKey := Low(TScriptKey) to High(TScriptKey) do
    FKeyboard.Values[LKey] := 1000 + Ord(LKey);
  LSection := KeysOf(sgStrife);
  LTable := Describe(LSection);
  LCode := LTable.Codes[3];
  for LIndex := 3 to LTable.Declarations.Count - 1 do
  begin
    // one method, and every line of the table has its own Self
    Assert.AreEqual(NativeInt(LCode), NativeInt(LTable.Codes[LIndex]));
    Assert.IsNotNull(LTable.Instances[LIndex]);
  end;
  Assert.AreEqual(1000 + Ord(skRight), TScriptKeyBinding(LTable.Instances[3]).Value);
  Assert.AreEqual(1000 + Ord(skLeft), TScriptKeyBinding(LTable.Instances[4]).Value);
  Assert.AreEqual(1000 + Ord(skJoyRight),
    TScriptKeyBinding(LTable.Instances[LTable.Declarations.Count - 1]).Value);
  Assert.AreNotEqual(NativeInt(LTable.Instances[3]), NativeInt(LTable.Instances[4]));
end;

procedure TTestScriptHostGameSections.DovrebbeDareZeroAiTastiInUnaDemoOInRete;
var
  LTable: TFakeFunctionTable;
begin
  FKeyboard.Values[skFire] := 77;
  LTable := Describe(KeysOf(sgDoom));
  FKeyboard.Blocked := True;
  Assert.AreEqual(0, TScriptKeyBinding(LTable.Instances[LTable.Declarations.IndexOf('function key_fire: integer;')]).Value);
  FKeyboard.Blocked := False;
  Assert.AreEqual(77, TScriptKeyBinding(LTable.Instances[LTable.Declarations.IndexOf('function key_fire: integer;')]).Value);
end;

procedure TTestScriptHostGameSections.DovrebbeDareIlTastoDelMouseAnchoraInUnaDemo;
var
  LTable: TFakeFunctionTable;
  LIndex: Integer;
begin
  // a defect of the old PS_mousebfire, kept: it had no test of the demo (the others have it)
  FKeyboard.Values[skMouseFire] := 5;
  FKeyboard.Values[skMouseStrafe] := 6;
  FKeyboard.Blocked := True;
  LTable := Describe(KeysOf(sgHexen));
  LIndex := LTable.Declarations.IndexOf('function mousebfire: integer;');
  Assert.AreEqual(5, TScriptKeyBinding(LTable.Instances[LIndex]).Value);
  LIndex := LTable.Declarations.IndexOf('function mousebstrafe: integer;');
  Assert.AreEqual(0, TScriptKeyBinding(LTable.Instances[LIndex]).Value);
end;

procedure TTestScriptHostGameSections.DovrebbeLeggereITastiPremutiNeiLimiti;
var
  LKeys: TScriptKeys;
begin
  LKeys := TScriptKeys.Create(FKeyboardRef, sgDoom);
  try
    FKeyboard.KeysDown[0] := True;
    FKeyboard.KeysDown[255] := True;
    FKeyboard.KeysDown[100] := False;
    Assert.IsTrue(LKeys.GameKeyDown(0));
    Assert.IsTrue(LKeys.GameKeyDown(255));
    Assert.IsFalse(LKeys.GameKeyDown(100));
  finally
    LKeys.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeDareFalsoPerUnTastoFuoriDaiLimiti;
var
  LKeys: TScriptKeys;
begin
  LKeys := TScriptKeys.Create(FKeyboardRef, sgDoom);
  try
    Assert.IsFalse(LKeys.GameKeyDown(-1));
    Assert.IsFalse(LKeys.GameKeyDown(256));
  finally
    LKeys.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeLeggereIPulsantiDelMouseEDelJoystick;
var
  LKeys: TScriptKeys;
begin
  LKeys := TScriptKeys.Create(FKeyboardRef, sgDoom);
  try
    FKeyboard.MouseDown[2] := True;
    FKeyboard.JoyDown[11] := True;
    Assert.IsTrue(LKeys.MouseButtons(2));
    Assert.IsFalse(LKeys.MouseButtons(0));
    Assert.IsTrue(LKeys.JoyButtons(11));
    Assert.IsFalse(LKeys.JoyButtons(5));
  finally
    LKeys.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeDareFalsoPerUnPulsanteFuoriDaiLimiti;
var
  LKeys: TScriptKeys;
begin
  LKeys := TScriptKeys.Create(FKeyboardRef, sgDoom);
  try
    Assert.IsFalse(LKeys.MouseButtons(3));
    Assert.IsFalse(LKeys.MouseButtons(-1));
    Assert.IsFalse(LKeys.JoyButtons(12));
    Assert.IsFalse(LKeys.JoyButtons(-1));
  finally
    LKeys.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeDareFalsoATuttiITastiInUnaDemo;
var
  LKeys: TScriptKeys;
begin
  LKeys := TScriptKeys.Create(FKeyboardRef, sgDoom);
  try
    FKeyboard.KeysDown[10] := True;
    FKeyboard.MouseDown[1] := True;
    FKeyboard.JoyDown[3] := True;
    FKeyboard.Blocked := True;
    Assert.IsFalse(LKeys.GameKeyDown(10));
    Assert.IsFalse(LKeys.MouseButtons(1));
    Assert.IsFalse(LKeys.JoyButtons(3));
  finally
    LKeys.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeDareErroreSeLaSorgenteDellaTastieraEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateKeys(nil, sgDoom);
    end, EArgumentNilException);
end;

procedure TTestScriptHostGameSections.DovrebbeDescrivereLeFunzioniDellaPartitaDiDoomEHeretic;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(TScriptHostFactory.CreateGameInfo(FGameInfoRef, sgDoom));
  Assert.AreEqual(6, LTable.Declarations.Count);
  Assert.AreEqual('function _GAME: string;', LTable.Declarations[0]);
  Assert.AreEqual('procedure GlobalEarthQuake(const tics: integer);', LTable.Declarations[1]);
  Assert.AreEqual('procedure LocalEarthQuake(const x, y, z: fixed_t; const tics: integer; ' +
    'const intensity: fixed_t; const maxdist: fixed_t);', LTable.Declarations[2]);
  Assert.AreEqual('function GameSkill: integer;', LTable.Declarations[3]);
  Assert.AreEqual('function GameMap: integer;', LTable.Declarations[4]);
  Assert.AreEqual('function GameEpisode: integer;', LTable.Declarations[5]);
  LTable := Describe(TScriptHostFactory.CreateGameInfo(FGameInfoRef, sgHeretic));
  Assert.AreEqual(6, LTable.Declarations.Count);
end;

procedure TTestScriptHostGameSections.DovrebbeDescrivereLeFunzioniDellaPartitaDiHexenEStrifeSenzaEpisodio;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(TScriptHostFactory.CreateGameInfo(FGameInfoRef, sgHexen));
  Assert.AreEqual(5, LTable.Declarations.Count);
  Assert.AreEqual(-1, LTable.Declarations.IndexOf('function GameEpisode: integer;'));
  LTable := Describe(TScriptHostFactory.CreateGameInfo(FGameInfoRef, sgStrife));
  Assert.AreEqual(5, LTable.Declarations.Count);
end;

procedure TTestScriptHostGameSections.DovrebbeInoltrareLeFunzioniDellaPartita;
var
  LInfo: TScriptGameInfo;
begin
  FGameInfo.Name := 'Doom';
  FGameInfo.SkillValue := 3;
  FGameInfo.MapValue := 7;
  FGameInfo.EpisodeValue := 2;
  LInfo := TScriptGameInfo.Create(FGameInfoRef, sgDoom);
  try
    Assert.AreEqual('Doom', LInfo.GameName);
    Assert.AreEqual(3, LInfo.GameSkill);
    Assert.AreEqual(7, LInfo.GameMap);
    Assert.AreEqual(2, LInfo.GameEpisode);
    LInfo.GlobalEarthQuake(35);
    LInfo.LocalEarthQuake(1, 2, 3, 4, 5, 6);
    Assert.AreEqual('G(35)L(1,2,3,4,5,6)', FGameInfo.Calls);
  finally
    LInfo.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeDareErroreSeLaSorgenteDellaPartitaEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateGameInfo(nil, sgDoom);
    end, EArgumentNilException);
end;

procedure TTestScriptHostGameSections.DovrebbeDescrivereLeTreFunzioniDelleTexture;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(TScriptHostFactory.CreateTextures(TFakeTextures.Create));
  Assert.AreEqual(3, LTable.Declarations.Count);
  Assert.AreEqual('function GetTextureWidth(const tex: string): Integer;', LTable.Declarations[0]);
  Assert.AreEqual('function GetTextureHeight(const tex: string): Integer;', LTable.Declarations[1]);
  Assert.AreEqual('function IsValidTexture(const tex: string): boolean;', LTable.Declarations[2]);
end;

procedure TTestScriptHostGameSections.DovrebbeDareLeDimensioniDiUnaTexture;
var
  LTextures: TScriptTextures;
begin
  LTextures := TScriptTextures.Create(TFakeTextures.Create);
  try
    Assert.AreEqual(64, LTextures.GetTextureWidth('wall'));
    Assert.AreEqual(128, LTextures.GetTextureHeight('wall'));
    Assert.AreEqual(72, LTextures.GetTextureHeight('door'));
    Assert.IsTrue(LTextures.IsValidTexture('sky'));
  finally
    LTextures.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeDareZeroPerUnaTextureCheNonCe;
var
  LTextures: TScriptTextures;
begin
  LTextures := TScriptTextures.Create(TFakeTextures.Create);
  try
    Assert.AreEqual(0, LTextures.GetTextureWidth('nothing'));
    Assert.AreEqual(0, LTextures.GetTextureHeight('nothing'));
    Assert.IsFalse(LTextures.IsValidTexture('nothing'));
  finally
    LTextures.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeDareZeroPerLaTextureVuota;
var
  LTextures: TScriptTextures;
begin
  LTextures := TScriptTextures.Create(TFakeTextures.Create);
  try
    // "" and "-" are texture 0, that is no texture for the scripts
    Assert.IsFalse(LTextures.IsValidTexture(''));
    Assert.IsFalse(LTextures.IsValidTexture('-'));
    Assert.AreEqual(0, LTextures.GetTextureWidth('-'));
  finally
    LTextures.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeDareErroreSeLaSorgenteDelleTextureEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateTextures(nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostGameSections.DovrebbeChiamareLeFunzioniDaUnoScriptVero;
const
  SCRIPT_TEXT =
    'var kr, sk, w: Integer; kd, tv: Boolean;'#13#10 +
    'begin'#13#10 +
    '  kr := key_right;'#13#10 +
    '  sk := GameSkill;'#13#10 +
    '  kd := gamekeydown(12);'#13#10 +
    '  w := GetTextureWidth(''wall'');'#13#10 +
    '  tv := IsValidTexture(''nothing'');'#13#10 +
    '  GlobalEarthQuake(9);'#13#10 +
    'end.';
var
  LList: TScriptFunctionList;
  LListRef: IScriptFunctionTable;
  LCompiler: TPSPascalCompiler;
  LExec: TPSExec;
  LBytes: TbtString;
  LKeys, LGame, LTextures: IScriptFunctionSection;

  function IntegerAt(const AIndex: Integer): Integer;
  var
    LVariable: PIFVariant;
  begin
    LVariable := LExec.GetVarNo(AIndex);
    Result := PSGetInt(@PPSVariantData(LVariable).Data, LVariable.FType);
  end;

begin
  FKeyboard.Values[skRight] := 174;
  FKeyboard.KeysDown[12] := True;
  FGameInfo.SkillValue := 4;
  LKeys := TScriptHostFactory.CreateKeys(FKeyboardRef, sgDoom);
  LGame := TScriptHostFactory.CreateGameInfo(FGameInfoRef, sgDoom);
  LTextures := TScriptHostFactory.CreateTextures(TFakeTextures.Create);
  LList := TScriptFunctionList.Create('PS_GAME');
  LListRef := LList;
  LGame.Describe(LListRef);
  LTextures.Describe(LListRef);
  LKeys.Describe(LListRef);
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  LExec := TPSExec.Create;
  try
    GUsedList := LList;
    LCompiler.OnUses := OnUsesGameList;
    Assert.IsTrue(LCompiler.Compile(TbtString(SCRIPT_TEXT)), 'compile');
    LCompiler.GetOutput(LBytes);
    LList.RegisterExecutor(LExec);
    Assert.IsTrue(LExec.LoadData(LBytes), 'load');
    Assert.IsTrue(LExec.RunScript, 'run');
    Assert.AreEqual(174, IntegerAt(0));
    Assert.AreEqual(4, IntegerAt(1));
    Assert.AreEqual(64, IntegerAt(2));
    Assert.AreEqual('G(9)', FGameInfo.Calls);
  finally
    LExec.Free;
    LCompiler.Free;
    LListRef := nil;
    LList.Free;
  end;
end;

procedure TTestScriptHostGameSections.DovrebbeTrovareIlGiocoDalNome;
var
  LGame: TScriptGame;
begin
  Assert.IsTrue(TScriptGames.TryFromName('Heretic', LGame));
  Assert.AreEqual(Ord(sgHeretic), Ord(LGame));
  Assert.IsTrue(TScriptGames.TryFromName('STRIFE', LGame));
  Assert.AreEqual(Ord(sgStrife), Ord(LGame));
  Assert.IsFalse(TScriptGames.TryFromName('Speed', LGame));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostGameSections);

end.
