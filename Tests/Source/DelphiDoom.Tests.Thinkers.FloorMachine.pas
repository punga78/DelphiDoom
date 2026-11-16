{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the classic floors (T_MoveFloor, EV_DoFloor, stairs)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.FloorMachine;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Floor.Types, DelphiDoom.Tests.Thinkers.OldFloors;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersFloorMachine = class(TObject)
  strict private
    function KindOf(AType: floor_e): TFloorKind;
    function StairOf(AType: stair_e): TStairKind;
    /// <summary>The body of the loop of EV_DoFloor as IdTech1\Base\p_floor.pas writes it now</summary>
    procedure NewSpawnFloor(AFloor: Pfloormove_t; ASector: Psector_t; ALine: Pline_t;
      AType: floor_e; const AProfile: TFloorProfile; AModern: Boolean);
    /// <summary>The changes of T_MoveFloor at the destination as IdTech1\Base\p_floor.pas writes them now</summary>
    procedure NewFloorArrival(AFloor: Pfloormove_t);
    procedure CheckSpawnParity(AGame: TPlatGame; AVersion: Integer; ASeed: Cardinal);
    procedure CheckStairParity(AGame: TPlatGame; AVersion: Integer);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeNonCambiareNullaConUnPavimentoQualsiasi;
    [Test]
    procedure DovrebbeCambiareIlSettoreConIlDonutCheSale;
    [Test]
    procedure DovrebbeCambiareIlSettoreConAbbassaECambiaCheScende;
    [Test]
    procedure DovrebbeTrasferireAncheIlVecchioSpecialConICambiatori;
    [Test]
    procedure DovrebbeNonFareNullaSenzaDirezione;
    [Test]
    procedure DovrebbeNonPianificareIGeneriCheNonNasconoQui;
    [Test]
    procedure DovrebbePianificareVelocitaEDirezione;
    [Test]
    procedure DovrebbeFermareIlTurboSopraIlPavimentoPiuAltoTranneInStrife;
    [Test]
    procedure DovrebbeLimitareIlPavimentoCheSaleAlSoffitto;
    [Test]
    procedure DovrebbeSommareLaDistanzaAlPavimento;
    [Test]
    procedure DovrebbeSalireDellaTextureConIlLimiteDeiMotoriNuovi;
    [Test]
    procedure DovrebbeSalireDellaTextureSenzaLimiteNeiMotoriVecchi;
    [Test]
    procedure DovrebbeDareIGradiniDiDoom;
    [Test]
    procedure DovrebbeDareIGradiniDiStrife;
    [Test]
    procedure DovrebbeDareIlProfiloDiOgniGioco;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiDoomAllArrivo;
    [Test]
    procedure DovrebbeCreareIPavimentiComeIlVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeCreareIPavimentiComeIlVecchioCodiceDiDoomVecchiaVersione;
    [Test]
    procedure DovrebbeCreareIPavimentiComeIlVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeCostruireLeScaleComeIlVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeCostruireLeScaleComeIlVecchioCodiceDiDoomVecchiaVersione;
    [Test]
    procedure DovrebbeCostruireLeScaleComeIlVecchioCodiceDiStrife;
  end;

implementation

uses
  DelphiDoom.Thinkers.Floor.Games, DelphiDoom.Thinkers.Floor.Machine,
  DelphiDoom.Tests.Thinkers.PlaneFakes;

const
  MODERN_VERSION = 207;

{ TTestThinkersFloorMachine }

procedure TTestThinkersFloorMachine.Setup;
begin
  OldFloorEngineVersion := MODERN_VERSION;
  OldFloorModelSector := nil;
end;

function TTestThinkersFloorMachine.KindOf(AType: floor_e): TFloorKind;
begin
  case AType of
    lowerFloor: Result := TFloorKind.LowerFloor;
    lowerFloorToLowest: Result := TFloorKind.LowerFloorToLowest;
    turboLower: Result := TFloorKind.TurboLower;
    raiseFloor: Result := TFloorKind.RaiseFloor;
    raiseFloorToNearest: Result := TFloorKind.RaiseFloorToNearest;
    lowerFloorToNearest: Result := TFloorKind.LowerFloorToNearest;
    lowerFloor24: Result := TFloorKind.LowerFloor24;
    lowerFloor32Turbo: Result := TFloorKind.LowerFloor32Turbo;
    raiseToTexture: Result := TFloorKind.RaiseToTexture;
    lowerAndChange: Result := TFloorKind.LowerAndChange;
    raiseFloor64: Result := TFloorKind.RaiseFloor64;
    raiseFloor24: Result := TFloorKind.RaiseFloor24;
    raiseFloor32Turbo: Result := TFloorKind.RaiseFloor32Turbo;
    raiseFloor24AndChange: Result := TFloorKind.RaiseFloor24AndChange;
    raiseFloorCrush: Result := TFloorKind.RaiseFloorCrush;
    raiseFloorTurbo: Result := TFloorKind.RaiseFloorTurbo;
    donutRaise: Result := TFloorKind.DonutRaise;
    raiseFloor512: Result := TFloorKind.RaiseFloor512;
    raiseFloor512AndChange: Result := TFloorKind.RaiseFloor512AndChange;
    genFloorChg: Result := TFloorKind.GenFloorChg;
    genFloorChg0: Result := TFloorKind.GenFloorChg0;
    genFloorChgT: Result := TFloorKind.GenFloorChgT;
  else
    Result := TFloorKind.Other;
  end;
end;

function TTestThinkersFloorMachine.StairOf(AType: stair_e): TStairKind;
begin
  case AType of
    build8: Result := TStairKind.Build8;
    turbo16: Result := TStairKind.Turbo16;
    buildDown16: Result := TStairKind.BuildDown16;
  else
    Result := TStairKind.Other;
  end;
end;

procedure TTestThinkersFloorMachine.NewSpawnFloor(AFloor: Pfloormove_t; ASector: Psector_t;
  ALine: Pline_t; AType: floor_e; const AProfile: TFloorProfile; AModern: Boolean);
var
  LKind: TFloorKind;
  LPlan: TFloorPlan;
  LIndex, LSize, LNeighbor: Integer;
  LModel: Psector_t;
begin
  LKind := KindOf(AType);
  if not TFloorMachine.Plan(LKind, LPlan) then
    Exit;
  if LPlan.Crush then
    AFloor.crush := True;
  AFloor.direction := LPlan.Direction;
  AFloor.sector := ASector;
  AFloor.speed := LPlan.Speed;

  if LPlan.Target = TFloorTarget.ShortestTexture then
  begin
    LSize := TFloorMachine.TextureStartSize(AModern);
    for LIndex := 0 to ASector.linecount - 1 do
      if OldFloorTwoSided[LIndex] then
      begin
        if OldFloorSides[LIndex, 0].bottomtexture >= 0 then
          if textureheight[OldFloorSides[LIndex, 0].bottomtexture] < LSize then
            LSize := textureheight[OldFloorSides[LIndex, 0].bottomtexture];
        if OldFloorSides[LIndex, 1].bottomtexture >= 0 then
          if textureheight[OldFloorSides[LIndex, 1].bottomtexture] < LSize then
            LSize := textureheight[OldFloorSides[LIndex, 1].bottomtexture];
      end;
    AFloor.floordestheight := TFloorMachine.TextureDestination(ASector.floorheight, LSize,
      AModern);
  end
  else
  begin
    case LPlan.Target of
      TFloorTarget.HighestFloor:
        LNeighbor := OldFloorHighestFloor;
      TFloorTarget.LowestFloor:
        LNeighbor := OldFloorLowestFloor;
      TFloorTarget.NextLowestFloor:
        LNeighbor := OldFloorNextLowestFloor;
      TFloorTarget.NextHighestFloor:
        LNeighbor := OldFloorNextHighestFloor;
      TFloorTarget.LowestCeiling:
        LNeighbor := OldFloorLowestCeiling;
    else
      LNeighbor := 0;
    end;
    AFloor.floordestheight := TFloorMachine.Destination(LKind, LPlan, ASector.floorheight,
      ASector.ceilingheight, LNeighbor, AProfile);
  end;

  if LPlan.ChangeFromLine then
  begin
    ASector.floorpic := ALine.frontsector.floorpic;
    ASector.special := ALine.frontsector.special;
    if LPlan.ChangeOldSpecialToo then
      ASector.oldspecial := ALine.frontsector.oldspecial;
  end;

  if LPlan.CarriesModel then
  begin
    AFloor.texture := ASector.floorpic;
    AFloor.newspecial := ASector.special;
    AFloor.oldspecial := ASector.oldspecial;
    LModel := OldFloorModelSector;
    if Assigned(LModel) then
    begin
      AFloor.texture := LModel.floorpic;
      AFloor.newspecial := LModel.special;
      AFloor.oldspecial := LModel.oldspecial;
    end;
  end;
end;

procedure TTestThinkersFloorMachine.NewFloorArrival(AFloor: Pfloormove_t);
var
  LActions: TFloorActions;
begin
  LActions := TFloorMachine.Arrival(KindOf(AFloor._type), AFloor.direction);
  if TFloorAction.TransferSpecial in LActions then
    AFloor.sector.special := AFloor.newspecial;
  if TFloorAction.TransferOldSpecial in LActions then
    AFloor.sector.oldspecial := AFloor.oldspecial;
  if TFloorAction.ChangeTexture in LActions then
    AFloor.sector.floorpic := AFloor.texture;
end;

procedure TTestThinkersFloorMachine.DovrebbeNonCambiareNullaConUnPavimentoQualsiasi;
begin
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.RaiseFloor, 1) = [], 'raise');
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.LowerFloor, -1) = [], 'lower');
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.Other, 1) = [], 'other');
end;

procedure TTestThinkersFloorMachine.DovrebbeCambiareIlSettoreConIlDonutCheSale;
begin
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.DonutRaise, 1) =
    [TFloorAction.TransferSpecial, TFloorAction.ChangeTexture], 'up');
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.DonutRaise, -1) = [], 'down');
end;

procedure TTestThinkersFloorMachine.DovrebbeCambiareIlSettoreConAbbassaECambiaCheScende;
begin
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.LowerAndChange, -1) =
    [TFloorAction.TransferSpecial, TFloorAction.ChangeTexture], 'down');
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.LowerAndChange, 1) = [], 'up');
end;

procedure TTestThinkersFloorMachine.DovrebbeTrasferireAncheIlVecchioSpecialConICambiatori;
var
  LDirection: Integer;
begin
  for LDirection in [-1, 1] do
  begin
    Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.GenFloorChg, LDirection) =
      [TFloorAction.ChangeTexture], 'plain changer');
    Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.GenFloorChg0, LDirection) =
      [TFloorAction.TransferSpecial, TFloorAction.TransferOldSpecial,
      TFloorAction.ChangeTexture], 'changer 0');
    Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.GenFloorChgT, LDirection) =
      [TFloorAction.TransferSpecial, TFloorAction.TransferOldSpecial,
      TFloorAction.ChangeTexture], 'changer T');
  end;
end;

procedure TTestThinkersFloorMachine.DovrebbeNonFareNullaSenzaDirezione;
begin
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.GenFloorChgT, 0) = [], 'zero');
  Assert.IsTrue(TFloorMachine.Arrival(TFloorKind.DonutRaise, 2) = [], 'two');
end;

procedure TTestThinkersFloorMachine.DovrebbeNonPianificareIGeneriCheNonNasconoQui;
var
  LPlan: TFloorPlan;
begin
  Assert.IsFalse(TFloorMachine.Plan(TFloorKind.DonutRaise, LPlan), 'donut');
  Assert.IsFalse(TFloorMachine.Plan(TFloorKind.GenFloorChg, LPlan), 'changer');
  Assert.IsFalse(TFloorMachine.Plan(TFloorKind.Other, LPlan), 'other');
end;

procedure TTestThinkersFloorMachine.DovrebbePianificareVelocitaEDirezione;
var
  LPlan: TFloorPlan;
begin
  Assert.IsTrue(TFloorMachine.Plan(TFloorKind.LowerFloor, LPlan), 'lower');
  Assert.AreEqual(-1, LPlan.Direction, 'lower direction');
  Assert.AreEqual(FLOOR_SPEED, LPlan.Speed, 'lower speed');
  Assert.AreEqual(Ord(TFloorTarget.HighestFloor), Ord(LPlan.Target), 'lower target');
  Assert.IsFalse(LPlan.Crush, 'lower crush');

  Assert.IsTrue(TFloorMachine.Plan(TFloorKind.RaiseFloorTurbo, LPlan), 'turbo');
  Assert.AreEqual(1, LPlan.Direction, 'turbo direction');
  Assert.AreEqual(4 * FLOOR_SPEED, LPlan.Speed, 'turbo speed');
  Assert.AreEqual(Ord(TFloorTarget.NextHighestFloor), Ord(LPlan.Target), 'turbo target');

  Assert.IsTrue(TFloorMachine.Plan(TFloorKind.RaiseFloorCrush, LPlan), 'crush');
  Assert.IsTrue(LPlan.Crush, 'crush flag');

  Assert.IsTrue(TFloorMachine.Plan(TFloorKind.RaiseFloor24AndChange, LPlan), 'change');
  Assert.IsTrue(LPlan.ChangeFromLine and LPlan.ChangeOldSpecialToo, 'change of doom');
  Assert.IsTrue(TFloorMachine.Plan(TFloorKind.RaiseFloor512AndChange, LPlan), 'change 512');
  Assert.IsTrue(LPlan.ChangeFromLine and not LPlan.ChangeOldSpecialToo, 'change of strife');
  Assert.AreEqual(512 * 65536, LPlan.Offset, 'offset');

  Assert.IsTrue(TFloorMachine.Plan(TFloorKind.LowerAndChange, LPlan), 'model');
  Assert.IsTrue(LPlan.CarriesModel, 'carries the model');
end;

procedure TTestThinkersFloorMachine.DovrebbeFermareIlTurboSopraIlPavimentoPiuAltoTranneInStrife;
var
  LPlan: TFloorPlan;
  LDoom, LStrife: TFloorProfile;
begin
  LDoom := TFloorGames.ProfileOf(TPlatGame.Doom);
  LStrife := TFloorGames.ProfileOf(TPlatGame.Strife);
  TFloorMachine.Plan(TFloorKind.TurboLower, LPlan);
  Assert.AreEqual(108 * 65536,
    TFloorMachine.Destination(TFloorKind.TurboLower, LPlan, 200 * 65536, 300 * 65536,
    100 * 65536, LDoom), 'doom');
  Assert.AreEqual(100 * 65536,
    TFloorMachine.Destination(TFloorKind.TurboLower, LPlan, 100 * 65536, 300 * 65536,
    100 * 65536, LDoom), 'doom, already there');
  Assert.AreEqual(100 * 65536,
    TFloorMachine.Destination(TFloorKind.TurboLower, LPlan, 200 * 65536, 300 * 65536,
    100 * 65536, LStrife), 'strife');
  // the slow one never adds
  TFloorMachine.Plan(TFloorKind.LowerFloor, LPlan);
  Assert.AreEqual(100 * 65536,
    TFloorMachine.Destination(TFloorKind.LowerFloor, LPlan, 200 * 65536, 300 * 65536,
    100 * 65536, LDoom), 'lower floor');
end;

procedure TTestThinkersFloorMachine.DovrebbeLimitareIlPavimentoCheSaleAlSoffitto;
var
  LPlan: TFloorPlan;
  LProfile: TFloorProfile;
begin
  LProfile := TFloorGames.ProfileOf(TPlatGame.Doom);
  TFloorMachine.Plan(TFloorKind.RaiseFloor, LPlan);
  Assert.AreEqual(300, TFloorMachine.Destination(TFloorKind.RaiseFloor, LPlan, 0, 300, 500,
    LProfile), 'clamped');
  Assert.AreEqual(250, TFloorMachine.Destination(TFloorKind.RaiseFloor, LPlan, 0, 300, 250,
    LProfile), 'lower neighbor');
  TFloorMachine.Plan(TFloorKind.RaiseFloorCrush, LPlan);
  Assert.AreEqual(300 - 8 * 65536, TFloorMachine.Destination(TFloorKind.RaiseFloorCrush, LPlan,
    0, 300, 500, LProfile), 'crusher stops 8 below');
end;

procedure TTestThinkersFloorMachine.DovrebbeSommareLaDistanzaAlPavimento;
var
  LPlan: TFloorPlan;
  LProfile: TFloorProfile;
begin
  LProfile := TFloorGames.ProfileOf(TPlatGame.Doom);
  TFloorMachine.Plan(TFloorKind.RaiseFloor24, LPlan);
  Assert.AreEqual(10 + 24 * 65536, TFloorMachine.Destination(TFloorKind.RaiseFloor24, LPlan,
    10, 0, 999, LProfile), '24');
  TFloorMachine.Plan(TFloorKind.RaiseFloor64, LPlan);
  Assert.AreEqual(10 + 64 * 65536, TFloorMachine.Destination(TFloorKind.RaiseFloor64, LPlan,
    10, 0, 999, LProfile), '64');
  // the old code adds also for the "lowering" kinds
  TFloorMachine.Plan(TFloorKind.LowerFloor24, LPlan);
  Assert.AreEqual(-1, LPlan.Direction, 'direction of lower 24');
  Assert.AreEqual(10 + 24 * 65536, TFloorMachine.Destination(TFloorKind.LowerFloor24, LPlan,
    10, 0, 999, LProfile), 'lower 24');
end;

procedure TTestThinkersFloorMachine.DovrebbeSalireDellaTextureConIlLimiteDeiMotoriNuovi;
begin
  Assert.AreEqual(32000 * 65536, TFloorMachine.TextureStartSize(True), 'start');
  Assert.AreEqual(164 * 65536, TFloorMachine.TextureDestination(100 * 65536, 64 * 65536, True),
    'sum');
  Assert.AreEqual(164 * 65536,
    TFloorMachine.TextureDestination(100 * 65536 + 5, 64 * 65536 + 7, True), 'whole units');
  Assert.AreEqual(32000 * 65536,
    TFloorMachine.TextureDestination(100 * 65536, 32000 * 65536, True), 'limit');
  Assert.AreEqual(-36 * 65536,
    TFloorMachine.TextureDestination(-100 * 65536, 64 * 65536, True), 'below zero');
  Assert.AreEqual(-37 * 65536,
    TFloorMachine.TextureDestination(-100 * 65536 - 1, 64 * 65536, True), 'floor of a negative');
end;

procedure TTestThinkersFloorMachine.DovrebbeSalireDellaTextureSenzaLimiteNeiMotoriVecchi;
begin
  Assert.AreEqual(MaxInt, TFloorMachine.TextureStartSize(False), 'start');
  Assert.AreEqual(100 * 65536 + 5 + 64 * 65536 + 7,
    TFloorMachine.TextureDestination(100 * 65536 + 5, 64 * 65536 + 7, False), 'plain sum');
  // no texture: the sum wraps as it did
  Assert.AreEqual(Integer(Cardinal(65536) + Cardinal(MaxInt)),
    TFloorMachine.TextureDestination(65536, MaxInt, False), 'wrap');
end;

procedure TTestThinkersFloorMachine.DovrebbeDareIGradiniDiDoom;
var
  LPlan: TStairPlan;
  LProfile: TFloorProfile;
begin
  LProfile := TFloorGames.ProfileOf(TPlatGame.Doom);
  LPlan := TFloorMachine.StairPlan(TStairKind.Build8, True, LProfile);
  Assert.AreEqual(FLOOR_SPEED div 4, LPlan.Speed, 'speed of build8');
  Assert.AreEqual(8 * 65536, LPlan.StepSize, 'step of build8');
  Assert.AreEqual(1, LPlan.Direction, 'direction');
  Assert.IsTrue(LPlan.FirstIsStair, 'first is a stair');
  Assert.IsFalse(LPlan.FirstCrush or LPlan.NextCrush, 'build8 never crushes');
  Assert.IsFalse(LPlan.ClearFirstTag, 'tag');

  LPlan := TFloorMachine.StairPlan(TStairKind.Turbo16, True, LProfile);
  Assert.AreEqual(4 * FLOOR_SPEED, LPlan.Speed, 'speed of turbo16');
  Assert.AreEqual(16 * 65536, LPlan.StepSize, 'step of turbo16');
  Assert.IsTrue(LPlan.FirstCrush and LPlan.NextCrush, 'turbo16 crushes');

  LPlan := TFloorMachine.StairPlan(TStairKind.Turbo16, False, LProfile);
  Assert.IsFalse(LPlan.FirstCrush or LPlan.NextCrush, 'the old engines never crush');
end;

procedure TTestThinkersFloorMachine.DovrebbeDareIGradiniDiStrife;
var
  LPlan: TStairPlan;
  LProfile: TFloorProfile;
begin
  LProfile := TFloorGames.ProfileOf(TPlatGame.Strife);
  LPlan := TFloorMachine.StairPlan(TStairKind.BuildDown16, True, LProfile);
  Assert.AreEqual(FLOOR_SPEED, LPlan.Speed, 'speed');
  Assert.AreEqual(-16 * 65536, LPlan.StepSize, 'step');
  Assert.AreEqual(-1, LPlan.Direction, 'direction');
  Assert.IsFalse(LPlan.FirstIsStair, 'the first step is left plain');
  Assert.IsFalse(LPlan.FirstCrush, 'first crush');
  Assert.IsTrue(LPlan.NextCrush, 'next crush');
  Assert.IsTrue(LPlan.ClearFirstTag, 'tag');

  LPlan := TFloorMachine.StairPlan(TStairKind.Turbo16, True, LProfile);
  Assert.IsFalse(LPlan.FirstCrush, 'first step of turbo16');
  Assert.IsTrue(LPlan.NextCrush, 'next steps of turbo16');

  LPlan := TFloorMachine.StairPlan(TStairKind.Other, True, LProfile);
  Assert.AreEqual(0, LPlan.Direction, 'unknown kind does not move');
end;

procedure TTestThinkersFloorMachine.DovrebbeDareIlProfiloDiOgniGioco;
begin
  Assert.IsTrue(TFloorGames.ProfileOf(TPlatGame.Doom).TurboLowerStopsAbove, 'doom turbo');
  Assert.IsFalse(TFloorGames.ProfileOf(TPlatGame.Doom).StrifeStairs, 'doom stairs');
  Assert.IsTrue(TFloorGames.ProfileOf(TPlatGame.Heretic).TurboLowerStopsAbove, 'heretic turbo');
  Assert.IsFalse(TFloorGames.ProfileOf(TPlatGame.Heretic).StrifeStairs, 'heretic stairs');
  Assert.IsFalse(TFloorGames.ProfileOf(TPlatGame.Strife).TurboLowerStopsAbove, 'strife turbo');
  Assert.IsTrue(TFloorGames.ProfileOf(TPlatGame.Strife).StrifeStairs, 'strife stairs');
end;

procedure TTestThinkersFloorMachine.DovrebbeSeguireIlVecchioCodiceDiDoomAllArrivo;
var
  LState: Cardinal;
  LCase, LDirection: Integer;
  LOldSector, LNewSector: sector_t;
  LOld, LNew: floormove_t;
  LText: string;
begin
  LState := 51;
  for LCase := 1 to 20000 do
  begin
    FillChar(LOldSector, SizeOf(LOldSector), 0);
    FillChar(LOld, SizeOf(LOld), 0);
    LOldSector.special := TestNumberIn(LState, 0, 40);
    LOldSector.oldspecial := TestNumberIn(LState, 0, 40);
    LOldSector.floorpic := TestNumberIn(LState, 0, 200);
    LOld._type := floor_e(TestNumberIn(LState, 0, Ord(High(floor_e))));
    LDirection := TestNumberIn(LState, -2, 2);
    LOld.direction := LDirection;
    LOld.newspecial := TestNumberIn(LState, 0, 40);
    LOld.oldspecial := TestNumberIn(LState, 0, 40);
    LOld.texture := TestNumberIn(LState, 0, 200);
    LNewSector := LOldSector;
    LNew := LOld;
    LOld.sector := @LOldSector;
    LNew.sector := @LNewSector;
    OldFloorArrival(@LOld);
    NewFloorArrival(@LNew);
    LText := Format('case %d kind %d direction %d', [LCase, Ord(LOld._type), LDirection]);
    Assert.AreEqual(LOldSector.special, LNewSector.special, 'special of ' + LText);
    Assert.AreEqual(LOldSector.oldspecial, LNewSector.oldspecial, 'old special of ' + LText);
    Assert.AreEqual(LOldSector.floorpic, LNewSector.floorpic, 'texture of ' + LText);
  end;
end;

procedure TTestThinkersFloorMachine.CheckSpawnParity(AGame: TPlatGame; AVersion: Integer;
  ASeed: Cardinal);
var
  LState: Cardinal;
  LCase, LIndex: Integer;
  LOldSector, LNewSector, LFront, LModel: sector_t;
  LOld, LNew: floormove_t;
  LLine: line_t;
  LType: floor_e;
  LProfile: TFloorProfile;
  LText: string;
begin
  LState := ASeed;
  LProfile := TFloorGames.ProfileOf(AGame);
  OldFloorEngineVersion := AVersion;
  for LCase := 1 to 30000 do
  begin
    FillChar(LOldSector, SizeOf(LOldSector), 0);
    LOldSector.floorheight := TestNumberIn(LState, -64 * 65536, 64 * 65536);
    LOldSector.ceilingheight := LOldSector.floorheight + TestNumberIn(LState, 0, 128 * 65536);
    LOldSector.floorpic := TestNumberIn(LState, 0, 200);
    LOldSector.special := TestNumberIn(LState, 0, 40);
    LOldSector.oldspecial := TestNumberIn(LState, 0, 40);
    LOldSector.linecount := TestNumberIn(LState, 0, OLD_FLOOR_SIDES);
    LFront.floorpic := TestNumberIn(LState, 0, 200);
    LFront.special := TestNumberIn(LState, 0, 40);
    LFront.oldspecial := TestNumberIn(LState, 0, 40);
    LLine.frontsector := @LFront;
    LModel.floorpic := TestNumberIn(LState, 0, 200);
    LModel.special := TestNumberIn(LState, 0, 40);
    LModel.oldspecial := TestNumberIn(LState, 0, 40);
    if TestNumberIn(LState, 0, 2) = 0 then
      OldFloorModelSector := nil
    else
      OldFloorModelSector := @LModel;
    OldFloorHighestFloor := LOldSector.floorheight + TestNumberIn(LState, -32, 32) * 65536;
    if TestNumberIn(LState, 0, 4) = 0 then
      OldFloorHighestFloor := LOldSector.floorheight;
    OldFloorLowestFloor := LOldSector.floorheight - TestNumberIn(LState, 0, 64) * 65536;
    OldFloorNextLowestFloor := LOldSector.floorheight - TestNumberIn(LState, 0, 32) * 65536;
    OldFloorNextHighestFloor := LOldSector.floorheight + TestNumberIn(LState, 0, 32) * 65536;
    OldFloorLowestCeiling := LOldSector.ceilingheight + TestNumberIn(LState, -64, 64) * 65536;
    for LIndex := 0 to OLD_FLOOR_SIDES - 1 do
    begin
      OldFloorTwoSided[LIndex] := TestNumberIn(LState, 0, 2) > 0;
      OldFloorSides[LIndex, 0].bottomtexture := TestNumberIn(LState, -1, High(textureheight));
      OldFloorSides[LIndex, 1].bottomtexture := TestNumberIn(LState, -1, High(textureheight));
    end;
    for LIndex := 0 to High(textureheight) do
      textureheight[LIndex] := TestNumberIn(LState, 1, 256) * 65536;
    if TestNumberIn(LState, 0, 9) = 0 then
      textureheight[0] := 32001 * 65536;

    // what the memory of a new thinker could hold: the kinds that set nothing keep it
    LOld.sector := nil;
    LOld.direction := TestNumberIn(LState, -5, 5);
    LOld.newspecial := TestNumberIn(LState, 0, 40);
    LOld.oldspecial := TestNumberIn(LState, 0, 40);
    LOld.texture := TestNumberIn(LState, 0, 200);
    LOld.floordestheight := TestNumberIn(LState, -100, 100);
    LOld.speed := TestNumberIn(LState, 0, 100);
    LType := floor_e(TestNumberIn(LState, 0, Ord(High(floor_e))));
    // Doom has no such kinds: its floor_e would never give them
    if (AGame <> TPlatGame.Strife) and (LType in [raiseFloor64, raiseFloor512AndChange]) then
      LType := raiseFloor;
    LOld._type := LType;
    LOld.crush := False;
    LNew := LOld;
    LNewSector := LOldSector;

    if AGame = TPlatGame.Strife then
      OldStrifeSpawnFloor(@LOld, @LOldSector, @LLine, LType)
    else
      OldDoomSpawnFloor(@LOld, @LOldSector, @LLine, LType);
    NewSpawnFloor(@LNew, @LNewSector, @LLine, LType, LProfile, AVersion > VERSION115);

    LText := Format('case %d kind %d', [LCase, Ord(LType)]);
    Assert.AreEqual(LOld.crush, LNew.crush, 'crush of ' + LText);
    Assert.AreEqual(LOld.direction, LNew.direction, 'direction of ' + LText);
    Assert.AreEqual(LOld.speed, LNew.speed, 'speed of ' + LText);
    Assert.AreEqual(LOld.floordestheight, LNew.floordestheight, 'destination of ' + LText);
    Assert.AreEqual(LOld.newspecial, LNew.newspecial, 'new special of ' + LText);
    Assert.AreEqual<Integer>(LOld.oldspecial, LNew.oldspecial, 'old special of ' + LText);
    Assert.AreEqual<Integer>(LOld.texture, LNew.texture, 'texture of ' + LText);
    Assert.AreEqual(LOld.sector = @LOldSector, LNew.sector = @LNewSector, 'sector of ' + LText);
    Assert.AreEqual(LOldSector.floorpic, LNewSector.floorpic, 'sector texture of ' + LText);
    Assert.AreEqual(LOldSector.special, LNewSector.special, 'sector special of ' + LText);
    Assert.AreEqual(LOldSector.oldspecial, LNewSector.oldspecial,
      'sector old special of ' + LText);
  end;
end;

procedure TTestThinkersFloorMachine.CheckStairParity(AGame: TPlatGame; AVersion: Integer);
var
  LType: stair_e;
  LOldFirst, LOldNext, LNewFirst, LNewNext: floormove_t;
  LOldSpeed, LOldSize: Integer;
  LPlan: TStairPlan;
  LText: string;
begin
  OldFloorEngineVersion := AVersion;
  for LType := Low(stair_e) to High(stair_e) do
  begin
    // Doom has no stairs that go down: its stair_e would never give them
    if (AGame <> TPlatGame.Strife) and (LType = buildDown16) then
      Continue;
    FillChar(LOldFirst, SizeOf(floormove_t), 0);
    FillChar(LOldNext, SizeOf(floormove_t), 0);
    FillChar(LNewFirst, SizeOf(floormove_t), 0);
    FillChar(LNewNext, SizeOf(floormove_t), 0);
    if AGame = TPlatGame.Strife then
      OldStrifeStairs(LType, @LOldFirst, @LOldNext, LOldSpeed, LOldSize)
    else
      OldDoomStairs(LType, @LOldFirst, @LOldNext, LOldSpeed, LOldSize);

    // EV_BuildStairs as IdTech1\Base\p_floor.pas writes it now
    LPlan := TFloorMachine.StairPlan(StairOf(LType), AVersion > VERSION115,
      TFloorGames.ProfileOf(AGame));
    LNewFirst.direction := LPlan.Direction;
    if LPlan.FirstIsStair then
      LNewFirst._type := buildStair;
    LNewFirst.crush := LPlan.FirstCrush;
    LNewFirst.speed := LPlan.Speed;
    LNewNext.direction := LPlan.Direction;
    LNewNext.speed := LPlan.Speed;
    LNewNext._type := buildStair;
    LNewNext.crush := LPlan.NextCrush;

    LText := Format('stairs %d', [Ord(LType)]);
    Assert.AreEqual(LOldSpeed, LPlan.Speed, 'speed of ' + LText);
    Assert.AreEqual(LOldSize, LPlan.StepSize, 'step of ' + LText);
    Assert.AreEqual(AGame = TPlatGame.Strife, LPlan.ClearFirstTag, 'tag of ' + LText);
    Assert.AreEqual(Ord(LOldFirst._type), Ord(LNewFirst._type), 'first kind of ' + LText);
    Assert.AreEqual(LOldFirst.direction, LNewFirst.direction, 'first direction of ' + LText);
    Assert.AreEqual(LOldFirst.crush, LNewFirst.crush, 'first crush of ' + LText);
    Assert.AreEqual(LOldFirst.speed, LNewFirst.speed, 'first speed of ' + LText);
    Assert.AreEqual(Ord(LOldNext._type), Ord(LNewNext._type), 'next kind of ' + LText);
    Assert.AreEqual(LOldNext.direction, LNewNext.direction, 'next direction of ' + LText);
    Assert.AreEqual(LOldNext.crush, LNewNext.crush, 'next crush of ' + LText);
    Assert.AreEqual(LOldNext.speed, LNewNext.speed, 'next speed of ' + LText);
  end;
end;

procedure TTestThinkersFloorMachine.DovrebbeCreareIPavimentiComeIlVecchioCodiceDiDoom;
begin
  CheckSpawnParity(TPlatGame.Doom, MODERN_VERSION, 61);
end;

procedure TTestThinkersFloorMachine.DovrebbeCreareIPavimentiComeIlVecchioCodiceDiDoomVecchiaVersione;
begin
  CheckSpawnParity(TPlatGame.Doom, VERSION115, 62);
end;

procedure TTestThinkersFloorMachine.DovrebbeCreareIPavimentiComeIlVecchioCodiceDiStrife;
begin
  CheckSpawnParity(TPlatGame.Strife, MODERN_VERSION, 63);
end;

procedure TTestThinkersFloorMachine.DovrebbeCostruireLeScaleComeIlVecchioCodiceDiDoom;
begin
  CheckStairParity(TPlatGame.Doom, MODERN_VERSION);
end;

procedure TTestThinkersFloorMachine.DovrebbeCostruireLeScaleComeIlVecchioCodiceDiDoomVecchiaVersione;
begin
  CheckStairParity(TPlatGame.Doom, VERSION115);
end;

procedure TTestThinkersFloorMachine.DovrebbeCostruireLeScaleComeIlVecchioCodiceDiStrife;
begin
  CheckStairParity(TPlatGame.Strife, MODERN_VERSION);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersFloorMachine);

end.
