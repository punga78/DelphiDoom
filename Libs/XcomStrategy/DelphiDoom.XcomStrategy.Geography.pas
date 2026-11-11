{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the regions and countries of a point of }
{  the globe, the activity that goes to them and the soldiers that die         }
{  (SavedGame::locateRegion, killSoldier and the loops of GeoscapeState)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.Geography;

interface

uses
  System.SysUtils, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.Country,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.SoldierDeath;

type
  /// <summary>
  ///   Lookups that the saved game and the geoscape do on the position of a target: the region and the country
  ///   that contain it, the activity of the aliens or of XCOM that is added to them, and the death of a soldier
  /// </summary>
  TXcomGeography = class
  public
    /// <summary>Nautical(x): nautical miles to radians</summary>
    class function Nautical(AMiles: Double): Double; static;
    /// <summary>locateRegion: the first region that contains the point, nil if none</summary>
    class function LocateRegion(const AGame: TXcomSavedGame; ALongitude, ALatitude: Double): TXcomRegion; static;
    /// <summary>The first country that contains the point, nil if none</summary>
    class function LocateCountry(const AGame: TXcomSavedGame; ALongitude, ALatitude: Double): TXcomCountry; static;
    /// <summary>
    ///   The pair of loops that give points to the first region and then the first country with the point inside
    ///   (the aliens' activity of a UFO, a site, an alien base)
    /// </summary>
    class procedure AddAlienActivity(const AGame: TXcomSavedGame; ALongitude, ALatitude: Double;
      APoints: Integer); static;
    /// <summary>
    ///   killSoldier: the soldier of a base dies: it goes to the dead soldiers of the game (they own it from now
    ///   on) and leaves the soldiers of its base; the base it was in is returned (nil if it was in none)
    /// </summary>
    class function KillSoldier(const AGame: TXcomSavedGame; const ASoldier: TXcomSoldier): TXcomBase; static;
  end;

implementation

{ TXcomGeography }

class function TXcomGeography.Nautical(AMiles: Double): Double;
var
  LValue: Double;
begin
  // Nautical(x) = x * (1 / 60.0) * (M_PI / 180.0)
  LValue := AMiles * (1 / 60.0);
  Result := LValue * (3.14159265358979323846 / 180.0);
end;

class function TXcomGeography.LocateRegion(const AGame: TXcomSavedGame; ALongitude, ALatitude: Double): TXcomRegion;
var
  LRegion: TXcomRegion;
begin
  for LRegion in AGame.Regions do
    if LRegion.Rules.IsInside(ALongitude, ALatitude) then
      Exit(LRegion);
  Result := nil;
end;

class function TXcomGeography.LocateCountry(const AGame: TXcomSavedGame; ALongitude, ALatitude: Double): TXcomCountry;
var
  LCountry: TXcomCountry;
begin
  for LCountry in AGame.Countries do
    if LCountry.Rules.IsInside(ALongitude, ALatitude) then
      Exit(LCountry);
  Result := nil;
end;

class procedure TXcomGeography.AddAlienActivity(const AGame: TXcomSavedGame; ALongitude, ALatitude: Double;
  APoints: Integer);
var
  LRegion: TXcomRegion;
  LCountry: TXcomCountry;
begin
  LRegion := LocateRegion(AGame, ALongitude, ALatitude);
  if Assigned(LRegion) then
    LRegion.AddActivityAlien(APoints);
  LCountry := LocateCountry(AGame, ALongitude, ALatitude);
  if Assigned(LCountry) then
    LCountry.AddActivityAlien(APoints);
end;

class function TXcomGeography.KillSoldier(const AGame: TXcomSavedGame; const ASoldier: TXcomSoldier): TXcomBase;
var
  LBase: TXcomBase;
begin
  for LBase in AGame.Bases do
    if LBase.Soldiers.IndexOf(ASoldier) >= 0 then
    begin
      ASoldier.Die(TXcomSoldierDeath.Create(AGame.Time, nil));
      AGame.DeadSoldiers.Add(LBase.Soldiers.Extract(ASoldier));
      Exit(LBase);
    end;
  Result := nil;
end;

end.
