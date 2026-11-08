{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the height of a thing after a teleport                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.TeleportPlacement;

// The old branches are written in the test as they were in udmf_telept.pas, with wrapping
// arithmetic as in the engine
{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework, DelphiDoom.Thinkers.Teleport.Placement;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersTeleportPlacement = class(TObject)
  private
    function Make(AIsPlayer, AIsMissile, AIsFlying: Boolean; AAboveFloor: Integer;
      AUseFog: Boolean): TTeleportSettleInput;
  public
    [Test]
    procedure DovrebbeMettereUnaCosaNormaleSulPavimento;
    [Test]
    procedure DovrebbeMettereUnGiocatoreSulPavimentoEAggiornareLaVista;
    [Test]
    procedure DovrebbeAzzerareLoSguardoSoloSeCeLaNebbia;
    [Test]
    procedure DovrebbeTenereLAltezzaDelGiocatoreCheVola;
    [Test]
    procedure DovrebbeNonSuperareIlSoffittoConUnGiocatoreCheVola;
    [Test]
    procedure DovrebbeTenereLAltezzaDiUnMissile;
    [Test]
    procedure DovrebbeNonSuperareIlSoffittoConUnMissile;
    [Test]
    procedure DovrebbeMettereSulPavimentoUnGiocatoreCheVolaAPavimento;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodice;
  end;

implementation

const
  FRACUNIT = 65536;

var
  GSeed: Cardinal;

function NextValue: Cardinal;
begin
  GSeed := GSeed * 1664525 + 1013904223;
  Result := GSeed;
end;

/// <summary>The branches of PH_Teleport that set the height, as they were</summary>
procedure OldSettle(const AInput: TTeleportSettleInput; out AZ: Integer; out AViewUpdated,
  ALookReset: Boolean);
begin
  AViewUpdated := False;
  ALookReset := False;
  if AInput.IsPlayer then
  begin
    if AInput.IsFlying and (AInput.AboveFloor <> 0) then
    begin
      AZ := AInput.FloorZ + AInput.AboveFloor;
      if AZ + AInput.Height > AInput.CeilingZ then
        AZ := AInput.CeilingZ - AInput.Height;
      AViewUpdated := True;
    end
    else
    begin
      AZ := AInput.FloorZ;
      AViewUpdated := True;
      if AInput.UseFog then
        ALookReset := True;
    end;
  end
  else if AInput.IsMissile then
  begin
    AZ := AInput.FloorZ + AInput.AboveFloor;
    if AZ + AInput.Height > AInput.CeilingZ then
      AZ := AInput.CeilingZ - AInput.Height;
  end
  else
    AZ := AInput.FloorZ;
end;

{ TTestThinkersTeleportPlacement }

function TTestThinkersTeleportPlacement.Make(AIsPlayer, AIsMissile, AIsFlying: Boolean;
  AAboveFloor: Integer; AUseFog: Boolean): TTeleportSettleInput;
begin
  Result.IsPlayer := AIsPlayer;
  Result.IsMissile := AIsMissile;
  Result.IsFlying := AIsFlying;
  Result.AboveFloor := AAboveFloor;
  Result.FloorZ := 16 * FRACUNIT;
  Result.CeilingZ := 120 * FRACUNIT;
  Result.Height := 56 * FRACUNIT;
  Result.UseFog := AUseFog;
end;

procedure TTestThinkersTeleportPlacement.DovrebbeMettereUnaCosaNormaleSulPavimento;
var
  LOutput: TTeleportSettleOutput;
begin
  TTeleportPlacement.Settle(Make(False, False, False, 10 * FRACUNIT, True), LOutput);
  Assert.AreEqual(16 * FRACUNIT, LOutput.Z);
  Assert.IsFalse(LOutput.UpdatesViewHeight);
  Assert.IsFalse(LOutput.ResetsLook);
end;

procedure TTestThinkersTeleportPlacement.DovrebbeMettereUnGiocatoreSulPavimentoEAggiornareLaVista;
var
  LOutput: TTeleportSettleOutput;
begin
  TTeleportPlacement.Settle(Make(True, False, False, 10 * FRACUNIT, True), LOutput);
  Assert.AreEqual(16 * FRACUNIT, LOutput.Z);
  Assert.IsTrue(LOutput.UpdatesViewHeight);
  Assert.IsTrue(LOutput.ResetsLook);
end;

procedure TTestThinkersTeleportPlacement.DovrebbeAzzerareLoSguardoSoloSeCeLaNebbia;
var
  LOutput: TTeleportSettleOutput;
begin
  TTeleportPlacement.Settle(Make(True, False, False, 0, False), LOutput);
  Assert.IsTrue(LOutput.UpdatesViewHeight);
  Assert.IsFalse(LOutput.ResetsLook);
end;

procedure TTestThinkersTeleportPlacement.DovrebbeTenereLAltezzaDelGiocatoreCheVola;
var
  LOutput: TTeleportSettleOutput;
begin
  TTeleportPlacement.Settle(Make(True, False, True, 20 * FRACUNIT, True), LOutput);
  Assert.AreEqual(36 * FRACUNIT, LOutput.Z);
  Assert.IsTrue(LOutput.UpdatesViewHeight);
  Assert.IsFalse(LOutput.ResetsLook, 'a flying player keeps looking where it looked');
end;

procedure TTestThinkersTeleportPlacement.DovrebbeNonSuperareIlSoffittoConUnGiocatoreCheVola;
var
  LOutput: TTeleportSettleOutput;
begin
  TTeleportPlacement.Settle(Make(True, False, True, 90 * FRACUNIT, True), LOutput);
  Assert.AreEqual((120 - 56) * FRACUNIT, LOutput.Z);
end;

procedure TTestThinkersTeleportPlacement.DovrebbeTenereLAltezzaDiUnMissile;
var
  LOutput: TTeleportSettleOutput;
begin
  TTeleportPlacement.Settle(Make(False, True, False, 8 * FRACUNIT, True), LOutput);
  Assert.AreEqual(24 * FRACUNIT, LOutput.Z);
  Assert.IsFalse(LOutput.UpdatesViewHeight);
end;

procedure TTestThinkersTeleportPlacement.DovrebbeNonSuperareIlSoffittoConUnMissile;
var
  LOutput: TTeleportSettleOutput;
begin
  TTeleportPlacement.Settle(Make(False, True, False, 100 * FRACUNIT, True), LOutput);
  Assert.AreEqual((120 - 56) * FRACUNIT, LOutput.Z);
end;

procedure TTestThinkersTeleportPlacement.DovrebbeMettereSulPavimentoUnGiocatoreCheVolaAPavimento;
var
  LOutput: TTeleportSettleOutput;
begin
  TTeleportPlacement.Settle(Make(True, False, True, 0, True), LOutput);
  Assert.AreEqual(16 * FRACUNIT, LOutput.Z);
  Assert.IsTrue(LOutput.ResetsLook);
end;

procedure TTestThinkersTeleportPlacement.DovrebbeDareGliStessiRisultatiDelVecchioCodice;
var
  LIndex: Integer;
  LInput: TTeleportSettleInput;
  LOutput: TTeleportSettleOutput;
  LZ: Integer;
  LView, LLook: Boolean;
begin
  GSeed := 5;
  for LIndex := 1 to 20000 do
  begin
    LInput.IsPlayer := (NextValue and 1) = 1;
    LInput.IsMissile := (NextValue and 1) = 1;
    LInput.IsFlying := (NextValue and 1) = 1;
    LInput.UseFog := (NextValue and 1) = 1;
    LInput.AboveFloor := (Integer(NextValue) shr 10) - 2000000;
    LInput.FloorZ := (Integer(NextValue) shr 10) - 2000000;
    LInput.CeilingZ := (Integer(NextValue) shr 10) - 2000000;
    LInput.Height := Integer(NextValue) shr 12;
    OldSettle(LInput, LZ, LView, LLook);
    TTeleportPlacement.Settle(LInput, LOutput);
    Assert.AreEqual(LZ, LOutput.Z, 'z');
    Assert.AreEqual(LView, LOutput.UpdatesViewHeight, 'view');
    Assert.AreEqual(LLook, LOutput.ResetsLook, 'look');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersTeleportPlacement);

end.
