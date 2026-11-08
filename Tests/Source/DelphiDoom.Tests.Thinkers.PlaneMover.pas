{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the step of a moving plane (T_MovePlane)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlaneMover;

// The heights of the random cases are large and the old code let the sums wrap
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.Plane.Types,
  DelphiDoom.Thinkers.Plane.Intf, DelphiDoom.Tests.Thinkers.OldPlanes,
  DelphiDoom.Tests.Thinkers.PlaneFakes;

type
  TOldMoveFunction = function(sector: Psector_t; speed: fixed_t; dest: fixed_t;
    crush: boolean; floorOrCeiling: integer; direction: integer): result_e;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersPlaneMover = class(TObject)
  strict private
    FHost: TFakePlaneHost;
    FHostIntf: IPlaneSectorHost;
    // the host that Move uses: it is FHostIntf, or a host of a parity test (FHost must stay referenced by FHostIntf)
    FCurrentHost: IPlaneSectorHost;
    procedure UseHostThatNeverBlocks;
    function Move(var ASector: sector_t; ASpeed, ADestination: Integer; ACrush: Boolean;
      AKind, ADirection: Integer; const ARules: TPlaneMoveRules): TPlaneMoveResult;
    procedure CheckParity(const ARules: TPlaneMoveRules; AOld: TOldMoveFunction;
      AVersion: Integer; ASeed: Cardinal);
    procedure CheckSequenceParity(const ARules: TPlaneMoveRules; AOld: TOldMoveFunction;
      AVersion: Integer; ASeed: Cardinal);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAbbassareIlPavimentoDiUnPasso;
    [Test]
    procedure DovrebbeFermareIlPavimentoCheScendeSullaDestinazione;
    [Test]
    procedure DovrebbeArrivareSullaDestinazioneSenzaSuperarla;
    [Test]
    procedure DovrebbeAlzareIlPavimentoDiUnPasso;
    [Test]
    procedure DovrebbeFermareIlPavimentoCheSaleSullaDestinazione;
    [Test]
    procedure DovrebbeRimettereIlPavimentoCheSaleSeQualcosaLoBlocca;
    [Test]
    procedure DovrebbeRimettereIlPavimentoCheSaleConIlSchiacciamentoNelleRegoleUdmf;
    [Test]
    procedure DovrebbeTenereIlPavimentoCheSaleConIlSchiacciamentoInHeretic;
    [Test]
    procedure DovrebbeTenereIlPavimentoCheSaleConIlSchiacciamentoSoloNelleVecchieVersioniDiDoom;
    [Test]
    procedure DovrebbeTenereIlPavimentoCheSaleConIlSchiacciamentoInStrife;
    [Test]
    procedure DovrebbeRimettereIlPavimentoCheScendeSeQualcosaLoBlocca;
    [Test]
    procedure DovrebbeLasciareIlPavimentoCheScendeBloccatoInStrife;
    [Test]
    procedure DovrebbeRimettereIlPavimentoSullaDestinazioneSoloDoveLeRegoleLoDicono;
    [Test]
    procedure DovrebbeAbbassareIlSoffittoDiUnPasso;
    [Test]
    procedure DovrebbeRimettereIlSoffittoCheScendeSeNonSchiaccia;
    [Test]
    procedure DovrebbeTenereIlSoffittoCheScendeConIlSchiacciamentoDoveLeRegoleLoDicono;
    [Test]
    procedure DovrebbeRimettereIlSoffittoSullaDestinazioneSeBloccato;
    [Test]
    procedure DovrebbeAlzareIlSoffittoAncheSeBloccato;
    [Test]
    procedure DovrebbeFermareIlSoffittoCheSaleSullaDestinazione;
    [Test]
    procedure DovrebbeLimitareIlPavimentoCheSaleAlSoffittoDoveLeRegoleLoDicono;
    [Test]
    procedure DovrebbeLimitareIlSoffittoCheScendeAlPavimentoDoveLeRegoleLoDicono;
    [Test]
    procedure DovrebbeNonFareNullaConDirezioneZero;
    [Test]
    procedure DovrebbeDareIlSettoreAlHostCosiCom;
    [Test]
    procedure DovrebbeAggiornarePendenzeSoloQuandoIlPassoFinisceBene;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiDoomVecchiaVersione;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiUdmf;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiDoomPerTuttoUnMovimento;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiDoomVecchiaVersionePerTuttoUnMovimento;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiHereticPerTuttoUnMovimento;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiStrifePerTuttoUnMovimento;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiUdmfPerTuttoUnMovimento;
  end;

implementation

uses
  DelphiDoom.Thinkers.Plane.Rules, DelphiDoom.Thinkers.Plane.Mover;

const
  FLOOR_PLANE = 0;
  CEILING_PLANE = 1;
  THING_HEIGHT = 56;

function MakeSector(AFloor, ACeiling: Integer): sector_t;
begin
  Result.floorheight := AFloor;
  Result.ceilingheight := ACeiling;
end;

function ResultOfOld(AResult: result_e): TPlaneMoveResult;
begin
  case AResult of
    crushed, RES_CRUSHED:
      Result := TPlaneMoveResult.Crushed;
    pastdest, RES_PASTDEST:
      Result := TPlaneMoveResult.PastDest;
  else
    Result := TPlaneMoveResult.Ok;
  end;
end;

{ TTestThinkersPlaneMover }

procedure TTestThinkersPlaneMover.Setup;
begin
  FHost := TFakePlaneHost.Create(THING_HEIGHT);
  FHostIntf := FHost;
  FCurrentHost := FHostIntf;
end;

procedure TTestThinkersPlaneMover.TearDown;
begin
  OldPlaneHost := nil;
  FCurrentHost := nil;
  FHostIntf := nil;
  FHost := nil;
end;

procedure TTestThinkersPlaneMover.UseHostThatNeverBlocks;
begin
  // a sector is blocked when its gap is smaller than the height of a thing: with a negative
  // height not even a ceiling below the floor is
  FCurrentHost := nil;
  FHostIntf := nil;
  FHost := TFakePlaneHost.Create(-1000);
  FHostIntf := FHost;
  FCurrentHost := FHostIntf;
end;

function TTestThinkersPlaneMover.Move(var ASector: sector_t; ASpeed, ADestination: Integer;
  ACrush: Boolean; AKind, ADirection: Integer; const ARules: TPlaneMoveRules): TPlaneMoveResult;
begin
  // the same choice of the plane that PlaneMove makes in the engine
  case AKind of
    FLOOR_PLANE:
      Result := TPlaneMover.Move(ASector.floorheight, ASector.ceilingheight, ASpeed,
        ADestination, ACrush, TPlaneKind.Floor, ADirection, ARules, FCurrentHost, @ASector);
    CEILING_PLANE:
      Result := TPlaneMover.Move(ASector.ceilingheight, ASector.floorheight, ASpeed,
        ADestination, ACrush, TPlaneKind.Ceiling, ADirection, ARules, FCurrentHost, @ASector);
  else
    FCurrentHost.PlaneMoved(@ASector);
    Result := TPlaneMoveResult.Ok;
  end;
end;

procedure TTestThinkersPlaneMover.DovrebbeAbbassareIlPavimentoDiUnPasso;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Udmf)));
  Assert.AreEqual(92, LSector.floorheight, 'floor');
  Assert.AreEqual(200, LSector.ceilingheight, 'ceiling');
  Assert.AreEqual(1, FHost.ChangeCount, 'changes');
  Assert.AreEqual(1, FHost.MovedCount, 'slopes');
end;

procedure TTestThinkersPlaneMover.DovrebbeFermareIlPavimentoCheScendeSullaDestinazione;
var
  LSector: sector_t;
begin
  LSector := MakeSector(4, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Udmf)));
  Assert.AreEqual(0, LSector.floorheight, 'floor');
  Assert.AreEqual(1, FHost.ChangeCount, 'changes');
  Assert.AreEqual(0, FHost.MovedCount, 'slopes');
end;

procedure TTestThinkersPlaneMover.DovrebbeArrivareSullaDestinazioneSenzaSuperarla;
var
  LSector: sector_t;
begin
  LSector := MakeSector(8, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Udmf)), 'first');
  Assert.AreEqual(0, LSector.floorheight, 'floor');
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Udmf)), 'second');
  Assert.AreEqual(0, LSector.floorheight, 'floor after');
end;

procedure TTestThinkersPlaneMover.DovrebbeAlzareIlPavimentoDiUnPasso;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 150, False, FLOOR_PLANE, 1, TPlaneRules.Udmf)));
  Assert.AreEqual(108, LSector.floorheight, 'floor');
  Assert.AreEqual(1, FHost.ChangeCount, 'changes');
  Assert.AreEqual(1, FHost.MovedCount, 'slopes');
end;

procedure TTestThinkersPlaneMover.DovrebbeFermareIlPavimentoCheSaleSullaDestinazione;
var
  LSector: sector_t;
begin
  LSector := MakeSector(148, 300);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 150, False, FLOOR_PLANE, 1, TPlaneRules.Udmf)));
  Assert.AreEqual(150, LSector.floorheight, 'floor');
  Assert.AreEqual(1, FHost.ChangeCount, 'changes');
  Assert.AreEqual(0, FHost.MovedCount, 'slopes');
end;

procedure TTestThinkersPlaneMover.DovrebbeRimettereIlPavimentoCheSaleSeQualcosaLoBlocca;
var
  LSector: sector_t;
begin
  // the gap is 50 and a thing needs 56: it is blocked at once
  LSector := MakeSector(100, 150);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 140, False, FLOOR_PLANE, 1, TPlaneRules.Udmf)));
  Assert.AreEqual(100, LSector.floorheight, 'floor');
  Assert.AreEqual(2, FHost.ChangeCount, 'the sector is changed again after the undo');
  Assert.AreEqual(0, FHost.MovedCount, 'slopes');
end;

procedure TTestThinkersPlaneMover.DovrebbeRimettereIlPavimentoCheSaleConIlSchiacciamentoNelleRegoleUdmf;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 150);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 140, True, FLOOR_PLANE, 1, TPlaneRules.Udmf)));
  Assert.AreEqual(100, LSector.floorheight, 'floor');
  Assert.AreEqual(2, FHost.ChangeCount, 'changes');
end;

procedure TTestThinkersPlaneMover.DovrebbeTenereIlPavimentoCheSaleConIlSchiacciamentoInHeretic;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 150);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 140, True, FLOOR_PLANE, 1, TPlaneRules.Heretic)));
  Assert.AreEqual(108, LSector.floorheight, 'kept');
  Assert.AreEqual(1, FHost.ChangeCount, 'changes');

  FHost.Clear;
  LSector := MakeSector(100, 150);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 140, False, FLOOR_PLANE, 1, TPlaneRules.Heretic)));
  Assert.AreEqual(100, LSector.floorheight, 'undone without the crush flag');
  Assert.AreEqual(2, FHost.ChangeCount, 'changes without the crush flag');
end;

procedure TTestThinkersPlaneMover.DovrebbeTenereIlPavimentoCheSaleConIlSchiacciamentoSoloNelleVecchieVersioniDiDoom;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 150);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 140, True, FLOOR_PLANE, 1, TPlaneRules.Doom(False))));
  Assert.AreEqual(108, LSector.floorheight, 'old versions keep it');

  LSector := MakeSector(100, 150);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 140, True, FLOOR_PLANE, 1, TPlaneRules.Doom(True))));
  Assert.AreEqual(100, LSector.floorheight, 'new versions undo it');
end;

procedure TTestThinkersPlaneMover.DovrebbeTenereIlPavimentoCheSaleConIlSchiacciamentoInStrife;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 150);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 140, True, FLOOR_PLANE, 1, TPlaneRules.Strife)));
  Assert.AreEqual(108, LSector.floorheight, 'kept');

  LSector := MakeSector(100, 150);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 140, False, FLOOR_PLANE, 1, TPlaneRules.Strife)));
  Assert.AreEqual(100, LSector.floorheight, 'undone without the crush flag');
end;

procedure TTestThinkersPlaneMover.DovrebbeRimettereIlPavimentoCheScendeSeQualcosaLoBlocca;
var
  LSector: sector_t;
begin
  FHost.BlockAll := True;
  LSector := MakeSector(100, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Udmf)), 'udmf');
  Assert.AreEqual(100, LSector.floorheight, 'udmf floor');
  Assert.AreEqual(2, FHost.ChangeCount, 'udmf changes');

  LSector := MakeSector(100, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 0, True, FLOOR_PLANE, -1, TPlaneRules.Heretic)), 'heretic');
  Assert.AreEqual(100, LSector.floorheight, 'heretic floor');

  LSector := MakeSector(100, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 0, True, FLOOR_PLANE, -1, TPlaneRules.Doom(True))), 'doom');
  Assert.AreEqual(100, LSector.floorheight, 'doom floor');
end;

procedure TTestThinkersPlaneMover.DovrebbeLasciareIlPavimentoCheScendeBloccatoInStrife;
var
  LSector: sector_t;
begin
  FHost.BlockAll := True;
  LSector := MakeSector(100, 200);
  // the floor stays where it moved and the step is reported as a normal one
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 0, True, FLOOR_PLANE, -1, TPlaneRules.Strife)));
  Assert.AreEqual(92, LSector.floorheight, 'floor');
  Assert.AreEqual(1, FHost.ChangeCount, 'changes');
  Assert.AreEqual(1, FHost.MovedCount, 'slopes');
end;

procedure TTestThinkersPlaneMover.DovrebbeRimettereIlPavimentoSullaDestinazioneSoloDoveLeRegoleLoDicono;
var
  LSector: sector_t;
begin
  FHost.BlockAll := True;
  LSector := MakeSector(4, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Udmf)), 'udmf');
  Assert.AreEqual(4, LSector.floorheight, 'udmf floor');
  Assert.AreEqual(2, FHost.ChangeCount, 'udmf changes');

  FHost.Clear;
  LSector := MakeSector(4, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Strife)), 'strife');
  Assert.AreEqual(0, LSector.floorheight, 'strife floor');
  Assert.AreEqual(1, FHost.ChangeCount, 'strife changes');
end;

procedure TTestThinkersPlaneMover.DovrebbeAbbassareIlSoffittoDiUnPasso;
var
  LSector: sector_t;
begin
  LSector := MakeSector(0, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 100, False, CEILING_PLANE, -1, TPlaneRules.Udmf)));
  Assert.AreEqual(192, LSector.ceilingheight, 'ceiling');
  Assert.AreEqual(0, LSector.floorheight, 'floor');
  Assert.AreEqual(1, FHost.MovedCount, 'slopes');
end;

procedure TTestThinkersPlaneMover.DovrebbeRimettereIlSoffittoCheScendeSeNonSchiaccia;
var
  LSector: sector_t;
begin
  FHost.BlockAll := True;
  LSector := MakeSector(0, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 100, False, CEILING_PLANE, -1, TPlaneRules.Doom(True))));
  Assert.AreEqual(200, LSector.ceilingheight, 'ceiling');
  Assert.AreEqual(2, FHost.ChangeCount, 'changes');
end;

procedure TTestThinkersPlaneMover.DovrebbeTenereIlSoffittoCheScendeConIlSchiacciamentoDoveLeRegoleLoDicono;
var
  LSector: sector_t;
begin
  FHost.BlockAll := True;
  LSector := MakeSector(0, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 100, True, CEILING_PLANE, -1, TPlaneRules.Doom(True))), 'doom');
  Assert.AreEqual(192, LSector.ceilingheight, 'doom ceiling');

  FHost.Clear;
  LSector := MakeSector(0, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 100, True, CEILING_PLANE, -1, TPlaneRules.Heretic)), 'heretic');
  Assert.AreEqual(192, LSector.ceilingheight, 'heretic ceiling');

  LSector := MakeSector(0, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 100, True, CEILING_PLANE, -1, TPlaneRules.Strife)), 'strife');
  Assert.AreEqual(192, LSector.ceilingheight, 'strife ceiling');

  FHost.Clear;
  LSector := MakeSector(0, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Crushed),
    Ord(Move(LSector, 8, 100, True, CEILING_PLANE, -1, TPlaneRules.Udmf)), 'udmf');
  Assert.AreEqual(200, LSector.ceilingheight, 'udmf ceiling is put back');
  Assert.AreEqual(2, FHost.ChangeCount, 'udmf changes');
end;

procedure TTestThinkersPlaneMover.DovrebbeRimettereIlSoffittoSullaDestinazioneSeBloccato;
var
  LSector: sector_t;
begin
  FHost.BlockAll := True;
  LSector := MakeSector(0, 204);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 200, True, CEILING_PLANE, -1, TPlaneRules.Doom(True))));
  Assert.AreEqual(204, LSector.ceilingheight, 'ceiling');
  Assert.AreEqual(2, FHost.ChangeCount, 'changes');
end;

procedure TTestThinkersPlaneMover.DovrebbeAlzareIlSoffittoAncheSeBloccato;
var
  LSector: sector_t;
begin
  FHost.BlockAll := True;
  LSector := MakeSector(0, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 300, True, CEILING_PLANE, 1, TPlaneRules.Udmf)));
  Assert.AreEqual(208, LSector.ceilingheight, 'ceiling');
  Assert.AreEqual(1, FHost.ChangeCount, 'changes');
  Assert.AreEqual(1, FHost.MovedCount, 'slopes');
end;

procedure TTestThinkersPlaneMover.DovrebbeFermareIlSoffittoCheSaleSullaDestinazione;
var
  LSector: sector_t;
begin
  LSector := MakeSector(0, 296);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 300, False, CEILING_PLANE, 1, TPlaneRules.Udmf)));
  Assert.AreEqual(300, LSector.ceilingheight, 'ceiling');
  Assert.AreEqual(0, FHost.MovedCount, 'slopes');

  FHost.Clear;
  FHost.BlockAll := True;
  LSector := MakeSector(0, 296);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 300, False, CEILING_PLANE, 1, TPlaneRules.Udmf)));
  Assert.AreEqual(296, LSector.ceilingheight, 'ceiling put back');
  Assert.AreEqual(2, FHost.ChangeCount, 'changes');
end;

procedure TTestThinkersPlaneMover.DovrebbeLimitareIlPavimentoCheSaleAlSoffittoDoveLeRegoleLoDicono;
var
  LSector: sector_t;
begin
  UseHostThatNeverBlocks;
  // 116 + 8 is over the ceiling (120) and the destination (500) is too
  LSector := MakeSector(116, 120);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 500, False, FLOOR_PLANE, 1, TPlaneRules.Strife)), 'strife');
  Assert.AreEqual(120, LSector.floorheight, 'strife floor');

  LSector := MakeSector(116, 120);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 500, False, FLOOR_PLANE, 1, TPlaneRules.Doom(True))), 'doom');
  Assert.AreEqual(120, LSector.floorheight, 'doom floor');

  LSector := MakeSector(116, 124);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 500, False, FLOOR_PLANE, 1, TPlaneRules.Udmf)), 'udmf');
  Assert.AreEqual(124, LSector.floorheight, 'udmf floor goes on');

  LSector := MakeSector(116, 124);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 500, False, FLOOR_PLANE, 1, TPlaneRules.Doom(False))), 'old doom');
  Assert.AreEqual(124, LSector.floorheight, 'old doom floor goes on');

  LSector := MakeSector(116, 124);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 500, False, FLOOR_PLANE, 1, TPlaneRules.Heretic)), 'heretic');
  Assert.AreEqual(124, LSector.floorheight, 'heretic floor goes on');
end;

procedure TTestThinkersPlaneMover.DovrebbeLimitareIlSoffittoCheScendeAlPavimentoDoveLeRegoleLoDicono;
var
  LSector: sector_t;
begin
  UseHostThatNeverBlocks;
  LSector := MakeSector(120, 124);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 0, False, CEILING_PLANE, -1, TPlaneRules.Strife)), 'strife');
  Assert.AreEqual(120, LSector.ceilingheight, 'strife ceiling');

  LSector := MakeSector(120, 124);
  Assert.AreEqual(Ord(TPlaneMoveResult.PastDest),
    Ord(Move(LSector, 8, 0, False, CEILING_PLANE, -1, TPlaneRules.Doom(True))), 'doom');
  Assert.AreEqual(120, LSector.ceilingheight, 'doom ceiling');

  LSector := MakeSector(120, 124);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 0, False, CEILING_PLANE, -1, TPlaneRules.Udmf)), 'udmf');
  Assert.AreEqual(116, LSector.ceilingheight, 'udmf ceiling goes on');

  LSector := MakeSector(120, 124);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 0, False, CEILING_PLANE, -1, TPlaneRules.Doom(False))), 'old doom');
  Assert.AreEqual(116, LSector.ceilingheight, 'old doom ceiling goes on');
end;

procedure TTestThinkersPlaneMover.DovrebbeNonFareNullaConDirezioneZero;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 200);
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 0, False, FLOOR_PLANE, 0, TPlaneRules.Udmf)), 'floor');
  Assert.AreEqual(Ord(TPlaneMoveResult.Ok),
    Ord(Move(LSector, 8, 0, False, CEILING_PLANE, 0, TPlaneRules.Udmf)), 'ceiling');
  Assert.AreEqual(100, LSector.floorheight, 'floor height');
  Assert.AreEqual(200, LSector.ceilingheight, 'ceiling height');
  Assert.AreEqual(0, FHost.ChangeCount, 'no sector change');
  Assert.AreEqual(2, FHost.MovedCount, 'the slopes are updated as the old code did');
end;

procedure TTestThinkersPlaneMover.DovrebbeDareIlSettoreAlHostCosiCom;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 200);
  Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Udmf);
  Assert.IsTrue(FHost.LastSector = @LSector, 'the pointer of the sector');
end;

procedure TTestThinkersPlaneMover.DovrebbeAggiornarePendenzeSoloQuandoIlPassoFinisceBene;
var
  LSector: sector_t;
begin
  LSector := MakeSector(100, 150);
  Move(LSector, 8, 140, False, FLOOR_PLANE, 1, TPlaneRules.Udmf);
  Assert.AreEqual(0, FHost.MovedCount, 'crushed');
  Move(LSector, 8, 0, False, FLOOR_PLANE, -1, TPlaneRules.Udmf);
  Assert.AreEqual(1, FHost.MovedCount, 'moved');
end;

procedure TTestThinkersPlaneMover.CheckParity(const ARules: TPlaneMoveRules;
  AOld: TOldMoveFunction; AVersion: Integer; ASeed: Cardinal);
var
  LState: Cardinal;
  LCase: Integer;
  LOldHost, LNewHost: TFakePlaneHost;
  LOldIntf, LNewIntf: IPlaneSectorHost;
  LOldSector, LNewSector: sector_t;
  LSpeed, LDest, LKind, LDirection: Integer;
  LCrush: Boolean;
  LOldResult, LNewResult: TPlaneMoveResult;
  LText: string;
begin
  LState := ASeed;
  LOldHost := TFakePlaneHost.Create(3 * 65536);
  LOldIntf := LOldHost;
  LNewHost := TFakePlaneHost.Create(3 * 65536);
  LNewIntf := LNewHost;
  OldEngineVersion := AVersion;
  OldPlaneHost := LOldIntf;
  try
    for LCase := 1 to 20000 do
    begin
      LOldSector.floorheight := TestNumberIn(LState, -8 * 65536, 8 * 65536);
      LOldSector.ceilingheight := LOldSector.floorheight + TestNumberIn(LState, 0, 8 * 65536);
      if TestNumberIn(LState, 0, 19) = 0 then
      begin
        // a few extreme values: the sums wrap in the same way
        LOldSector.floorheight := TestNumberIn(LState, -MaxInt, MaxInt);
        LOldSector.ceilingheight := TestNumberIn(LState, -MaxInt, MaxInt);
      end;
      LNewSector := LOldSector;
      LSpeed := TestNumberIn(LState, 0, 4 * 65536);
      LDest := TestNumberIn(LState, -10 * 65536, 10 * 65536);
      LCrush := TestNumberIn(LState, 0, 1) = 1;
      LKind := TestNumberIn(LState, 0, 2);
      LDirection := TestNumberIn(LState, -2, 2);
      LOldHost.BlockAll := TestNumberIn(LState, 0, 4) = 0;
      LNewHost.BlockAll := LOldHost.BlockAll;
      LOldHost.Clear;
      LNewHost.Clear;
      // the old function writes through the pointer to the sector
      LOldResult := ResultOfOld(AOld(@LOldSector, LSpeed, LDest, LCrush, LKind, LDirection));
      FCurrentHost := LNewIntf;
      LNewResult := Move(LNewSector, LSpeed, LDest, LCrush, LKind, LDirection, ARules);
      LText := Format('case %d (kind %d, direction %d, crush %d, speed %d, destination %d)',
        [LCase, LKind, LDirection, Ord(LCrush), LSpeed, LDest]);
      Assert.AreEqual(Ord(LOldResult), Ord(LNewResult), 'result of ' + LText);
      Assert.AreEqual(LOldSector.floorheight, LNewSector.floorheight, 'floor of ' + LText);
      Assert.AreEqual(LOldSector.ceilingheight, LNewSector.ceilingheight, 'ceiling of ' + LText);
      Assert.AreEqual(LOldHost.Log, LNewHost.Log, 'calls of ' + LText);
    end;
  finally
    OldPlaneHost := nil;
    FCurrentHost := FHostIntf;
  end;
end;

procedure TTestThinkersPlaneMover.CheckSequenceParity(const ARules: TPlaneMoveRules;
  AOld: TOldMoveFunction; AVersion: Integer; ASeed: Cardinal);
var
  LState: Cardinal;
  LRun, LStep: Integer;
  LOldHost, LNewHost: TFakePlaneHost;
  LOldIntf, LNewIntf: IPlaneSectorHost;
  LOldSector, LNewSector: sector_t;
  LSpeed, LDest, LKind, LDirection, LStart: Integer;
  LCrush: Boolean;
  LOldResult, LNewResult: TPlaneMoveResult;
  LText: string;
begin
  LState := ASeed;
  LOldHost := TFakePlaneHost.Create(3 * 65536);
  LOldIntf := LOldHost;
  LNewHost := TFakePlaneHost.Create(3 * 65536);
  LNewIntf := LNewHost;
  OldEngineVersion := AVersion;
  OldPlaneHost := LOldIntf;
  try
    for LRun := 1 to 300 do
    begin
      LOldSector.floorheight := TestNumberIn(LState, -4 * 65536, 4 * 65536);
      LOldSector.ceilingheight := LOldSector.floorheight + TestNumberIn(LState, 0, 8 * 65536);
      LNewSector := LOldSector;
      LKind := TestNumberIn(LState, 0, 1);
      LSpeed := TestNumberIn(LState, 1, 2 * 65536);
      LDest := TestNumberIn(LState, -10 * 65536, 10 * 65536);
      LCrush := TestNumberIn(LState, 0, 1) = 1;
      LOldHost.BlockAll := TestNumberIn(LState, 0, 6) = 0;
      LNewHost.BlockAll := LOldHost.BlockAll;
      if LKind = FLOOR_PLANE then
        LStart := LOldSector.floorheight
      else
        LStart := LOldSector.ceilingheight;
      if LDest >= LStart then
        LDirection := 1
      else
        LDirection := -1;
      FCurrentHost := LNewIntf;
      for LStep := 1 to 400 do
      begin
        LOldHost.Clear;
        LNewHost.Clear;
        LOldResult := ResultOfOld(AOld(@LOldSector, LSpeed, LDest, LCrush, LKind, LDirection));
        LNewResult := Move(LNewSector, LSpeed, LDest, LCrush, LKind, LDirection, ARules);
        LText := Format('run %d step %d (kind %d, direction %d)', [LRun, LStep, LKind, LDirection]);
        Assert.AreEqual(Ord(LOldResult), Ord(LNewResult), 'result of ' + LText);
        Assert.AreEqual(LOldSector.floorheight, LNewSector.floorheight, 'floor of ' + LText);
        Assert.AreEqual(LOldSector.ceilingheight, LNewSector.ceilingheight, 'ceiling of ' + LText);
        Assert.AreEqual(LOldHost.Log, LNewHost.Log, 'calls of ' + LText);
        if LNewResult = TPlaneMoveResult.PastDest then
          Break;
      end;
    end;
  finally
    OldPlaneHost := nil;
    FCurrentHost := FHostIntf;
  end;
end;

procedure TTestThinkersPlaneMover.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiDoom;
begin
  CheckParity(TPlaneRules.Doom(True), OldDoomMovePlane, 207, 11);
end;

procedure TTestThinkersPlaneMover.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiDoomVecchiaVersione;
begin
  CheckParity(TPlaneRules.Doom(False), OldDoomMovePlane, VERSION115, 12);
end;

procedure TTestThinkersPlaneMover.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiHeretic;
begin
  CheckParity(TPlaneRules.Heretic, OldHereticMovePlane, 207, 13);
end;

procedure TTestThinkersPlaneMover.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiStrife;
begin
  CheckParity(TPlaneRules.Strife, OldStrifeMovePlane, 207, 14);
end;

procedure TTestThinkersPlaneMover.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiUdmf;
begin
  CheckParity(TPlaneRules.Udmf, OldUdmfMovePlane, 207, 15);
end;

procedure TTestThinkersPlaneMover.DovrebbeSeguireIlVecchioCodiceDiDoomPerTuttoUnMovimento;
begin
  CheckSequenceParity(TPlaneRules.Doom(True), OldDoomMovePlane, 207, 21);
end;

procedure TTestThinkersPlaneMover.DovrebbeSeguireIlVecchioCodiceDiDoomVecchiaVersionePerTuttoUnMovimento;
begin
  CheckSequenceParity(TPlaneRules.Doom(False), OldDoomMovePlane, VERSION115, 22);
end;

procedure TTestThinkersPlaneMover.DovrebbeSeguireIlVecchioCodiceDiHereticPerTuttoUnMovimento;
begin
  CheckSequenceParity(TPlaneRules.Heretic, OldHereticMovePlane, 207, 23);
end;

procedure TTestThinkersPlaneMover.DovrebbeSeguireIlVecchioCodiceDiStrifePerTuttoUnMovimento;
begin
  CheckSequenceParity(TPlaneRules.Strife, OldStrifeMovePlane, 207, 24);
end;

procedure TTestThinkersPlaneMover.DovrebbeSeguireIlVecchioCodiceDiUdmfPerTuttoUnMovimento;
begin
  CheckSequenceParity(TPlaneRules.Udmf, OldUdmfMovePlane, 207, 25);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersPlaneMover);

end.
