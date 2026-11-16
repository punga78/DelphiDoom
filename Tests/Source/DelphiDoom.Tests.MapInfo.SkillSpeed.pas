{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the speed of the monsters of a new game                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.SkillSpeed;

interface

uses
  DUnitX.TestFramework, DelphiDoom.MapInfo.SkillSpeed;

type
  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoSkillSpeed = class
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSuTutteLeCombinazioni;
    [Test]
    procedure DovrebbeFarRinascereIMostriInIncuboOConIlParametro;
  end;

implementation

function OldChange(const fastparm, newnm, oldnm: Boolean): Integer;
begin
  // G_InitNew as it was: 1 = the speed of the fast field, 2 = the normal one, 0 = nothing
  Result := 0;
  if fastparm or (newnm and not oldnm) then
    Result := 1
  else if (not newnm) and oldnm then
    Result := 2;
end;

procedure TTestMapInfoSkillSpeed.DovrebbeEssereUgualeAlVecchioCodiceSuTutteLeCombinazioni;
var
  LFast, LNew, LOld: Boolean;
begin
  for LFast := False to True do
    for LNew := False to True do
      for LOld := False to True do
        Assert.AreEqual<Integer>(OldChange(LFast, LNew, LOld), Ord(TSkillSpeed.Change(LFast, LNew, LOld)));
end;

procedure TTestMapInfoSkillSpeed.DovrebbeFarRinascereIMostriInIncuboOConIlParametro;
begin
  Assert.IsTrue(TSkillSpeed.RespawnMonsters(True, False));
  Assert.IsTrue(TSkillSpeed.RespawnMonsters(False, True));
  Assert.IsFalse(TSkillSpeed.RespawnMonsters(False, False));
end;

end.
