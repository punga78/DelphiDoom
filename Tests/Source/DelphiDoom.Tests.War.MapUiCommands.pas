{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the tables, the state and the cursors  }
{  of the commands of the map                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiCommands;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Model.Intf, DelphiDoom.War.MapUi.CommandCatalog,
  DelphiDoom.War.MapUi.CommandState, DelphiDoom.War.MapUi.CommandCursor, DelphiDoom.War.MapUi.Intf,
  DelphiDoom.War.MapUi.Host;

type
  /// <summary>Writes down what the host asks of the audio: the id of a sound, or the range of a sound drawn</summary>
  TRecordingAudio = class(TInterfacedObject, IWarMapAudio)
  public
    Events: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure PlaySound(AAudioId: Integer);
    procedure PlayRandomSound(AFromId, AToId: Integer);
    procedure Acknowledge(APlayer: Integer);
    procedure DudeSelected(ASlot: Integer);
    procedure BuildingSelected(ASlot: Integer);
  end;

  [TestFixture]
  [Category('war')]
  TTestWarMapUiCommands = class(TObject)
  strict private
    FHost: TWarMapHost;
    FHostRef: IWarModelEvents;
    FAudio: TRecordingAudio;
    FAudioRef: IWarMapAudio;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFareIlSuonoDiOgniMorteEDiOgniCrollo;
    [Test]
    procedure DovrebbeFareIlSuonoDeiColpiEDegliIncantesimi;
    [Test]
    procedure DovrebbeDareITestiELeChiaviDiOgniComando;
    [Test]
    procedure DovrebbeRifiutareUnComandoCheNonEInTabella;
    [Test]
    procedure DovrebbeTrovareIlTipoMappatoEIlComandoDiUnTipo;
    [Test]
    procedure DovrebbeDareIRitrattiELeImmaginiDeiMiglioramenti;
    [Test]
    procedure DovrebbeConsumareELasciareLaSelezioneSoloPerIComandiConUnClic;
    [Test]
    procedure DovrebbeAzzerareIlComando;
    [Test]
    procedure DovrebbeScegliereIlCursoreSullaMappa;
    [Test]
    procedure DovrebbeScegliereIlCursoreSulMinimap;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Ui.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.CommandData.Data,
  DelphiDoom.War.MapUi.UnitNames.Data;

{ TRecordingAudio }

constructor TRecordingAudio.Create;
begin
  inherited Create;
  Events := TStringList.Create;
end;

destructor TRecordingAudio.Destroy;
begin
  Events.Free;
  inherited Destroy;
end;

procedure TRecordingAudio.PlaySound(AAudioId: Integer);
begin
  Events.Add('S' + IntToStr(AAudioId));
end;

procedure TRecordingAudio.PlayRandomSound(AFromId, AToId: Integer);
begin
  Events.Add(Format('R%d-%d', [AFromId, AToId]));
end;

procedure TRecordingAudio.Acknowledge(APlayer: Integer);
begin
  Events.Add('A');
end;

procedure TRecordingAudio.DudeSelected(ASlot: Integer);
begin
  Events.Add('D');
end;

procedure TRecordingAudio.BuildingSelected(ASlot: Integer);
begin
  Events.Add('B');
end;

{ TTestWarMapUiCommands }

procedure TTestWarMapUiCommands.Setup;
begin
  FHost := TWarMapHost.Create(nil);
  FHostRef := FHost;
  FAudio := TRecordingAudio.Create;
  FAudioRef := FAudio;
  FHost.AttachAudio(FAudioRef);
end;

procedure TTestWarMapUiCommands.TearDown;
begin
  FHost.Detach;
  FAudioRef := nil;
  FHostRef := nil;
end;

procedure TTestWarMapUiCommands.DovrebbeFareIlSuonoDiOgniMorteEDiOgniCrollo;
var
  LPosition: TWarVec2;
begin
  LPosition := Default(TWarVec2);
  FHost.UnitDied(1, WAR_UNIT_SPIDER, LPosition);
  FHost.UnitDied(1, WAR_UNIT_SCORPION, LPosition);
  FHost.UnitDied(1, WAR_UNIT_CATAPULT_ORCS, LPosition);
  FHost.UnitDied(1, WAR_UNIT_FOOTMAN, LPosition);
  FHost.UnitDied(1, WAR_UNIT_GRUNT, LPosition);
  FHost.BuildingCollapsing(1, WAR_UNIT_FARM_HUMANS, LPosition);
  FHost.TreeChopped(LPosition);
  Assert.AreEqual('S531,S531,R481-483,S500,S499,R481-483,R477-480', FAudio.Events.CommaText.Replace('"', ''),
    'la morte di un ragno, di uno scorpione, di una catapulta (uno dei crolli), di un uomo, di un orco; il crollo; il legno');
end;

procedure TTestWarMapUiCommands.DovrebbeFareIlSuonoDeiColpiEDegliIncantesimi;
var
  LPosition: TWarVec2;
begin
  LPosition := Default(TWarVec2);
  FHost.AttackSound(LPosition, WAR_ACTION_STEP_SOUND_SWORD);
  FHost.AttackSound(LPosition, WAR_ACTION_STEP_SOUND_FIST);
  FHost.AttackSound(LPosition, WAR_ACTION_STEP_SOUND_FIREBALL);
  FHost.AttackSound(LPosition, WAR_ACTION_STEP_SOUND_CATAPULT);
  FHost.AttackSound(LPosition, WAR_ACTION_STEP_SOUND_ARROW);
  FHost.AttackSound(LPosition, WAR_ACTION_STEP_SOUND_LIGHTNING);
  Assert.AreEqual(5, FAudio.Events.Count, 'il fulmine non ha suono e non fa un''entita''');
  Assert.AreEqual('R487-489', FAudio.Events[0], 'la spada e'' una di tre');
  FAudio.Events.Clear;
  FHost.ArrowHit(LPosition);
  FHost.Explosion(LPosition, False);
  FHost.Explosion(LPosition, True);
  FHost.SpellCast(LPosition);
  FHost.SummonExpired(LPosition, WAR_UNIT_SPIDER);
  Assert.AreEqual('S494,S491,S491,S532,S531', FAudio.Events.CommaText);
  FHost.BuildingDamaged(1, 50);
  Assert.AreEqual(5, FAudio.Events.Count, 'un edificio ferito non suona');
end;

procedure TTestWarMapUiCommands.DovrebbeDareITestiELeChiaviDiOgniComando;
var
  LCommand: Integer;
begin
  for LCommand := 0 to 73 do
    Assert.AreEqual(LCommand, TWarCommandCatalog.Base(LCommand).CommandType, 'la tabella e'' per numero di comando');
  Assert.AreEqual('MOVE', string(TWarCommandCatalog.Base(WAR_CMD_MOVE).Tooltip));
  Assert.IsTrue(TWarCommandCatalog.Base(WAR_CMD_MOVE).HotKey = wkM);
  Assert.AreEqual(3, TWarCommandCatalog.Base(WAR_CMD_CANCEL).HighlightCount);
  Assert.IsTrue(TWarCommandCatalog.Base(WAR_CMD_CANCEL).HotKey = wkEsc);
  Assert.AreEqual('TRAINING A PEASANT', string(TWarCommandCatalog.Base(WAR_CMD_TRAIN_PEASANT).Tooltip2));
  Assert.AreEqual('RESEARCHING WEAPONRY', string(TWarCommandCatalog.Base(WAR_CMD_UPGRADE_SWORDS).Tooltip2));
  // the numbers of the commands of the model are the ones of the original
  Assert.AreEqual(WAR_COMMAND_TRAIN_FIRST, WAR_CMD_TRAIN_FOOTMAN);
  Assert.AreEqual(WAR_COMMAND_BUILD_ROAD, WAR_CMD_BUILD_ROAD);
  Assert.AreEqual(WAR_COMMAND_UPGRADE_LAST, WAR_CMD_UPGRADE_UNHOLY_ARMOR);
  Assert.AreEqual(WAR_COMMAND_CANCEL, WAR_CMD_CANCEL);
end;

procedure TTestWarMapUiCommands.DovrebbeRifiutareUnComandoCheNonEInTabella;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarCommandCatalog.Base(74);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarCommandCatalog.Base(-1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarCommandCatalog.MappedType(WAR_CMD_MOVE);
    end, EWarException, 'muovi non e'' di un tipo di unita'' ne'' di miglioramento');
end;

procedure TTestWarMapUiCommands.DovrebbeTrovareIlTipoMappatoEIlComandoDiUnTipo;
begin
  Assert.AreEqual(WAR_UNIT_FOOTMAN, TWarCommandCatalog.MappedType(WAR_CMD_TRAIN_FOOTMAN));
  Assert.AreEqual(WAR_UPGRADE_SHIELD, TWarCommandCatalog.MappedType(WAR_CMD_UPGRADE_SHIELD_ORCS));
  Assert.AreEqual(WAR_SUMMON_DAEMON, TWarCommandCatalog.MappedType(WAR_CMD_SUMMON_DAEMON));
  Assert.AreEqual(WAR_CMD_TRAIN_PEASANT, TWarCommandCatalog.CommandOfUnit(WAR_UNIT_PEASANT));
  Assert.AreEqual(WAR_CMD_BUILD_FARM_ORCS, TWarCommandCatalog.CommandOfUnit(WAR_UNIT_FARM_ORCS));
  Assert.AreEqual(-1, TWarCommandCatalog.CommandOfUnit(WAR_UNIT_GOLDMINE), 'la miniera non si addestra ne'' si costruisce');
  // the shield is in the table twice: the first one is the one of the humans
  Assert.AreEqual(WAR_CMD_UPGRADE_SHIELD_HUMANS, TWarCommandCatalog.CommandOfUpgrade(WAR_UPGRADE_SHIELD));
  Assert.AreEqual(WAR_CMD_UPGRADE_HORSES, TWarCommandCatalog.CommandOfUpgrade(WAR_UPGRADE_HORSES));
  Assert.AreEqual(-1, TWarCommandCatalog.CommandOfUpgrade(99));
end;

procedure TTestWarMapUiCommands.DovrebbeDareIRitrattiELeImmaginiDeiMiglioramenti;
begin
  Assert.AreEqual(WAR_PORTRAIT_GOLDMINE, TWarCommandCatalog.PortraitOfUnit(WAR_UNIT_GOLDMINE));
  Assert.AreEqual(0, TWarCommandCatalog.PortraitOfUnit(999), 'un tipo che la tabella non ha');
  Assert.AreEqual(WAR_PORTRAIT_SWORD_2, TWarCommandCatalog.UpgradeFrame(WAR_UPGRADE_SWORDS, 0));
  Assert.AreEqual(WAR_PORTRAIT_SWORD_3, TWarCommandCatalog.UpgradeFrame(WAR_UPGRADE_SWORDS, 1));
  Assert.AreEqual(WAR_PORTRAIT_HEALING, TWarCommandCatalog.SpellPortrait(WAR_SPELL_HEALING));
  Assert.AreEqual(WAR_PORTRAIT_DAEMON, TWarCommandCatalog.SpellPortrait(WAR_SUMMON_DAEMON));
end;

procedure TTestWarMapUiCommands.DovrebbeConsumareELasciareLaSelezioneSoloPerIComandiConUnClic;
var
  LState: TWarMapCommandState;
  LType: Integer;
begin
  LState := TWarMapCommandState.Create;
  try
    Assert.IsFalse(LState.Pending);
    for LType in [WAR_COMMAND_MOVE, WAR_COMMAND_HARVEST, WAR_COMMAND_REPAIR, WAR_COMMAND_ATTACK, WAR_COMMAND_SPELL_HEALING,
      WAR_COMMAND_SPELL_UNHOLY_ARMOR, WAR_COMMAND_BUILD_FIRST, WAR_COMMAND_BUILD_ROAD, WAR_COMMAND_BUILD_WALL] do
    begin
      LState.CommandType := LType;
      Assert.IsTrue(LState.Pending);
      LState.Consume;
      Assert.IsFalse(LState.Pending);
      Assert.IsTrue(LState.SuppressSelectionOnRelease, 'un clic ha dato l''ordine: ' + IntToStr(LType));
      LState.SuppressSelectionOnRelease := False;
    end;
    for LType in [WAR_COMMAND_STOP, WAR_COMMAND_DELIVER, WAR_COMMAND_TRAIN_FIRST, WAR_COMMAND_UPGRADE_FIRST,
      WAR_COMMAND_SUMMON_SPIDER, WAR_COMMAND_CANCEL] do
    begin
      LState.CommandType := LType;
      LState.Consume;
      Assert.IsFalse(LState.SuppressSelectionOnRelease, 'nessun clic: ' + IntToStr(LType));
    end;
  finally
    LState.Free;
  end;
end;

procedure TTestWarMapUiCommands.DovrebbeAzzerareIlComando;
var
  LState: TWarMapCommandState;
begin
  LState := TWarMapCommandState.Create;
  try
    LState.CommandType := WAR_COMMAND_ATTACK;
    LState.Clear;
    Assert.IsFalse(LState.Pending);
    Assert.AreEqual(WAR_COMMAND_NONE, LState.CommandType);
  finally
    LState.Free;
  end;
end;

procedure TTestWarMapUiCommands.DovrebbeScegliereIlCursoreSullaMappa;
begin
  Assert.AreEqual(WAR_CURSOR_RED_CROSSHAIR, TWarCommandCursor.OverMap(WAR_COMMAND_ATTACK));
  Assert.AreEqual(WAR_CURSOR_RED_CROSSHAIR, TWarCommandCursor.OverMap(WAR_COMMAND_SPELL_POISON_CLOUD));
  Assert.AreEqual(WAR_CURSOR_YELLOW_CROSSHAIR, TWarCommandCursor.OverMap(WAR_COMMAND_MOVE));
  Assert.AreEqual(WAR_CURSOR_YELLOW_CROSSHAIR, TWarCommandCursor.OverMap(WAR_COMMAND_SPELL_FAR_SIGHT));
  Assert.AreEqual(WAR_CURSOR_ARROW, TWarCommandCursor.OverMap(WAR_COMMAND_BUILD_WALL));
  Assert.AreEqual(WAR_CURSOR_ARROW, TWarCommandCursor.OverMap(WAR_COMMAND_BUILD_FIRST));
  Assert.AreEqual(-1, TWarCommandCursor.OverMap(WAR_COMMAND_NONE), 'nessun comando: dipende da cio'' che sta sotto');
  Assert.AreEqual(-1, TWarCommandCursor.OverMap(WAR_COMMAND_BUILD_BASIC), 'i menu non scelgono il cursore');
end;

procedure TTestWarMapUiCommands.DovrebbeScegliereIlCursoreSulMinimap;
begin
  Assert.AreEqual(WAR_CURSOR_RED_CROSSHAIR, TWarCommandCursor.OverMinimap(WAR_COMMAND_SPELL_RAIN_OF_FIRE));
  Assert.AreEqual(WAR_CURSOR_YELLOW_CROSSHAIR, TWarCommandCursor.OverMinimap(WAR_COMMAND_MOVE));
  Assert.AreEqual(WAR_CURSOR_YELLOW_CROSSHAIR, TWarCommandCursor.OverMinimap(WAR_COMMAND_SPELL_DARK_VISION));
  Assert.AreEqual(WAR_CURSOR_ARROW, TWarCommandCursor.OverMinimap(WAR_COMMAND_REPAIR));
  Assert.AreEqual(WAR_CURSOR_ARROW, TWarCommandCursor.OverMinimap(WAR_COMMAND_NONE));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiCommands);

end.
