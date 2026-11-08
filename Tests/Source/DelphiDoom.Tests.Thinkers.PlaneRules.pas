{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the rules of the move of a plane per game              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlaneRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.Plane.Types;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersPlaneRules = class(TObject)
  strict private
    procedure CheckRules(const ARules: TPlaneMoveRules; AClampFloor, AClampCeiling,
      AFloorLowerRestores, AFloorRaiseKeeps, ACeilingLowerKeeps: Boolean; const AName: string);
  public
    [Test]
    procedure DovrebbeDareLeRegoleDiDoomRecente;
    [Test]
    procedure DovrebbeDareLeRegoleDiDoomDelleVecchieVersioni;
    [Test]
    procedure DovrebbeDareLeRegoleDiHeretic;
    [Test]
    procedure DovrebbeDareLeRegoleDiStrife;
    [Test]
    procedure DovrebbeDareLeRegoleDegliSpecialUdmfEDiHexen;
  end;

implementation

uses
  DelphiDoom.Thinkers.Plane.Rules;

{ TTestThinkersPlaneRules }

procedure TTestThinkersPlaneRules.CheckRules(const ARules: TPlaneMoveRules; AClampFloor,
  AClampCeiling, AFloorLowerRestores, AFloorRaiseKeeps, ACeilingLowerKeeps: Boolean;
  const AName: string);
begin
  Assert.AreEqual(AClampFloor, ARules.ClampFloorRaiseToCeiling, AName + ' clamp of the floor');
  Assert.AreEqual(AClampCeiling, ARules.ClampCeilingLowerToFloor, AName + ' clamp of the ceiling');
  Assert.AreEqual(AFloorLowerRestores, ARules.FloorLowerRestores, AName + ' floor that goes down');
  Assert.AreEqual(AFloorRaiseKeeps, ARules.FloorRaiseCrushKeeps, AName + ' floor that crushes');
  Assert.AreEqual(ACeilingLowerKeeps, ARules.CeilingLowerCrushKeeps, AName + ' ceiling that crushes');
end;

procedure TTestThinkersPlaneRules.DovrebbeDareLeRegoleDiDoomRecente;
begin
  CheckRules(TPlaneRules.Doom(True), True, True, True, False, True, 'doom');
end;

procedure TTestThinkersPlaneRules.DovrebbeDareLeRegoleDiDoomDelleVecchieVersioni;
begin
  CheckRules(TPlaneRules.Doom(False), False, False, True, True, True, 'old doom');
end;

procedure TTestThinkersPlaneRules.DovrebbeDareLeRegoleDiHeretic;
begin
  CheckRules(TPlaneRules.Heretic, False, False, True, True, True, 'heretic');
end;

procedure TTestThinkersPlaneRules.DovrebbeDareLeRegoleDiStrife;
begin
  CheckRules(TPlaneRules.Strife, True, True, False, True, True, 'strife');
end;

procedure TTestThinkersPlaneRules.DovrebbeDareLeRegoleDegliSpecialUdmfEDiHexen;
begin
  CheckRules(TPlaneRules.Udmf, False, False, True, False, False, 'udmf');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersPlaneRules);

end.
