{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedWeaponPictures                                    }
{                                                                              }
{  The oracle is loadweapon of utils.pas of xGreed as it was: the harness       }
{  Tools\Verifica\175-events (SessionGolden) cuts it out of the original file,  }
{  loads a sequence of weapons and writes                                       }
{  Tests\Data\Greed\weaponpictures.golden.txt; here the library loads the same  }
{  weapons                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.WeaponPictures;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.WeaponPictures,
  DelphiDoom.Tests.Greed.SessionScenarios, DelphiDoom.Tests.Greed.Events;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedWeaponPictures = class(TObject)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FGame: TEventGameFake;
    FGameIntf: IInterface;
    FArchive: TEventFakeArchive;
    FArchiveIntf: IGreedArchive;
    FPicturesObject: TGreedWeaponPictures;
    FPictures: IGreedWeaponView;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeNonAvereImmaginiPrimaDellaPrimaArma;
    [Test]
    procedure DovrebbeCaricareLArmaELeSueImmagini;
    [Test]
    procedure DovrebbeLasciareLeImmaginiDiPrimaPerUnArmaCheNonNeHa;
    [Test]
    procedure DovrebbeTenereLImmagineVecchiaNeiPostiNonRiempiti;
    [Test]
    procedure DovrebbeIgnorareUnArmaFuoriTabella;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.RealData;

const
  GOLDEN_NAME = 'weaponpictures.golden.txt';

{ TTestGreedWeaponPictures }

procedure TTestGreedWeaponPictures.Setup;
begin
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FWorld := TGreedWorld.Create;
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  FGame := TEventGameFake.Create;
  FGameIntf := FGame;
  FArchive := TEventFakeArchive.Create;
  FArchiveIntf := FArchive;
  FArchive.Game := FGame;
  FArchive.Lenient := True;
  FPicturesObject := TGreedWeaponPictures.Create(FState, FArchiveIntf);
  FPictures := FPicturesObject;
end;

procedure TTestGreedWeaponPictures.TearDown;
begin
  FPictures := nil;
  FPicturesObject := nil;
  FArchiveIntf := nil;
  FArchive := nil;
  FGameIntf := nil;
  FGame := nil;
  FreeAndNil(FState);
  FWorld := nil;
  FreeAndNil(FElevators);
  FreeAndNil(FSprites);
end;

procedure TTestGreedWeaponPictures.DovrebbeSollevareSenzaUnaDipendenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedWeaponPictures.Create(nil, FArchiveIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedWeaponPictures.Create(FState, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedWeaponPictures.DovrebbeNonAvereImmaginiPrimaDellaPrimaArma;
begin
  Assert.AreEqual(-1, FPicturesObject.PictureLump(0));
  Assert.AreEqual(0, FPictures.PictureWidth(0));
  Assert.AreEqual(0, FPictures.PictureHeight(6));
  Assert.AreEqual(-1, FPicturesObject.PictureLump(7));
  Assert.AreEqual(0, FPictures.PictureWidth(-1));
  Assert.AreEqual(0, FPicturesObject.FirstLump);
end;

procedure TTestGreedWeaponPictures.DovrebbeCaricareLArmaELeSueImmagini;
var
  LFirst, LIndex: Integer;
begin
  FState.TimeCount := 1000;
  FState.Weapons[18].Charge := 3;
  FPictures.LoadWeapon(18);
  LFirst := TSessionScenarios.LumpNumber('GREENGUN');
  Assert.AreEqual(100, FState.Weapons[18].Charge);
  Assert.AreEqual(1000 + FState.Weapons[18].ChargeRate, FState.Weapons[18].ChargeTime);
  Assert.AreEqual(LFirst, FPicturesObject.FirstLump);
  Assert.AreEqual(5, FPicturesObject.LumpCount);
  for LIndex := 0 to 4 do
  begin
    Assert.AreEqual(LFirst + LIndex, FPicturesObject.PictureLump(LIndex));
    Assert.AreEqual(TSessionScenarios.PictureWidth(LFirst + LIndex), FPictures.PictureWidth(LIndex));
    Assert.AreEqual(TSessionScenarios.PictureHeight(LFirst + LIndex), FPictures.PictureHeight(LIndex));
  end;
  Assert.AreEqual(-1, FPicturesObject.PictureLump(5));
end;

procedure TTestGreedWeaponPictures.DovrebbeLasciareLeImmaginiDiPrimaPerUnArmaCheNonNeHa;
var
  LFirst, LWeapon: Integer;
  LName: string;
  LCount: Integer;
begin
  FPictures.LoadWeapon(1);
  LFirst := FPicturesObject.FirstLump;
  for LWeapon in [0, 5, 6] do
  begin
    FState.Weapons[LWeapon].Charge := 0;
    FPictures.LoadWeapon(LWeapon);
    Assert.AreEqual(100, FState.Weapons[LWeapon].Charge);
    Assert.AreEqual(LFirst, FPicturesObject.FirstLump);
    Assert.AreEqual(LFirst + 2, FPicturesObject.PictureLump(2));
    Assert.IsFalse(TGreedWeaponPictures.PicturesOf(LWeapon, LName, LCount));
  end;
  Assert.IsTrue(TGreedWeaponPictures.PicturesOf(16, LName, LCount));
  Assert.AreEqual('redgun', LName);
  Assert.AreEqual(2, LCount);
end;

procedure TTestGreedWeaponPictures.DovrebbeTenereLImmagineVecchiaNeiPostiNonRiempiti;
var
  LGreen: Integer;
begin
  FPictures.LoadWeapon(18);
  LGreen := FPicturesObject.FirstLump;
  FPictures.LoadWeapon(16);
  Assert.AreEqual(2, FPicturesObject.LumpCount);
  Assert.AreEqual(TSessionScenarios.LumpNumber('redgun') + 1, FPicturesObject.PictureLump(1));
  Assert.AreEqual(LGreen + 2, FPicturesObject.PictureLump(2), 'as the pointer that the original leaves');
  Assert.AreEqual(TSessionScenarios.PictureWidth(LGreen + 4), FPictures.PictureWidth(4));
end;

procedure TTestGreedWeaponPictures.DovrebbeIgnorareUnArmaFuoriTabella;
begin
  FPictures.LoadWeapon(2);
  FPictures.LoadWeapon(-1);
  FPictures.LoadWeapon(19);
  Assert.AreEqual(TSessionScenarios.LumpNumber('gun3'), FPicturesObject.FirstLump);
  Assert.AreEqual(4, FPicturesObject.LumpCount);
end;

procedure TTestGreedWeaponPictures.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
var
  LGolden: TStringList;
  LStep, LWeapon, LPlace, LDifferences: Integer;
  LFirst, LActual: string;
  LPictures: array[0..SESSION_WEAPON_PICTURES * 3 - 1] of Integer;
begin
  LDifferences := 0;
  LFirst := '';
  FState.ResetWeapons;
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(GOLDEN_NAME));
    Assert.AreEqual(SESSION_WEAPON_STEPS + 1, LGolden.Count, 'the golden file is of another list of steps');
    for LStep := 0 to SESSION_WEAPON_STEPS - 1 do
    begin
      FState.TimeCount := LStep * 7 + 1;
      LWeapon := TSessionScenarios.WeaponStep(LStep);
      FPictures.LoadWeapon(LWeapon);
      for LPlace := 0 to SESSION_WEAPON_PICTURES - 1 do
      begin
        LPictures[LPlace * 3] := FPicturesObject.PictureLump(LPlace);
        LPictures[LPlace * 3 + 1] := FPictures.PictureWidth(LPlace);
        LPictures[LPlace * 3 + 2] := FPictures.PictureHeight(LPlace);
      end;
      LActual := TSessionScenarios.WeaponLine(LStep, LWeapon, FPicturesObject.FirstLump,
        FPicturesObject.LumpCount, FState.Weapons[LWeapon].Charge, FState.Weapons[LWeapon].ChargeTime, LPictures);
      if LGolden[LStep + 1] <> LActual then
      begin
        Inc(LDifferences);
        if LFirst = '' then
          LFirst := Format('original "%s", library "%s"', [LGolden[LStep + 1], LActual]);
      end;
    end;
  finally
    LGolden.Free;
  end;
  Assert.AreEqual(0, LDifferences, Format('%d steps of %d differ; the first: %s', [LDifferences,
    SESSION_WEAPON_STEPS, LFirst]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedWeaponPictures);

end.
