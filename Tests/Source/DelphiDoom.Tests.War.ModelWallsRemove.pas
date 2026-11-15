{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - taking a piece out of a wall         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelWallsRemove;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Model.Walls;

type
  /// <summary>we_removeWallPiece, which only the cheat "Edit walls" uses</summary>
  [TestFixture]
  [Category('war')]
  TTestWarModelWallsRemove = class
  strict private
    FWalls: TWarWalls;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeToglierePezzoETenereLOrdineDegliAltri;
    [Test]
    procedure DovrebbeDecidereDiNuovoITipiDopoLaRimozione;
    [Test]
    procedure DovrebbeRifiutareUnPezzoCheNonCe;
    [Test]
    procedure DovrebbeToglierePureLUnicoPezzo;
  end;

implementation

uses
  DelphiDoom.War.Types;

procedure TTestWarModelWallsRemove.Setup;
begin
  FWalls := TWarWalls.Create;
  FWalls.Add(10, 10, 0);
  FWalls.Add(11, 10, 0);
  FWalls.Add(12, 10, 0);
end;

procedure TTestWarModelWallsRemove.TearDown;
begin
  FreeAndNil(FWalls);
end;

procedure TTestWarModelWallsRemove.DovrebbeToglierePezzoETenereLOrdineDegliAltri;
begin
  FWalls.Remove(1);
  Assert.AreEqual(2, FWalls.Count);
  Assert.AreEqual(10, FWalls[0]^.TileX);
  Assert.AreEqual(12, FWalls[1]^.TileX, 'l''ultimo sale al posto di quello tolto');
  Assert.AreEqual(-1, FWalls.IndexAt(11, 10));
  Assert.IsFalse(FWalls.HasPieceAt(11, 10));
  Assert.IsTrue(FWalls.HasPieceAt(12, 10));
end;

procedure TTestWarModelWallsRemove.DovrebbeDecidereDiNuovoITipiDopoLaRimozione;
var
  LOther: TWarWalls;
begin
  // un muro tolto il pezzo di mezzo e' come un muro fatto di due pezzi che non si toccano
  LOther := TWarWalls.Create;
  try
    LOther.Add(10, 10, 0);
    LOther.Add(12, 10, 0);
    LOther.DetermineTypes;
    FWalls.DetermineTypes;
    FWalls.Remove(1);
    FWalls.DetermineTypes;
    Assert.AreEqual<Integer>(Integer(LOther[0]^.PieceType), Integer(FWalls[0]^.PieceType));
    Assert.AreEqual<Integer>(Integer(LOther[1]^.PieceType), Integer(FWalls[1]^.PieceType));
  finally
    LOther.Free;
  end;
end;
procedure TTestWarModelWallsRemove.DovrebbeRifiutareUnPezzoCheNonCe;
begin
  Assert.WillRaise(
    procedure
    begin
      FWalls.Remove(3);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FWalls.Remove(-1);
    end, EWarException);
end;

procedure TTestWarModelWallsRemove.DovrebbeToglierePureLUnicoPezzo;
begin
  FWalls.Remove(0);
  FWalls.Remove(0);
  FWalls.Remove(0);
  Assert.AreEqual(0, FWalls.Count);
  FWalls.DetermineTypes;
  FWalls.Add(5, 5, 0);
  Assert.AreEqual(1, FWalls.Count);
  Assert.AreEqual(0, FWalls.IndexAt(5, 5));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarModelWallsRemove);

end.
