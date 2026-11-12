{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the pictures of the weapon of the player         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): loadweapon of utils.pas     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.WeaponPictures;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.PlayerControl.Intf;

const
  /// <summary>weaponpic has 7 places; a weapon has from 2 to 5 pictures</summary>
  GREED_WEAPON_PICTURES = 7;

type
  /// <summary>
  ///   loadweapon of utils.pas as data: which lumps are the pictures of each weapon (the lump of a name and the
  ///   ones that follow it) and how large they are. LoadWeapon(n) charges the weapon (charge 100, the next charge
  ///   at its rate) and makes its pictures the current ones; nothing is drawn here: who draws asks PictureLump.
  ///   The weapons 0, 5 and 6 have no pictures in the original: they are charged and the pictures stay the ones of
  ///   the weapon before. The net game is not ported (NetGetData between the pictures is not here).
  ///   Kept defect of the original: the places that the new weapon does not fill keep the picture of an older
  ///   weapon (in the original a pointer to a lump that was freed). Differences: a weapon number outside 0..18
  ///   does nothing (the original wrote outside its table: LoadGame can ask for the weapon -1 of an empty hand);
  ///   a picture lump shorter than its header is 0 x 0
  /// </summary>
  TGreedWeaponPictures = class(TInterfacedObject, IGreedWeaponView)
  strict private
    FState: TGreedGameState;
    FArchive: IGreedArchive;
    FFirstLump: Integer;
    FLumpCount: Integer;
    FLumps: array[0..GREED_WEAPON_PICTURES - 1] of Integer;
    FWidths: array[0..GREED_WEAPON_PICTURES - 1] of Integer;
    FHeights: array[0..GREED_WEAPON_PICTURES - 1] of Integer;
  public
    /// <summary>
    ///   AState has the table of the weapons and the clock; AArchive gives the lumps. EArgumentNilException if one
    ///   is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const AArchive: IGreedArchive);
    /// <summary>loadweapon(n)</summary>
    procedure LoadWeapon(AWeapon: Integer);
    /// <summary>weaponpic[mode].width; 0 if the place was never filled or AMode is not a place</summary>
    function PictureWidth(AMode: Integer): Integer;
    function PictureHeight(AMode: Integer): Integer;
    /// <summary>The lump of weaponpic[mode]; -1 if the place was never filled or AMode is not a place</summary>
    function PictureLump(AMode: Integer): Integer;
    /// <summary>The name of the first picture lump of a weapon and how many they are; False if it has none</summary>
    class function PicturesOf(AWeapon: Integer; out AName: string; out ACount: Integer): Boolean; static;
    /// <summary>weaponlump: the first lump of the weapon loaded last (0 before the first one)</summary>
    property FirstLump: Integer read FFirstLump;
    /// <summary>numweaponlumps</summary>
    property LumpCount: Integer read FLumpCount;
  end;

implementation

const
  FULL_CHARGE = 100;
  PICTURE_SIZE_BYTES = 4;

type
  TWeaponPictureSet = record
    Name: string;
    Count: Integer;
  end;

const
  /// the lump of the first picture of each weapon and how many pictures follow each other
  WEAPON_PICTURES: array[0..18] of TWeaponPictureSet = (
    (Name: ''; Count: 0),
    (Name: 'gun2'; Count: 3),
    (Name: 'gun3'; Count: 4),
    (Name: 'gun4'; Count: 4),
    (Name: 'gun5'; Count: 4),
    (Name: ''; Count: 0),
    (Name: ''; Count: 0),
    (Name: 'gunsquar'; Count: 3),
    (Name: 'gunknife'; Count: 4),
    (Name: 'guncross'; Count: 3),
    (Name: 'gunspec7'; Count: 4),
    (Name: 'gunmoo'; Count: 3),
    (Name: 'gunprong'; Count: 3),
    (Name: 'catlprod'; Count: 3),
    (Name: 's7weapon'; Count: 3),
    (Name: 'domknife'; Count: 3),
    (Name: 'redgun'; Count: 2),
    (Name: 'bluegun'; Count: 3),
    (Name: 'greengun'; Count: 5));

{ TGreedWeaponPictures }

constructor TGreedWeaponPictures.Create(AState: TGreedGameState; const AArchive: IGreedArchive);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  FState := AState;
  FArchive := AArchive;
  for LIndex := Low(FLumps) to High(FLumps) do
    FLumps[LIndex] := -1;
end;

class function TGreedWeaponPictures.PicturesOf(AWeapon: Integer; out AName: string; out ACount: Integer): Boolean;
begin
  AName := '';
  ACount := 0;
  Result := (AWeapon >= Low(WEAPON_PICTURES)) and (AWeapon <= High(WEAPON_PICTURES)) and
    (WEAPON_PICTURES[AWeapon].Count > 0);
  if Result then
  begin
    AName := WEAPON_PICTURES[AWeapon].Name;
    ACount := WEAPON_PICTURES[AWeapon].Count;
  end;
end;

procedure TGreedWeaponPictures.LoadWeapon(AWeapon: Integer);
var
  LName: string;
  LCount, LIndex: Integer;
  LBytes: TBytes;
begin
  if (AWeapon < Low(FState.Weapons)) or (AWeapon > High(FState.Weapons)) then
    Exit;
  FState.Weapons[AWeapon].Charge := FULL_CHARGE;
  FState.Weapons[AWeapon].ChargeTime := FState.TimeCount + FState.Weapons[AWeapon].ChargeRate;
  if not PicturesOf(AWeapon, LName, LCount) then
    Exit;
  FFirstLump := FArchive.RequireIndexOf(LName);
  FLumpCount := LCount;
  for LIndex := 0 to LCount - 1 do
  begin
    FLumps[LIndex] := FFirstLump + LIndex;
    LBytes := FArchive.ReadLump(FFirstLump + LIndex);
    if Length(LBytes) >= PICTURE_SIZE_BYTES then
    begin
      FWidths[LIndex] := SmallInt(LBytes[0] or (LBytes[1] shl 8));
      FHeights[LIndex] := SmallInt(LBytes[2] or (LBytes[3] shl 8));
    end
    else
    begin
      FWidths[LIndex] := 0;
      FHeights[LIndex] := 0;
    end;
  end;
end;

function TGreedWeaponPictures.PictureWidth(AMode: Integer): Integer;
begin
  if (AMode >= Low(FWidths)) and (AMode <= High(FWidths)) then
    Result := FWidths[AMode]
  else
    Result := 0;
end;

function TGreedWeaponPictures.PictureHeight(AMode: Integer): Integer;
begin
  if (AMode >= Low(FHeights)) and (AMode <= High(FHeights)) then
    Result := FHeights[AMode]
  else
    Result := 0;
end;

function TGreedWeaponPictures.PictureLump(AMode: Integer): Integer;
begin
  if (AMode >= Low(FLumps)) and (AMode <= High(FLumps)) then
    Result := FLumps[AMode]
  else
    Result := -1;
end;

end.
