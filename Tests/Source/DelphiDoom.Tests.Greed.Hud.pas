{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the inventory, the status bar and   }
{  the head up display, and their parity with the original on the pixels        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Hud;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Inventory, DelphiDoom.Greed.Hud, DelphiDoom.Tests.Greed.HudScenarios;

type
  /// <summary>The parts of the game the inventory calls, with what they were asked</summary>
  TInventoryGameFake = class(TInterfacedObject, IGreedSpawner, IGreedGameSound, IGreedPlayerHealth,
    IGreedMessages)
  public
    SpawnValues: TArray<Integer>;
    SpawnAngles: TArray<Integer>;
    LastSpawnId: Integer;
    LastActive: Boolean;
    Sounds: TArray<Integer>;
    MedPakAmount: Integer;
    HealAmount: Integer;
    Messages: TArray<string>;
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure Hurt(AAmount: Integer);
    procedure Heal(AAmount: Integer);
    procedure MedPaks(AAmount: Integer);
    procedure AddScore(AAmount: Integer);
    procedure WriteMessage(const AText: string);
    function LastMessage: string;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedInventory = class(TObject)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FGame: TInventoryGameFake;
    FGameIntf: IGreedSpawner;
    FInventory: TGreedInventory;
    procedure Choose(AKind, ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeNonAvereNullaDaSceglierSeVuoto;
    [Test]
    procedure DovrebbeAndareAlProssimoOggettoPossedutoFacendoIlGiro;
    [Test]
    procedure DovrebbeAndareAlPrecedenteFacendoIlGiro;
    [Test]
    procedure DovrebbeUsareIlMedtubeSoloSeFerito;
    [Test]
    procedure DovrebbeUsareLaCaricaDelloScudoSoloSeServe;
    [Test]
    procedure DovrebbeChiedereLaGranataELanciarlaDopo;
    [Test]
    procedure DovrebbeAvviareLEffettoUnaVoltaSola;
    [Test]
    procedure DovrebbePosareMineEControfigureDoveSiTrovaIlGiocatore;
    [Test]
    procedure DovrebbePrendereLaFiguraDelloSpriteFermoPiuVicino;
    [Test]
    procedure DovrebbeFallireLOloSenzaSpriteFermi;
    [Test]
    procedure DovrebbeSoloSegnalareIlWarpJammer;
    [Test]
    procedure DovrebbeSparareSediciProiettiliConIlSoulStealer;
    [Test]
    procedure DovrebbePassareAlProssimoOggettoFinitoQuelloScelto;
    [Test]
    procedure DovrebbeNonFareNullaSenzaOggettoScelto;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedHud = class(TObject)
  strict private
    FArchive: IGreedArchive;
    FRunner: THudLibraryRunner;
    function Hud: TGreedHud;
    function State: TGreedGameState;
    function Canvas: TGreedCanvas;
    function CountPixels: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeAzzerareCioCheHaDisegnato;
    [Test]
    procedure DovrebbeCambiareLaDimensioneDellaVistaTraZeroEQuattro;
    [Test]
    procedure DovrebbeNonDisegnareBarraADimensioneZero;
    [Test]
    procedure DovrebbeDisegnareLaBarraAlSuoPostoSaltandoLoZero;
    [Test]
    procedure DovrebbeDisegnareLaBarraInAltoSoloADimensioneQuattro;
    [Test]
    procedure DovrebbeMostrareLOggettoSceltoPerUnPoADimensioneZero;
    [Test]
    procedure DovrebbeMuovereIlCursoreDelBattitoColTempo;
    [Test]
    procedure DovrebbeChiedereUnAltroObiettivoQuandoCompareIlBonus;
    [Test]
    procedure DovrebbeSollevarePerUnaModalitaMappaSconosciuta;
    [Test]
    procedure DovrebbeDisegnareIlSensoreDiCaloreNelRiquadro;
    [Test]
    procedure DovrebbeSegnareGliSpriteViviNelSensoreDiMovimento;
    [Test]
    procedure DovrebbeDisegnareLaFrecciaAlCentroDellaMappa;
    [Test]
    procedure DovrebbeDisegnareIlRiquadroDellaVistaPosteriore;
    [Test]
    procedure DovrebbeRifiutareUnaVistaPosterioreCorta;
    [Test]
    procedure DovrebbeDisegnareLOloSoloSeIndossato;
    [Test]
    procedure DovrebbeOffrireIMetodiDegliHostDelLivello;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedHudParity = class(TObject)
  strict private
    procedure CheckGolden(const AArchive: IGreedArchive; const AGoldenName: string);
  public
    [Test]
    procedure DovrebbeDareGliStessiPixelDelloOriginaleSuiDatiSintetici;
    [Test]
    procedure DovrebbeDareGliStessiPixelDelloOriginaleNelGiocoCompleto;
    [Test]
    procedure DovrebbeDareGliStessiPixelDelloOriginaleNellaDemo20;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Elevator.Intf, DelphiDoom.Tests.Greed.RealData, DelphiDoom.Tests.Shared.Skip;

{ TInventoryGameFake }

function TInventoryGameFake.SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle,
  AAngle2: Integer; AActive: Boolean; ASpawnId: Integer): Integer;
begin
  SpawnValues := SpawnValues + [AValue];
  SpawnAngles := SpawnAngles + [AAngle];
  LastSpawnId := ASpawnId;
  LastActive := AActive;
  Result := GREED_POOL_NIL;
end;

procedure TInventoryGameFake.DemandLoadMonster(ALump, ACount: Integer);
begin
end;

procedure TInventoryGameFake.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  Sounds := Sounds + [ASound];
end;

procedure TInventoryGameFake.Hurt(AAmount: Integer);
begin
end;

procedure TInventoryGameFake.Heal(AAmount: Integer);
begin
  HealAmount := HealAmount + AAmount;
end;

procedure TInventoryGameFake.MedPaks(AAmount: Integer);
begin
  MedPakAmount := MedPakAmount + AAmount;
end;

procedure TInventoryGameFake.AddScore(AAmount: Integer);
begin
end;

procedure TInventoryGameFake.WriteMessage(const AText: string);
begin
  Messages := Messages + [AText];
end;

function TInventoryGameFake.LastMessage: string;
begin
  if Length(Messages) = 0 then
    Result := ''
  else
    Result := Messages[High(Messages)];
end;

{ TTestGreedInventory }

procedure TTestGreedInventory.Setup;
begin
  FWorld := TGreedWorld.Create;
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(16, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(8, 'elevators');
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  FState.PlayerNum := 1;
  FState.Player.CharType := 4;
  FState.Player.MaxAngst := 100;
  FState.Player.MaxShield := 100;
  FState.Player.Angst := 100;
  FState.Player.Shield := 100;
  FGame := TInventoryGameFake.Create;
  FGameIntf := FGame;
  FInventory := TGreedInventory.Create(FState, FGame, FGame, FGame, FGame);
end;

procedure TTestGreedInventory.TearDown;
begin
  FInventory.Free;
  FGameIntf := nil;
  FState.Free;
  FElevators.Free;
  FSprites.Free;
  FWorld := nil;
end;

procedure TTestGreedInventory.Choose(AKind, ACount: Integer);
begin
  FState.Player.Inventory[AKind] := ACount;
  FInventory.Cursor := AKind;
end;

procedure TTestGreedInventory.DovrebbeSollevareSenzaUnaDipendenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedInventory.Create(nil, FGame, FGame, FGame, FGame).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedInventory.Create(FState, nil, FGame, FGame, FGame).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedInventory.Create(FState, FGame, nil, FGame, FGame).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedInventory.Create(FState, FGame, FGame, nil, FGame).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedInventory.Create(FState, FGame, FGame, FGame, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedInventory.DovrebbeNonAvereNullaDaSceglierSeVuoto;
begin
  Assert.AreEqual(GREED_INVENTORY_NONE, FInventory.Cursor);
  FInventory.Right;
  Assert.AreEqual(GREED_INVENTORY_NONE, FInventory.Cursor);
  FInventory.Left;
  Assert.AreEqual(GREED_INVENTORY_NONE, FInventory.Cursor);
  FInventory.Refresh;
  Assert.AreEqual(GREED_INVENTORY_NONE, FInventory.Cursor);
  Assert.AreEqual(GREED_INVENTORY_REDRAW, FInventory.OldInventory);
end;

procedure TTestGreedInventory.DovrebbeAndareAlProssimoOggettoPossedutoFacendoIlGiro;
begin
  FState.Player.Inventory[2] := 1;
  FState.Player.Inventory[7] := 3;
  FInventory.Right;
  Assert.AreEqual(2, FInventory.Cursor);
  FInventory.Right;
  Assert.AreEqual(7, FInventory.Cursor);
  FInventory.Right;
  Assert.AreEqual(2, FInventory.Cursor);
end;

procedure TTestGreedInventory.DovrebbeAndareAlPrecedenteFacendoIlGiro;
begin
  FState.Player.Inventory[2] := 1;
  FState.Player.Inventory[7] := 3;
  FState.Player.Inventory[12] := 1;
  FInventory.Cursor := 7;
  FInventory.Left;
  Assert.AreEqual(2, FInventory.Cursor);
  FInventory.Left;
  Assert.AreEqual(12, FInventory.Cursor);
end;

procedure TTestGreedInventory.DovrebbeUsareIlMedtubeSoloSeFerito;
begin
  Choose(0, 2);
  FInventory.OldInventory := 0;
  FInventory.Use;
  Assert.AreEqual(0, FGame.MedPakAmount);
  Assert.AreEqual(2, FState.Player.Inventory[0]);
  Assert.AreEqual(GREED_INVENTORY_REDRAW, FInventory.OldInventory, 'the bar is drawn again even so');
  FState.Player.Angst := 40;
  FInventory.Use;
  Assert.AreEqual(50, FGame.MedPakAmount);
  Assert.AreEqual(1, FState.Player.Inventory[0]);
  Assert.AreEqual(SGreedUsedMedtube, FGame.LastMessage);
  Assert.AreEqual(0, FInventory.Cursor);
end;

procedure TTestGreedInventory.DovrebbeUsareLaCaricaDelloScudoSoloSeServe;
begin
  Choose(1, 1);
  FInventory.Use;
  Assert.AreEqual(0, FGame.HealAmount);
  FState.Player.Shield := 99;
  FInventory.Use;
  Assert.AreEqual(50, FGame.HealAmount);
  Assert.AreEqual(0, FState.Player.Inventory[1]);
  Assert.AreEqual(SGreedUsedShieldCharge, FGame.LastMessage);
  Assert.AreEqual(GREED_INVENTORY_NONE, FInventory.Cursor, 'nothing is left');
end;

procedure TTestGreedInventory.DovrebbeChiedereLaGranataELanciarlaDopo;
begin
  FInventory.ThrowGrenade;
  Assert.AreEqual(0, Integer(Length(FGame.SpawnValues)), 'no grenade was asked for');
  Choose(2, 4);
  FState.Player.Angle := 300;
  FState.Player.ScrollMin := 10;
  FInventory.Use;
  Assert.IsTrue(FInventory.FireGrenade);
  Assert.AreEqual(4, FState.Player.Inventory[2], 'the grenade is taken when it is thrown');
  FInventory.ThrowGrenade;
  Assert.IsFalse(FInventory.FireGrenade);
  Assert.AreEqual(3, FState.Player.Inventory[2]);
  Assert.AreEqual(GREED_S_GRENADE, FGame.SpawnValues[0]);
  Assert.AreEqual(300, FGame.SpawnAngles[0]);
  Assert.IsTrue(FGame.LastActive);
  Assert.AreEqual(GREED_SN_GRENADE, FGame.Sounds[0]);
end;

procedure TTestGreedInventory.DovrebbeAvviareLEffettoUnaVoltaSola;
begin
  Choose(3, 2);
  FState.TimeCount := 1000;
  FInventory.Use;
  Assert.AreEqual(GREED_SE_REVERSOPILL, FState.SpecialEffect);
  Assert.AreEqual(1000 + GREED_TIC_RATE * 15, FState.SpecialEffectTime);
  Assert.AreEqual(GREED_TIC_RATE * 15, FInventory.TotalEffectTime);
  Assert.AreEqual(1, FState.Player.Inventory[3]);
  Assert.AreEqual(SGreedUsedReversoPill, FGame.LastMessage);
  FInventory.Use;
  Assert.AreEqual(1, FState.Player.Inventory[3], 'the effect is already running');
  Choose(10, 1);
  FInventory.Use;
  Assert.AreEqual(GREED_SE_INVISIBILITY, FState.SpecialEffect);
  Assert.AreEqual(GREED_TIC_RATE * 30, FInventory.TotalEffectTime);
  Assert.AreEqual(SGreedActivatedInvisibility, FGame.LastMessage);
end;

procedure TTestGreedInventory.DovrebbePosareMineEControfigureDoveSiTrovaIlGiocatore;
begin
  Choose(4, 1);
  FInventory.Use;
  Assert.AreEqual(GREED_S_PROXMINE, FGame.SpawnValues[0]);
  Assert.AreEqual(1, FGame.LastSpawnId, 'the number of the player');
  Assert.IsFalse(FGame.LastActive);
  Assert.AreEqual(SGreedDroppedProximityMine, FGame.LastMessage);
  Choose(5, 1);
  FInventory.Use;
  Assert.AreEqual(GREED_S_TIMEMINE, FGame.SpawnValues[1]);
  Choose(6, 1);
  FInventory.Use;
  Assert.AreEqual(GREED_S_DECOY, FGame.SpawnValues[2]);
  Assert.AreEqual(4, FGame.LastSpawnId, 'the character of the player');
  Choose(7, 1);
  FInventory.Use;
  Assert.AreEqual(GREED_S_INSTAWALL, FGame.SpawnValues[3]);
  Choose(8, 1);
  FInventory.Use;
  Assert.AreEqual(GREED_S_CLONE, FGame.SpawnValues[4]);
  Assert.AreEqual(SGreedCloneActivated, FGame.LastMessage);
  Assert.AreEqual(0, FState.Player.Inventory[8]);
end;

procedure TTestGreedInventory.DovrebbePrendereLaFiguraDelloSpriteFermoPiuVicino;
var
  LItem: PGreedSprite;
begin
  // far and still, near but alive, near and still
  LItem := PGreedSprite(FSprites.Item(FSprites.Add));
  LItem^.X := 30 * GREED_FRACTILEUNIT;
  LItem^.BasePic := 111;
  LItem^.Scale := 1;
  LItem := PGreedSprite(FSprites.Item(FSprites.Add));
  LItem^.X := 1 * GREED_FRACTILEUNIT;
  LItem^.HitPoints := 5;
  LItem^.BasePic := 222;
  LItem := PGreedSprite(FSprites.Item(FSprites.Add));
  LItem^.X := 3 * GREED_FRACTILEUNIT;
  LItem^.BasePic := 333;
  LItem^.Scale := 2;
  Choose(9, 1);
  FInventory.Use;
  Assert.AreEqual(333, FState.Player.HoloPic);
  Assert.AreEqual(2, FState.Player.HoloScale);
  Assert.AreEqual(0, FState.Player.Inventory[9]);
  Assert.AreEqual(SGreedHoloSuitActive, FGame.LastMessage);
end;

procedure TTestGreedInventory.DovrebbeFallireLOloSenzaSpriteFermi;
begin
  PGreedSprite(FSprites.Item(FSprites.Add))^.Active := True;
  Choose(9, 1);
  FInventory.Use;
  Assert.AreEqual(0, FState.Player.HoloPic);
  Assert.AreEqual(1, FState.Player.Inventory[9]);
  Assert.AreEqual(SGreedUnsuccessfulHolo, FGame.LastMessage);
end;

procedure TTestGreedInventory.DovrebbeSoloSegnalareIlWarpJammer;
begin
  Choose(11, 1);
  FInventory.Use;
  Assert.IsTrue(FState.WarpJammer);
  Assert.AreEqual(1, FState.Player.Inventory[11], 'the level takes it when it jams the warps');
  Assert.AreEqual(0, Integer(Length(FGame.Messages)));
end;

procedure TTestGreedInventory.DovrebbeSparareSediciProiettiliConIlSoulStealer;
begin
  Choose(12, 1);
  FInventory.Use;
  Assert.AreEqual(16, Integer(Length(FGame.SpawnValues)));
  Assert.AreEqual(GREED_S_SOULBULLET, FGame.SpawnValues[15]);
  Assert.AreEqual(0, FGame.SpawnAngles[0]);
  Assert.AreEqual(63, FGame.SpawnAngles[1], '1023 div 16');
  Assert.AreEqual(15 * 63, FGame.SpawnAngles[15]);
  Assert.IsTrue(FGame.LastActive);
  Assert.AreEqual(2, Integer(Length(FGame.Sounds)), 'the sound is played twice');
  Assert.AreEqual(GREED_SN_SOULSTEALER, FGame.Sounds[1]);
  Assert.AreEqual(SGreedUsedSoulStealer, FGame.LastMessage);
end;

procedure TTestGreedInventory.DovrebbePassareAlProssimoOggettoFinitoQuelloScelto;
begin
  FState.Player.Inventory[7] := 2;
  Choose(4, 1);
  FInventory.Use;
  Assert.AreEqual(7, FInventory.Cursor);
end;

procedure TTestGreedInventory.DovrebbeNonFareNullaSenzaOggettoScelto;
begin
  FInventory.OldInventory := 5;
  FInventory.Use;
  FInventory.Cursor := 4;
  FInventory.Use;
  Assert.AreEqual(0, Integer(Length(FGame.SpawnValues)));
  Assert.AreEqual(5, FInventory.OldInventory, 'not even the bar is drawn again');
end;

{ TTestGreedHud }

procedure TTestGreedHud.Setup;
begin
  FArchive := THudScenarios.SyntheticArchive;
  FRunner := THudLibraryRunner.Create(THudScenarios.Describe(FArchive));
  State.Player.MaxAngst := 100;
  State.Player.MaxShield := 100;
  State.Player.Angst := 50;
  State.Player.Shield := 50;
  State.Player.X := 10 * GREED_FRACTILEUNIT;
  State.Player.Y := 20 * GREED_FRACTILEUNIT;
  State.SpecialEffectTime := $7FFFFFFF;
  State.GoalItem := -1;
  Canvas.ApproxZero := 250;
  Hud.ResetDisplay;
end;

procedure TTestGreedHud.TearDown;
begin
  FRunner.Free;
  FArchive := nil;
end;

function TTestGreedHud.Hud: TGreedHud;
begin
  Result := FRunner.Hud;
end;

function TTestGreedHud.State: TGreedGameState;
begin
  Result := FRunner.State;
end;

function TTestGreedHud.Canvas: TGreedCanvas;
begin
  Result := FRunner.Canvas;
end;

function TTestGreedHud.CountPixels: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(Canvas.Pixels) do
    if Canvas.Pixels[LIndex] <> 0 then
      Inc(Result);
end;

procedure TTestGreedHud.DovrebbeSollevareSenzaUnaDipendenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedHud.Create(nil, Canvas, FRunner.Printer, FRunner.Inventory, FArchive, nil, nil, nil).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedHud.Create(State, Canvas, FRunner.Printer, FRunner.Inventory, FArchive, nil, nil, nil).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedHud.Create(State, Canvas, FRunner.Printer, nil, FArchive, nil, nil, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedHud.DovrebbeAzzerareCioCheHaDisegnato;
begin
  Hud.OldShots := 5;
  Hud.OldGoalItem := 5;
  Hud.OldAngle := 5;
  FRunner.Inventory.OldInventory := 5;
  Hud.ResetDisplay;
  Assert.AreEqual(-1, Hud.OldShots);
  Assert.AreEqual(-1, Hud.OldGoalItem);
  Assert.AreEqual(-1, Hud.OldAngle);
  Assert.AreEqual(-1, Hud.OldAngst);
  Assert.AreEqual(-1, Hud.OldAngstPic);
  Assert.AreEqual(GREED_INVENTORY_REDRAW, FRunner.Inventory.OldInventory);
end;

procedure TTestGreedHud.DovrebbeCambiareLaDimensioneDellaVistaTraZeroEQuattro;
begin
  Hud.CurrentViewSize := 0;
  Hud.OldShots := 9;
  Hud.ChangeViewSize(False);
  Assert.AreEqual(0, Hud.CurrentViewSize);
  Assert.AreEqual(9, Hud.OldShots, 'nothing changes at the limit');
  Hud.ChangeViewSize(True);
  Assert.AreEqual(1, Hud.CurrentViewSize);
  Assert.AreEqual(-1, Hud.OldShots, 'the display is reset');
  Hud.CurrentViewSize := GREED_MAXVIEWSIZE - 1;
  Hud.ChangeViewSize(True);
  Assert.AreEqual(GREED_MAXVIEWSIZE - 1, Hud.CurrentViewSize);
  Hud.ChangeViewSize(False);
  Assert.AreEqual(GREED_MAXVIEWSIZE - 2, Hud.CurrentViewSize);
end;

procedure TTestGreedHud.DovrebbeNonDisegnareBarraADimensioneZero;
begin
  Hud.CurrentViewSize := 0;
  Hud.DrawStatusBar;
  Assert.AreEqual(0, CountPixels);
end;

procedure TTestGreedHud.DovrebbeDisegnareLaBarraAlSuoPostoSaltandoLoZero;
var
  LBar: TBytes;
  LRow, LColumn: Integer;
begin
  LBar := FArchive.ReadLump(FArchive.RequireIndexOf('STATBAR1'));
  Hud.CurrentViewSize := 1;
  Hud.DrawStatusBar;
  for LRow := 0 to TGreedCanvas.PictureHeight(LBar) - 1 do
    for LColumn := 0 to TGreedCanvas.PictureWidth(LBar) - 1 do
      Assert.AreEqual(LBar[GREED_PICTURE_HEADER_BYTES + LRow * TGreedCanvas.PictureWidth(LBar) + LColumn],
        Canvas.GetPixel(220 + LColumn, 149 + LRow));
  Assert.AreEqual(Byte(0), Canvas.GetPixel(219, 160));
  Assert.AreEqual(Byte(0), Canvas.GetPixel(100, 5), 'no top bar');
end;

procedure TTestGreedHud.DovrebbeDisegnareLaBarraInAltoSoloADimensioneQuattro;
var
  LTop: TBytes;
  LColumn, LSeen: Integer;
begin
  LTop := FArchive.ReadLump(FArchive.RequireIndexOf('STATBAR4'));
  Hud.CurrentViewSize := 4;
  Hud.DrawStatusBar;
  LSeen := 0;
  for LColumn := 0 to 319 do
  begin
    Assert.AreEqual(LTop[GREED_PICTURE_HEADER_BYTES + LColumn], Canvas.GetPixel(LColumn, 0));
    if Canvas.GetPixel(LColumn, 0) <> 0 then
      Inc(LSeen);
  end;
  Assert.IsTrue(LSeen > 100);
  // and the third bar at the bottom
  Assert.AreEqual(FArchive.ReadLump(FArchive.RequireIndexOf('STATBAR3'))[GREED_PICTURE_HEADER_BYTES],
    Canvas.GetPixel(4, 149));
end;

procedure TTestGreedHud.DovrebbeMostrareLOggettoSceltoPerUnPoADimensioneZero;
begin
  Hud.CurrentViewSize := 0;
  State.Player.Inventory[3] := 7;
  FRunner.Inventory.Cursor := 3;
  State.TimeCount := 100;
  State.InventoryTime := 100;
  Hud.UpdateDisplay;
  Assert.AreEqual(0, CountPixels, 'the time is over');
  State.InventoryTime := 101;
  Hud.UpdateDisplay;
  // the frame of the box: a column at the left and a row at the bottom, and the background inside
  Assert.AreEqual(Byte(30), Canvas.GetPixel(320 - 55, 0));
  Assert.AreEqual(Byte(30), Canvas.GetPixel(319, 27));
  Assert.AreEqual(Byte(250), Canvas.GetPixel(320 - 54, 26));
  Assert.AreEqual(Byte(0), Canvas.GetPixel(320 - 56, 0));
  Assert.AreEqual(Byte(0), Canvas.GetPixel(300, 28));
end;

procedure TTestGreedHud.DovrebbeMuovereIlCursoreDelBattitoColTempo;
begin
  Hud.CurrentViewSize := 1;
  State.TimeCount := 54 * 3 + 20;
  Hud.DrawStatusBar;
  Hud.UpdateDisplay;
  Assert.AreEqual(289, Hud.StatCursor);
  // the needle of the compass starts at its center with the color 139
  Assert.AreEqual(Byte(139), Canvas.GetPixel(237, 161));
end;

procedure TTestGreedHud.DovrebbeChiedereUnAltroObiettivoQuandoCompareIlBonus;
begin
  Hud.CurrentViewSize := 2;
  State.GoalItem := -1;
  Hud.UpdateDisplay;
  Assert.IsFalse(State.ToggleGoalItem);
  State.BonusItem.Score := 500;
  Hud.UpdateDisplay;
  Assert.IsTrue(State.ToggleGoalItem, 'no goal is shown and a bonus item appeared');
  State.ToggleGoalItem := False;
  State.GoalItem := 0;
  State.BonusItem.Score := 0;
  Hud.UpdateDisplay;
  Assert.IsTrue(State.ToggleGoalItem, 'the bonus item that was shown is gone');
end;

procedure TTestGreedHud.DovrebbeSollevarePerUnaModalitaMappaSconosciuta;
begin
  State.MapMode := 3;
  Assert.WillRaise(
    procedure
    begin
      Hud.DrawDisplays;
    end, EGreedException);
end;

procedure TTestGreedHud.DovrebbeDisegnareIlSensoreDiCaloreNelRiquadro;
begin
  State.HeatMode := True;
  State.ExitExists := True;
  State.ExitX := 5;
  State.ExitY := 6;
  Hud.DrawDisplays;
  Assert.AreEqual(Byte(73), Canvas.GetPixel(2, 20));
  Assert.AreEqual(Byte(73), Canvas.GetPixel(67, 85));
  Assert.AreEqual(Byte(73), Canvas.GetPixel(67, 50));
  Assert.AreEqual(Byte(40), Canvas.GetPixel(10 + 3, 20 + 21), 'the player');
  Assert.AreEqual(Byte(187), Canvas.GetPixel(5 + 3, 6 + 21), 'the exit');
end;

procedure TTestGreedHud.DovrebbeSegnareGliSpriteViviNelSensoreDiMovimento;
var
  LItem: PGreedSprite;
begin
  LItem := PGreedSprite(State.Sprites.Item(State.Sprites.Add));
  LItem^.X := 30 * GREED_FRACTILEUNIT;
  LItem^.Y := 40 * GREED_FRACTILEUNIT;
  LItem^.Active := True;
  LItem^.HitPoints := 10;
  LItem := PGreedSprite(State.Sprites.Item(State.Sprites.Add));
  LItem^.X := 31 * GREED_FRACTILEUNIT;
  LItem^.Y := 40 * GREED_FRACTILEUNIT;
  LItem^.Active := True;
  State.MotionMode := True;
  Hud.DrawDisplays;
  Assert.AreEqual(Byte(152), Canvas.GetPixel(30 + 3, 40 + 21));
  Assert.AreEqual(Byte(0), Canvas.GetPixel(31 + 3, 40 + 21), 'without hit points it is not alive');
end;

procedure TTestGreedHud.DovrebbeDisegnareLaFrecciaAlCentroDellaMappa;
begin
  State.MapMode := 1;
  State.Player.Angle := 0;
  State.Player.NorthMap[20 * 64 + 10] := 99;
  Hud.DrawDisplays;
  Assert.AreEqual(Byte(26), Canvas.GetPixel(161, 101));
  Assert.AreEqual(Byte(40), Canvas.GetPixel(162, 101), 'the point of the arrow, to the east');
  Assert.AreEqual(Byte(20), Canvas.GetPixel(160, 101));
  // the north wall of the tile of the player: 5 pixels from the corner of the tile
  Assert.AreEqual(Byte(99), Canvas.GetPixel(163, 101 + 1 - 1));
end;

procedure TTestGreedHud.DovrebbeDisegnareIlRiquadroDellaVistaPosteriore;
var
  LRear: TBytes;
begin
  SetLength(LRear, GREED_REAR_VIEW_SIZE * GREED_REAR_VIEW_SIZE);
  FillChar(LRear[0], Length(LRear), 8);
  Hud.CurrentViewSize := 0;
  Hud.DrawRearView(LRear);
  Assert.AreEqual(Byte(30), Canvas.GetPixel(254, 1));
  Assert.AreEqual(Byte(30), Canvas.GetPixel(319, 30));
  Assert.AreEqual(Byte(30), Canvas.GetPixel(300, 64));
  Assert.AreEqual(Byte(8), Canvas.GetPixel(255, 2));
  Assert.AreEqual(Byte(8), Canvas.GetPixel(318, 63));
  Canvas.Clear;
  Hud.CurrentViewSize := 4;
  Hud.DrawRearView(LRear);
  Assert.AreEqual(Byte(30), Canvas.GetPixel(254, 11), 'under the top bar');
  Assert.AreEqual(Byte(0), Canvas.GetPixel(254, 1));
end;

procedure TTestGreedHud.DovrebbeRifiutareUnaVistaPosterioreCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      Hud.DrawRearView(TBytes.Create(1, 2, 3));
    end, EGreedDataException);
end;

procedure TTestGreedHud.DovrebbeDisegnareLOloSoloSeIndossato;
begin
  Hud.DrawHolo;
  Assert.AreEqual(0, CountPixels);
  State.Player.HoloPic := FArchive.RequireIndexOf('primary');
  Hud.DrawHolo;
  Assert.IsTrue(CountPixels > 0);
  Assert.AreEqual(Byte(0), Canvas.GetPixel(4, 190), 'the picture starts at the column 5');
end;

procedure TTestGreedHud.DovrebbeOffrireIMetodiDegliHostDelLivello;
begin
  Hud.OldShots := 4;
  Hud.RefreshAmmo;
  Assert.AreEqual(-1, Hud.OldShots);
  Hud.OldGoalItem := 4;
  Hud.RefreshGoalItem;
  Assert.AreEqual(-1, Hud.OldGoalItem);
  Hud.SetTotalEffectTime(700);
  Assert.AreEqual(700, FRunner.Inventory.TotalEffectTime);
  State.Player.Inventory[6] := 1;
  FRunner.Inventory.OldInventory := 6;
  Hud.RefreshInventory;
  Assert.AreEqual(6, FRunner.Inventory.Cursor);
  Assert.AreEqual(GREED_INVENTORY_REDRAW, FRunner.Inventory.OldInventory);
  Assert.AreSame(FRunner.Inventory, Hud.Inventory);
end;

{ TTestGreedHudParity }

procedure TTestGreedHudParity.CheckGolden(const AArchive: IGreedArchive; const AGoldenName: string);
var
  LGolden, LLines: TStringList;
  LIndex, LDifferent: Integer;
  LFirst: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(AGoldenName));
    LLines := HudLibraryLines(AArchive);
    try
      Assert.AreEqual(HUD_PALETTE_CASES + HUD_CANVAS_CASES + HUD_TEXT_CASES + HUD_SCENARIOS * HUD_FRAMES,
        LLines.Count);
      Assert.AreEqual(LGolden.Count, LLines.Count, 'the golden file has other cases');
      LDifferent := 0;
      LFirst := '';
      for LIndex := 0 to LLines.Count - 1 do
        if LLines[LIndex] <> LGolden[LIndex] then
        begin
          if LDifferent = 0 then
            LFirst := LGolden[LIndex] + ' / ' + LLines[LIndex];
          Inc(LDifferent);
        end;
      Assert.AreEqual(0, LDifferent, 'cases that differ from the original; the first (original / library): ' +
        LFirst);
    finally
      LLines.Free;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedHudParity.DovrebbeDareGliStessiPixelDelloOriginaleSuiDatiSintetici;
begin
  CheckGolden(THudScenarios.SyntheticArchive, 'hud.golden.txt');
end;

procedure TTestGreedHudParity.DovrebbeDareGliStessiPixelDelloOriginaleNelGiocoCompleto;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('i dati del gioco completo (GREED.BLO) non ci sono');
  CheckGolden(TGreedRealData.OpenArchive(TGreedRealData.FullFolder), 'hud.full.golden.txt');
end;

procedure TTestGreedHudParity.DovrebbeDareGliStessiPixelDelloOriginaleNellaDemo20;
begin
  if TGreedRealData.Demo20Folder = '' then
    TTestSkip.Ignore('i dati della demo 2.0 (GREED.BLO) non ci sono');
  CheckGolden(TGreedRealData.OpenArchive(TGreedRealData.Demo20Folder), 'hud.demo20.golden.txt');
end;

end.
