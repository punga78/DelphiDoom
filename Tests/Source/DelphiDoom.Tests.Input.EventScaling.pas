{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scaling of the mouse and joystick events           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Input.EventScaling;

// The old expression wraps as well
{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework, DelphiDoom.Input.EventScaling;

type
  [TestFixture]
  [Category('input')]
  TTestInputEventScaling = class
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDelMouse;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDelJoystick;
    [Test]
    procedure DovrebbeDareZeroSenzaMovimento;
    [Test]
    procedure DovrebbeSpegnereITastiSeLaMaschera0;
  end;

implementation

uses
  System.SysUtils;

const
  NUMJOYBUTTONS = 12;

procedure TTestInputEventScaling.DovrebbeEssereUgualeAlVecchioCodiceDelMouse;
var
  LMotion, LSensitivity, LAxis: Integer;
  LOld: Integer;
begin
  for LMotion := -300 to 300 do
    for LSensitivity := 0 to 20 do
      for LAxis := 0 to 12 do
      begin
        // the old line of G_Responder of the four games
        LOld := ((LMotion * (LSensitivity + 5)) div 10) * LAxis div 5;
        if LOld <> TInputEventScaling.MouseMotion(LMotion, LSensitivity, LAxis) then
          Assert.Fail('mouse ' + LMotion.ToString + ' ' + LSensitivity.ToString + ' ' + LAxis.ToString);
      end;
end;

procedure TTestInputEventScaling.DovrebbeEssereUgualeAlVecchioCodiceDelJoystick;
var
  LMask, LIndex, LBitmask: Integer;
  LOld: array[0..NUMJOYBUTTONS - 1] of Boolean;
  LNew: array[0..NUMJOYBUTTONS - 1] of Boolean;
begin
  for LMask := 0 to 8191 do
  begin
    // the old loop of G_Responder of the four games
    LBitmask := 1;
    for LIndex := 0 to NUMJOYBUTTONS - 1 do
    begin
      LOld[LIndex] := (LMask and LBitmask) <> 0;
      LBitmask := LBitmask * 2;
    end;
    FillChar(LNew, SizeOf(LNew), 1);
    TInputEventScaling.JoystickButtons(LMask, @LNew[0], NUMJOYBUTTONS);
    for LIndex := 0 to NUMJOYBUTTONS - 1 do
      if LOld[LIndex] <> LNew[LIndex] then
        Assert.Fail('joystick ' + LMask.ToString + ' tasto ' + LIndex.ToString);
  end;
end;

procedure TTestInputEventScaling.DovrebbeDareZeroSenzaMovimento;
begin
  Assert.AreEqual(0, TInputEventScaling.MouseMotion(0, 5, 5));
end;

procedure TTestInputEventScaling.DovrebbeSpegnereITastiSeLaMaschera0;
var
  LButtons: array[0..NUMJOYBUTTONS - 1] of Boolean;
  LIndex: Integer;
begin
  FillChar(LButtons, SizeOf(LButtons), 1);
  TInputEventScaling.JoystickButtons(0, @LButtons[0], NUMJOYBUTTONS);
  for LIndex := 0 to NUMJOYBUTTONS - 1 do
    Assert.IsFalse(LButtons[LIndex]);
end;

end.
