{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the player functions of PS_GAME                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Players;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Players.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  /// <summary>Four players (the third is not in the game), 5 keys, 3 artifacts, 4 weapons, 3 kinds of ammunition, 6 powers</summary>
  TFakePlayerSource = class(TInterfacedObject, IScriptPlayerSource)
  public
    Keys: array[0..3, 0..4] of Boolean;
    Weapons: array[0..3, 0..3] of Boolean;
    Reserves: array[0..3, 0..2] of Integer;
    Powers: array[0..3, 0..5] of Integer;
    Messages: array[0..3] of string;
    Lights: array[0..3] of Integer;
    Quests: array[0..3] of Cardinal;
    ActorKeys: array[0..3] of Cardinal;
    /// <summary>What the source was asked to do, as text</summary>
    Calls: string;
    constructor Create;
    function MaxPlayers: Integer;
    function InGame(const APlayer: Integer): Boolean;
    function KeyCount: Integer;
    function HasKey(const APlayer: Integer; const AKey: Integer): Boolean;
    procedure SetKey(const APlayer: Integer; const AKey: Integer; const AValue: Boolean);
    function ArtifactCount: Integer;
    procedure UseArtifact(const APlayer: Integer; const AArtifact: Integer);
    function GiveArtifact(const APlayer: Integer; const AArtifact: Integer): Boolean;
    function ArtifactAmount(const APlayer: Integer; const AArtifact: Integer): Integer;
    function WeaponCount: Integer;
    function HasWeapon(const APlayer: Integer; const AWeapon: Integer): Boolean;
    procedure GiveWeapon(const APlayer: Integer; const AWeapon: Integer);
    function ReserveCount: Integer;
    function Reserve(const APlayer: Integer; const AKind: Integer): Integer;
    procedure SetReserve(const APlayer: Integer; const AKind: Integer; const AValue: Integer);
    function PlayerClass(const APlayer: Integer): Integer;
    function Message(const APlayer: Integer): string;
    procedure SetMessage(const APlayer: Integer; const AText: string);
    function ExtraLight(const APlayer: Integer): Integer;
    procedure SetExtraLight(const APlayer: Integer; const AValue: Integer);
    function PowerCount: Integer;
    function PowerTicks(const APlayer: Integer; const APower: Integer): Integer;
    procedure SetPowerTicks(const APlayer: Integer; const APower: Integer; const ATicks: Integer);
    function ViewZ(const APlayer: Integer): Integer;
    function ViewHeight(const APlayer: Integer): Integer;
    function ActorKey(const APlayer: Integer): Cardinal;
    function ConsolePlayer: Integer;
    function QuestFlags(const APlayer: Integer): Cardinal;
    procedure SetQuestFlags(const APlayer: Integer; const AFlags: Cardinal);
    procedure FaceActor(const APlayer: Integer; const AActorKey: Cardinal; const ATicks: Integer);
  end;

  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostPlayers = class(TObject)
  strict private
    FSource: TFakePlayerSource;
    FSourceRef: IScriptPlayerSource;
    FPlayers: IScriptPlayers;
    FTables: TList<IScriptFunctionTable>;
    function DescribeFor(const AGame: TScriptGame): TFakeFunctionTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDeiGiocatoriDiDoom;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDeiGiocatoriDiStrifeConLeMissioni;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDeiGiocatoriDiHereticConGliArtefatti;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDeiGiocatoriDiHexenConManaEClasse;
    [Test]
    procedure DovrebbeDescrivereIGiocatoriNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeUsareLaStessaFunzioneConIlNomeDiCartaEDiChiave;
    [Test]
    procedure DovrebbeDireSeUnGiocatoreEInGioco;
    [Test]
    procedure DovrebbeLeggereEScrivereLeChiavi;
    [Test]
    procedure DovrebbeNonToccareLeChiaviDiUnGiocatoreOUnIndiceNonValido;
    [Test]
    procedure DovrebbeUsareEDareUnArtefatto;
    [Test]
    procedure DovrebbeContareUnArtefatto;
    [Test]
    procedure DovrebbeConservareIlDifettoDellArmaCheSiPuoSoloDare;
    [Test]
    procedure DovrebbeLeggereLeArmiEDareFalsoPerUnIndiceNonValido;
    [Test]
    procedure DovrebbeLeggereEScrivereMunizioniOMana;
    [Test]
    procedure DovrebbeDareLaClasseDelGiocatore;
    [Test]
    procedure DovrebbeLeggereEScrivereMessaggioELuceExtra;
    [Test]
    procedure DovrebbeLeggereEScrivereIPoteri;
    [Test]
    procedure DovrebbeLeggereLaVistaDelGiocatore;
    [Test]
    procedure DovrebbeDareLAttoreDelGiocatoreOIlNumeroNonValido;
    [Test]
    procedure DovrebbeDareIlGiocatoreDellaConsole;
    [Test]
    procedure DovrebbeControllareImpostareEToglierLeMissioni;
    [Test]
    procedure DovrebbeFarGuardareUnAttoreSoloConTicPositivi;
    [Test]
    procedure DovrebbeDareValoriNeutriPerUnGiocatoreFuoriDalGioco;
    [Test]
    procedure DovrebbeDareErroreSeLaSorgenteEnil;
    [Test]
    procedure DovrebbeChiamareLeFunzioniDaUnoScriptVero;
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
  DelphiDoom.ScriptHost.World.Intf;

var
  GUsedList: TScriptFunctionList;

function OnUsesPlayerList(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
  if Result then
  begin
    Sender.AddTypeS('fixed_t', 'Integer');
    GUsedList.RegisterCompiler(Sender);
  end;
end;

{ TFakePlayerSource }

constructor TFakePlayerSource.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to 3 do
  begin
    Messages[LIndex] := Format('msg%d', [LIndex]);
    Lights[LIndex] := 10 + LIndex;
    ActorKeys[LIndex] := 500 + LIndex;
    Reserves[LIndex, 1] := 70 + LIndex;
    Powers[LIndex, 2] := 33 + LIndex;
  end;
  ActorKeys[3] := Cardinal(SCRIPT_INVALID_ID);
  Keys[1, 2] := True;
  Weapons[1, 1] := True;
  Quests[1] := 5;
end;

function TFakePlayerSource.MaxPlayers: Integer;
begin
  Result := 4;
end;

function TFakePlayerSource.InGame(const APlayer: Integer): Boolean;
begin
  Result := APlayer <> 2;
end;

function TFakePlayerSource.KeyCount: Integer;
begin
  Result := 5;
end;

function TFakePlayerSource.HasKey(const APlayer: Integer; const AKey: Integer): Boolean;
begin
  Result := Keys[APlayer, AKey];
end;

procedure TFakePlayerSource.SetKey(const APlayer: Integer; const AKey: Integer; const AValue: Boolean);
begin
  Keys[APlayer, AKey] := AValue;
end;

function TFakePlayerSource.ArtifactCount: Integer;
begin
  Result := 3;
end;

procedure TFakePlayerSource.UseArtifact(const APlayer: Integer; const AArtifact: Integer);
begin
  Calls := Calls + Format('U(%d,%d)', [APlayer, AArtifact]);
end;

function TFakePlayerSource.GiveArtifact(const APlayer: Integer; const AArtifact: Integer): Boolean;
begin
  Calls := Calls + Format('G(%d,%d)', [APlayer, AArtifact]);
  Result := AArtifact <> 1;
end;

function TFakePlayerSource.ArtifactAmount(const APlayer: Integer; const AArtifact: Integer): Integer;
begin
  Result := 10 * APlayer + AArtifact;
end;

function TFakePlayerSource.WeaponCount: Integer;
begin
  Result := 4;
end;

function TFakePlayerSource.HasWeapon(const APlayer: Integer; const AWeapon: Integer): Boolean;
begin
  Result := Weapons[APlayer, AWeapon];
end;

procedure TFakePlayerSource.GiveWeapon(const APlayer: Integer; const AWeapon: Integer);
begin
  Weapons[APlayer, AWeapon] := True;
end;

function TFakePlayerSource.ReserveCount: Integer;
begin
  Result := 3;
end;

function TFakePlayerSource.Reserve(const APlayer: Integer; const AKind: Integer): Integer;
begin
  Result := Reserves[APlayer, AKind];
end;

procedure TFakePlayerSource.SetReserve(const APlayer: Integer; const AKind: Integer; const AValue: Integer);
begin
  Reserves[APlayer, AKind] := AValue;
end;

function TFakePlayerSource.PlayerClass(const APlayer: Integer): Integer;
begin
  Result := 2 + APlayer;
end;

function TFakePlayerSource.Message(const APlayer: Integer): string;
begin
  Result := Messages[APlayer];
end;

procedure TFakePlayerSource.SetMessage(const APlayer: Integer; const AText: string);
begin
  Messages[APlayer] := AText;
end;

function TFakePlayerSource.ExtraLight(const APlayer: Integer): Integer;
begin
  Result := Lights[APlayer];
end;

procedure TFakePlayerSource.SetExtraLight(const APlayer: Integer; const AValue: Integer);
begin
  Lights[APlayer] := AValue;
end;

function TFakePlayerSource.PowerCount: Integer;
begin
  Result := 6;
end;

function TFakePlayerSource.PowerTicks(const APlayer: Integer; const APower: Integer): Integer;
begin
  Result := Powers[APlayer, APower];
end;

procedure TFakePlayerSource.SetPowerTicks(const APlayer: Integer; const APower: Integer;
  const ATicks: Integer);
begin
  Powers[APlayer, APower] := ATicks;
end;

function TFakePlayerSource.ViewZ(const APlayer: Integer): Integer;
begin
  Result := 41 * 65536 + APlayer;
end;

function TFakePlayerSource.ViewHeight(const APlayer: Integer): Integer;
begin
  Result := 41 * 65536 - APlayer;
end;

function TFakePlayerSource.ActorKey(const APlayer: Integer): Cardinal;
begin
  Result := ActorKeys[APlayer];
end;

function TFakePlayerSource.ConsolePlayer: Integer;
begin
  Result := 1;
end;

function TFakePlayerSource.QuestFlags(const APlayer: Integer): Cardinal;
begin
  Result := Quests[APlayer];
end;

procedure TFakePlayerSource.SetQuestFlags(const APlayer: Integer; const AFlags: Cardinal);
begin
  Quests[APlayer] := AFlags;
end;

procedure TFakePlayerSource.FaceActor(const APlayer: Integer; const AActorKey: Cardinal;
  const ATicks: Integer);
begin
  Calls := Calls + Format('F(%d,%d,%d)', [APlayer, AActorKey, ATicks]);
end;

{ TTestScriptHostPlayers }

procedure TTestScriptHostPlayers.Setup;
begin
  FSource := TFakePlayerSource.Create;
  FSourceRef := FSource;
  FPlayers := TScriptHostFactory.CreatePlayers(FSourceRef, sgDoom);
  FTables := TList<IScriptFunctionTable>.Create;
end;

procedure TTestScriptHostPlayers.TearDown;
begin
  FTables.Free;
  FPlayers := nil;
  FSourceRef := nil;
  FSource := nil;
end;

function TTestScriptHostPlayers.DescribeFor(const AGame: TScriptGame): TFakeFunctionTable;
var
  LRef: IScriptFunctionTable;
begin
  Result := TFakeFunctionTable.Create;
  LRef := Result;
  FTables.Add(LRef);
  TScriptHostFactory.CreatePlayers(FSourceRef, AGame).Describe(LRef);
end;

procedure TTestScriptHostPlayers.DovrebbeDescrivereLeFunzioniDeiGiocatoriDiDoom;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgDoom);
  Assert.AreEqual(19, LTable.Declarations.Count);
  Assert.IsTrue(LTable.Declarations.IndexOf(
    'procedure PlayerFaceMobj(const plnum: integer; const actor: LongWord; const ticks: integer);') >= 0);
  Assert.IsTrue(LTable.Declarations.IndexOf(
    'procedure SetPlayerAmmo(const plnum: integer; const ammotype: integer; const value: integer);') >= 0);
  Assert.AreEqual(-1, LTable.Declarations.IndexOf(
    'procedure PlayerUseArtifact(const plnum: Integer; const arti: Integer);'));
  Assert.AreEqual('function ConsolePlayer: Integer;', LTable.Declarations[LTable.Declarations.Count - 1]);
end;

procedure TTestScriptHostPlayers.DovrebbeDescrivereLeFunzioniDeiGiocatoriDiStrifeConLeMissioni;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgStrife);
  Assert.AreEqual(22, LTable.Declarations.Count);
  Assert.AreEqual('procedure UnSetPlayerQuest(const plnum: Integer; const quest: LongWord);',
    LTable.Declarations[LTable.Declarations.Count - 1]);
  Assert.IsTrue(LTable.Declarations.IndexOf(
    'procedure PlayerFaceMobj(const plnum: integer; const actor: LongWord; const ticks: integer);') >= 0);
end;

procedure TTestScriptHostPlayers.DovrebbeDescrivereLeFunzioniDeiGiocatoriDiHereticConGliArtefatti;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgHeretic);
  Assert.AreEqual(21, LTable.Declarations.Count);
  Assert.IsTrue(LTable.Declarations.IndexOf(
    'function CheckPlayerArtifact(const plnum: Integer; const arti: Integer): Integer;') >= 0);
  Assert.AreEqual(-1, LTable.Declarations.IndexOf(
    'procedure PlayerFaceMobj(const plnum: integer; const actor: LongWord; const ticks: integer);'));
  Assert.IsTrue(LTable.Declarations.IndexOf(
    'procedure SetPlayerAmmo(const plnum: integer; const ammotype: integer; const value: integer);') >= 0);
end;

procedure TTestScriptHostPlayers.DovrebbeDescrivereLeFunzioniDeiGiocatoriDiHexenConManaEClasse;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgHexen);
  Assert.AreEqual(22, LTable.Declarations.Count);
  Assert.IsTrue(LTable.Declarations.IndexOf('function GetPlayerClass(const plnum: Integer): Integer;') >= 0);
  Assert.IsTrue(LTable.Declarations.IndexOf(
    'procedure SetPlayerMana(const plnum: integer; const mana: integer; const value: integer);') >= 0);
  Assert.AreEqual(-1, LTable.Declarations.IndexOf(
    'procedure SetPlayerAmmo(const plnum: integer; const ammotype: integer; const value: integer);'));
end;

procedure TTestScriptHostPlayers.DovrebbeDescrivereIGiocatoriNellOrdineDelVecchioCodice;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgDoom);
  Assert.AreEqual('function PlayerInGame(const plnum: integer): boolean;', LTable.Declarations[0]);
  Assert.AreEqual(
    'procedure PlayerFaceMobj(const plnum: integer; const actor: LongWord; const ticks: integer);',
    LTable.Declarations[1]);
  Assert.AreEqual(
    'procedure SetPlayerHasCard(const plnum: integer; const card: integer; const value: boolean);',
    LTable.Declarations[2]);
  Assert.AreEqual('function GetPlayerHasKey(const plnum: integer; const key: integer): boolean;',
    LTable.Declarations[5]);
  Assert.AreEqual('procedure SetPlayerHasWeapon(const plnum: integer; const weapon: integer; const value: boolean);',
    LTable.Declarations[6]);
  Assert.AreEqual('procedure SetPlayerMessage(const plnum: integer; const msg: string);',
    LTable.Declarations[10]);
end;

procedure TTestScriptHostPlayers.DovrebbeUsareLaStessaFunzioneConIlNomeDiCartaEDiChiave;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgDoom);
  Assert.AreEqual(LTable.Codes[2], LTable.Codes[4]);
  Assert.AreEqual(LTable.Codes[3], LTable.Codes[5]);
  LTable := DescribeFor(sgHexen);
  Assert.AreEqual(LTable.Codes[1], LTable.Codes[3]);
  Assert.AreEqual(LTable.Codes[2], LTable.Codes[4]);
end;

procedure TTestScriptHostPlayers.DovrebbeDireSeUnGiocatoreEInGioco;
begin
  Assert.IsTrue(FPlayers.PlayerInGame(0));
  Assert.IsTrue(FPlayers.PlayerInGame(3));
  Assert.IsFalse(FPlayers.PlayerInGame(2));
  Assert.IsFalse(FPlayers.PlayerInGame(4));
  Assert.IsFalse(FPlayers.PlayerInGame(-1));
end;

procedure TTestScriptHostPlayers.DovrebbeLeggereEScrivereLeChiavi;
begin
  Assert.IsTrue(FPlayers.GetPlayerHasKey(1, 2));
  Assert.IsFalse(FPlayers.GetPlayerHasKey(1, 3));
  FPlayers.SetPlayerHasKey(0, 4, True);
  Assert.IsTrue(FSource.Keys[0, 4]);
  FPlayers.SetPlayerHasKey(0, 4, False);
  Assert.IsFalse(FSource.Keys[0, 4]);
end;

procedure TTestScriptHostPlayers.DovrebbeNonToccareLeChiaviDiUnGiocatoreOUnIndiceNonValido;
begin
  FPlayers.SetPlayerHasKey(2, 1, True);
  FPlayers.SetPlayerHasKey(0, 5, True);
  FPlayers.SetPlayerHasKey(0, -1, True);
  Assert.IsFalse(FSource.Keys[2, 1]);
  Assert.IsFalse(FSource.Keys[0, 0]);
  Assert.IsFalse(FPlayers.GetPlayerHasKey(2, 2));
  Assert.IsFalse(FPlayers.GetPlayerHasKey(0, 5));
end;

procedure TTestScriptHostPlayers.DovrebbeUsareEDareUnArtefatto;
begin
  FPlayers.PlayerUseArtifact(1, 2);
  FPlayers.PlayerUseArtifact(1, 3);
  FPlayers.PlayerUseArtifact(2, 0);
  Assert.IsTrue(FPlayers.GiveArtifactToPlayer(0, 0));
  Assert.IsFalse(FPlayers.GiveArtifactToPlayer(0, 1));
  Assert.IsFalse(FPlayers.GiveArtifactToPlayer(0, 3));
  Assert.IsFalse(FPlayers.GiveArtifactToPlayer(2, 0));
  Assert.AreEqual('U(1,2)G(0,0)G(0,1)', FSource.Calls);
end;

procedure TTestScriptHostPlayers.DovrebbeContareUnArtefatto;
begin
  Assert.AreEqual(12, FPlayers.CheckPlayerArtifact(1, 2));
  Assert.AreEqual(0, FPlayers.CheckPlayerArtifact(1, 3));
  Assert.AreEqual(0, FPlayers.CheckPlayerArtifact(2, 0));
end;

procedure TTestScriptHostPlayers.DovrebbeConservareIlDifettoDellArmaCheSiPuoSoloDare;
begin
  FPlayers.SetPlayerHasWeapon(0, 2, True);
  Assert.IsTrue(FSource.Weapons[0, 2]);
  // the old code ignored the value: a weapon is given even when the script says false
  FPlayers.SetPlayerHasWeapon(0, 3, False);
  Assert.IsTrue(FSource.Weapons[0, 3]);
  FPlayers.SetPlayerHasWeapon(1, 1, False);
  Assert.IsTrue(FSource.Weapons[1, 1]);
end;

procedure TTestScriptHostPlayers.DovrebbeLeggereLeArmiEDareFalsoPerUnIndiceNonValido;
begin
  Assert.IsTrue(FPlayers.GetPlayerHasWeapon(1, 1));
  Assert.IsFalse(FPlayers.GetPlayerHasWeapon(1, 0));
  Assert.IsFalse(FPlayers.GetPlayerHasWeapon(1, 4));
  Assert.IsFalse(FPlayers.GetPlayerHasWeapon(2, 1));
  FPlayers.SetPlayerHasWeapon(0, 4, True);
  FPlayers.SetPlayerHasWeapon(2, 0, True);
  Assert.IsFalse(FSource.Weapons[0, 0]);
  Assert.IsFalse(FSource.Weapons[2, 0]);
end;

procedure TTestScriptHostPlayers.DovrebbeLeggereEScrivereMunizioniOMana;
begin
  Assert.AreEqual(71, FPlayers.GetPlayerReserve(1, 1));
  FPlayers.SetPlayerReserve(0, 2, 99);
  Assert.AreEqual(99, FSource.Reserves[0, 2]);
  FPlayers.SetPlayerReserve(0, 3, 1);
  FPlayers.SetPlayerReserve(2, 0, 1);
  Assert.AreEqual(0, FSource.Reserves[2, 0]);
  Assert.AreEqual(0, FPlayers.GetPlayerReserve(1, 3));
  Assert.AreEqual(0, FPlayers.GetPlayerReserve(2, 1));
end;

procedure TTestScriptHostPlayers.DovrebbeDareLaClasseDelGiocatore;
begin
  Assert.AreEqual(3, FPlayers.GetPlayerClass(1));
  Assert.AreEqual(0, FPlayers.GetPlayerClass(2));
  Assert.AreEqual(0, FPlayers.GetPlayerClass(9));
end;

procedure TTestScriptHostPlayers.DovrebbeLeggereEScrivereMessaggioELuceExtra;
begin
  Assert.AreEqual('msg1', FPlayers.GetPlayerMessage(1));
  FPlayers.SetPlayerMessage(1, 'ciao');
  Assert.AreEqual('ciao', FSource.Messages[1]);
  Assert.AreEqual('', FPlayers.GetPlayerMessage(2));
  FPlayers.SetPlayerMessage(2, 'no');
  Assert.AreEqual('msg2', FSource.Messages[2]);
  Assert.AreEqual(11, FPlayers.GetPlayerExtraLight(1));
  FPlayers.SetPlayerExtraLight(1, 5);
  Assert.AreEqual(5, FSource.Lights[1]);
  Assert.AreEqual(0, FPlayers.GetPlayerExtraLight(2));
  FPlayers.SetPlayerExtraLight(2, 7);
  Assert.AreEqual(12, FSource.Lights[2]);
end;

procedure TTestScriptHostPlayers.DovrebbeLeggereEScrivereIPoteri;
begin
  Assert.AreEqual(34, FPlayers.GetPlayerPowerTicks(1, 2));
  FPlayers.SetPlayerPowerTicks(1, 5, 350);
  Assert.AreEqual(350, FSource.Powers[1, 5]);
  FPlayers.SetPlayerPowerTicks(1, 6, 1);
  FPlayers.SetPlayerPowerTicks(1, -1, 1);
  FPlayers.SetPlayerPowerTicks(2, 0, 1);
  Assert.AreEqual(0, FSource.Powers[2, 0]);
  Assert.AreEqual(0, FPlayers.GetPlayerPowerTicks(1, 6));
  Assert.AreEqual(0, FPlayers.GetPlayerPowerTicks(2, 2));
end;

procedure TTestScriptHostPlayers.DovrebbeLeggereLaVistaDelGiocatore;
begin
  Assert.AreEqual(41 * 65536 + 1, FPlayers.GetPlayerViewZ(1));
  Assert.AreEqual(41 * 65536 - 1, FPlayers.GetPlayerViewHeight(1));
  Assert.AreEqual(0, FPlayers.GetPlayerViewZ(2));
  Assert.AreEqual(0, FPlayers.GetPlayerViewHeight(-1));
end;

procedure TTestScriptHostPlayers.DovrebbeDareLAttoreDelGiocatoreOIlNumeroNonValido;
begin
  Assert.AreEqual(Cardinal(501), FPlayers.GetPlayerActor(1));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FPlayers.GetPlayerActor(3));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FPlayers.GetPlayerActor(2));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FPlayers.GetPlayerActor(8));
end;

procedure TTestScriptHostPlayers.DovrebbeDareIlGiocatoreDellaConsole;
begin
  Assert.AreEqual(1, FPlayers.ConsolePlayer);
end;

procedure TTestScriptHostPlayers.DovrebbeControllareImpostareEToglierLeMissioni;
begin
  Assert.IsTrue(FPlayers.CheckPlayerQuest(1, 4));
  Assert.IsFalse(FPlayers.CheckPlayerQuest(1, 2));
  FPlayers.SetPlayerQuest(1, 8);
  Assert.AreEqual(Cardinal(13), FSource.Quests[1]);
  FPlayers.UnSetPlayerQuest(1, 1);
  Assert.AreEqual(Cardinal(12), FSource.Quests[1]);
  Assert.IsFalse(FPlayers.CheckPlayerQuest(2, 4));
  FPlayers.SetPlayerQuest(2, 8);
  FPlayers.UnSetPlayerQuest(2, 8);
  Assert.AreEqual(Cardinal(0), FSource.Quests[2]);
end;

procedure TTestScriptHostPlayers.DovrebbeFarGuardareUnAttoreSoloConTicPositivi;
begin
  FPlayers.PlayerFaceMobj(1, 77, 35);
  FPlayers.PlayerFaceMobj(1, 77, 0);
  FPlayers.PlayerFaceMobj(1, 77, -5);
  FPlayers.PlayerFaceMobj(2, 77, 35);
  FPlayers.PlayerFaceMobj(9, 77, 35);
  Assert.AreEqual('F(1,77,35)', FSource.Calls);
end;

procedure TTestScriptHostPlayers.DovrebbeDareValoriNeutriPerUnGiocatoreFuoriDalGioco;
begin
  Assert.IsFalse(FPlayers.GetPlayerHasKey(2, 0));
  Assert.IsFalse(FPlayers.CheckPlayerQuest(2, 1));
  Assert.AreEqual(0, FPlayers.CheckPlayerArtifact(2, 0));
  Assert.AreEqual('', FPlayers.GetPlayerMessage(-1));
end;

procedure TTestScriptHostPlayers.DovrebbeDareErroreSeLaSorgenteEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreatePlayers(nil, sgDoom);
    end,
    EArgumentNilException);
end;

procedure TTestScriptHostPlayers.DovrebbeChiamareLeFunzioniDaUnoScriptVero;
const
  SCRIPT_TEXT =
    'var ing, hk, ps, cn: Integer; msg: string; w: Boolean;'#13#10 +
    'begin'#13#10 +
    '  if PlayerInGame(1) then ing := 1 else ing := 0;'#13#10 +
    '  if GetPlayerHasCard(1, 2) then hk := 1 else hk := 0;'#13#10 +
    '  SetPlayerHasKey(0, 3, true);'#13#10 +
    '  ps := GetPlayerPowerTicks(1, 2);'#13#10 +
    '  cn := ConsolePlayer;'#13#10 +
    '  msg := GetPlayerMessage(1);'#13#10 +
    '  SetPlayerAmmo(0, 1, 9);'#13#10 +
    'end.';
var
  LList: TScriptFunctionList;
  LListRef: IScriptFunctionTable;
  LCompiler: TPSPascalCompiler;
  LExec: TPSExec;
  LBytes: TbtString;
  LRun: Integer;

  function IntegerAt(const AIndex: Integer): Integer;
  var
    LVariable: PIFVariant;
  begin
    LVariable := LExec.GetVarNo(AIndex);
    Result := PSGetInt(@PPSVariantData(LVariable).Data, LVariable.FType);
  end;

begin
  LList := TScriptFunctionList.Create('PS_GAME');
  LListRef := LList;
  FPlayers.Describe(LListRef);
  try
    // the interpreters come and go while the section lives (the engine runs one script after the other)
    for LRun := 1 to 3 do
    begin
      LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
      LExec := TPSExec.Create;
      try
        GUsedList := LList;
        LCompiler.OnUses := OnUsesPlayerList;
        Assert.IsTrue(LCompiler.Compile(TbtString(SCRIPT_TEXT)), 'compile');
        LCompiler.GetOutput(LBytes);
        LList.RegisterExecutor(LExec);
        Assert.IsTrue(LExec.LoadData(LBytes), 'load');
        Assert.IsTrue(LExec.RunScript, 'run');
        Assert.AreEqual(1, IntegerAt(0));
        Assert.AreEqual(1, IntegerAt(1));
        Assert.AreEqual(34, IntegerAt(2));
        Assert.AreEqual(1, IntegerAt(3));
        Assert.IsTrue(FSource.Keys[0, 3]);
        Assert.AreEqual(9, FSource.Reserves[0, 1]);
      finally
        LExec.Free;
        LCompiler.Free;
      end;
    end;
  finally
    LListRef := nil;
    LList.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostPlayers);

end.
