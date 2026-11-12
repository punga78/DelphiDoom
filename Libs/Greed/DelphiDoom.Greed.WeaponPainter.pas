{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the pictures of the weapon in the hands          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): loadweapon of utils.pas,    }
{  weaponpic of raven.pas and the part of UpdateView that draws the weapon      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.WeaponPictures;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Hud.Intf;

const
  /// <summary>weaponpic has 7 places; the weapon with the most pictures has 5</summary>
  GREED_WEAPON_PICTURES = 7;

type
  /// <summary>The lump of the first picture of a weapon and how many follow each other</summary>
  TGreedWeaponLumps = record
    Name: string;
    Count: Integer;
  end;

  /// <summary>
  ///   weaponpic: the pictures of the weapon in the hands, one for each weapmode (0 at rest, the others while it
  ///   shoots). LoadWeapon (loadweapon) charges the weapon (charge 100, the next charge after its rate) and reads
  ///   its pictures, which are lumps that follow each other from a named one. Draw is the end of the weapon part of
  ///   UpdateView: at rest the picture takes the light of the tile where the player stands
  ///   (VI_DrawMaskedPicToBuffer2), while shooting it is drawn as it is (VI_DrawMaskedPicToBuffer, with the origin
  ///   of the picture); the position is the one IGreedPlayerWeapons.UpdateWeaponView gives.
  ///   Kept from the original: the weapons 0, 5 and 6 have no pictures and leave the ones of the weapon before,
  ///   as do the places a weapon with fewer pictures does not fill.
  ///   Differences from the original: a weapon number outside the table changes nothing; a place that was never
  ///   filled has size 0 and is not drawn (the original follows a nil pointer); the original draws again the
  ///   picture of the last new frame when UpdateView is called with update = 0, here the picture is always the
  ///   one of the weapmode of now
  /// </summary>
  TGreedWeaponPictures = class(TInterfacedObject, IGreedWeaponView)
  strict private
    FState: TGreedGameState;
    FArchive: IGreedArchive;
    FCanvas: TGreedCanvas;
    FLight: IGreedWeaponLight;
    FPictures: array[0..GREED_WEAPON_PICTURES - 1] of TBytes;
    FLoadedWeapon: Integer;
  public
    constructor Create(AState: TGreedGameState; const AArchive: IGreedArchive; ACanvas: TGreedCanvas;
      const ALight: IGreedWeaponLight);
    /// <summary>The lumps of the weapon n; a count of 0 for a weapon without pictures</summary>
    class function LumpsOf(AWeapon: Integer): TGreedWeaponLumps; static;
    /// <summary>loadweapon(n)</summary>
    procedure LoadWeapon(AWeapon: Integer);
    /// <summary>weaponpic[mode].width</summary>
    function PictureWidth(AMode: Integer): Integer;
    /// <summary>weaponpic[mode].height</summary>
    function PictureHeight(AMode: Integer): Integer;
    /// <summary>
    ///   Draws the picture of the weapmode of the game at the position given, if the player is alive (angst is
    ///   not 0). AWindowHeight is windowHeight (200): the picture at rest is cut there
    /// </summary>
    procedure Draw(AWeaponX, AWeaponY, AWindowHeight: Integer);
    /// <summary>The weapon LoadWeapon was called with last; -1 before the first call</summary>
    property LoadedWeapon: Integer read FLoadedWeapon;
  end;

implementation

{ TGreedWeaponPictures }

constructor TGreedWeaponPictures.Create(AState: TGreedGameState; const AArchive: IGreedArchive;
  ACanvas: TGreedCanvas; const ALight: IGreedWeaponLight);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(ACanvas) then
    raise EArgumentNilException.Create('ACanvas');
  if not Assigned(ALight) then
    raise EArgumentNilException.Create('ALight');
  FState := AState;
  FArchive := AArchive;
  FCanvas := ACanvas;
  FLight := ALight;
  FLoadedWeapon := -1;
end;

class function TGreedWeaponPictures.LumpsOf(AWeapon: Integer): TGreedWeaponLumps;

  procedure Give(const AName: string; ACount: Integer);
  begin
    Result.Name := AName;
    Result.Count := ACount;
  end;

begin
  case AWeapon of
    1: Give('gun2', 3);
    2: Give('gun3', 4);
    3: Give('gun4', 4);
    4: Give('gun5', 4);
    7: Give('gunsquar', 3);
    8: Give('gunknife', 4);
    9: Give('guncross', 3);
    10: Give('gunspec7', 4);
    11: Give('gunmoo', 3);
    12: Give('gunprong', 3);
    13: Give('catlprod', 3);
    14: Give('s7weapon', 3);
    15: Give('domknife', 3);
    16: Give('redgun', 2);
    17: Give('bluegun', 3);
    18: Give('greengun', 5);
  else
    Give('', 0);
  end;
end;

procedure TGreedWeaponPictures.LoadWeapon(AWeapon: Integer);
var
  LLumps: TGreedWeaponLumps;
  LFirst: Integer;
  LIndex: Integer;
begin
  if (AWeapon < Low(FState.Weapons)) or (AWeapon > High(FState.Weapons)) then
    Exit;
  FLoadedWeapon := AWeapon;
  FState.Weapons[AWeapon].Charge := 100;
  FState.Weapons[AWeapon].ChargeTime := FState.TimeCount + FState.Weapons[AWeapon].ChargeRate;
  LLumps := LumpsOf(AWeapon);
  if LLumps.Count = 0 then
    Exit;
  LFirst := FArchive.RequireIndexOf(LLumps.Name);
  for LIndex := 0 to LLumps.Count - 1 do
    FPictures[LIndex] := FArchive.ReadLump(LFirst + LIndex);
end;

function TGreedWeaponPictures.PictureWidth(AMode: Integer): Integer;
begin
  if (AMode < 0) or (AMode >= GREED_WEAPON_PICTURES) then
    Result := 0
  else
    Result := TGreedCanvas.PictureWidth(FPictures[AMode]);
end;

function TGreedWeaponPictures.PictureHeight(AMode: Integer): Integer;
begin
  if (AMode < 0) or (AMode >= GREED_WEAPON_PICTURES) then
    Result := 0
  else
    Result := TGreedCanvas.PictureHeight(FPictures[AMode]);
end;

procedure TGreedWeaponPictures.Draw(AWeaponX, AWeaponY, AWindowHeight: Integer);
var
  LMode: Integer;
begin
  // only if alive
  if FState.Player.Angst = 0 then
    Exit;
  LMode := FState.WeapMode;
  if (LMode < 0) or (LMode >= GREED_WEAPON_PICTURES) or (Length(FPictures[LMode]) < GREED_PICTURE_HEADER_BYTES) then
    Exit;
  if LMode = 0 then
    FCanvas.DrawMaskedPicToBuffer2(AWeaponX, AWeaponY, FPictures[LMode],
      FLight.WeaponColormap(FState.Player.MapSpot), AWindowHeight)
  else
    FCanvas.DrawMaskedPicToBuffer(AWeaponX, AWeaponY, FPictures[LMode]);
end;

end.
