{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the weapon in the hands, drawn                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the part of UpdateView of   }
{  raven.pas that draws weaponpic                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.WeaponPainter;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Hud.Intf,
  DelphiDoom.Greed.WeaponPictures;

type
  /// <summary>
  ///   The end of the weapon part of UpdateView: the picture of the weapmode of the game (TGreedWeaponPictures
  ///   says which lump) at the position IGreedPlayerWeapons.UpdateWeaponView gives. At rest (weapmode 0) the
  ///   picture takes the light of the tile where the player stands (VI_DrawMaskedPicToBuffer2: the origin of the
  ///   picture is not used and it is cut at the bottom of the window); while shooting it is drawn as it is
  ///   (VI_DrawMaskedPicToBuffer, with its origin). Nothing is drawn if the player is dead (angst 0).
  ///   Differences from the original: a place of weaponpic that was never filled is not drawn (the original
  ///   follows a nil pointer); when UpdateView is called with update = 0 the original draws again the picture of
  ///   the last new frame, here the picture is always the one of the weapmode of now
  /// </summary>
  TGreedWeaponPainter = class
  strict private
    FState: TGreedGameState;
    FPictures: TGreedWeaponPictures;
    FArchive: IGreedArchive;
    FCanvas: TGreedCanvas;
    FLight: IGreedWeaponLight;
    FLumps: TDictionary<Integer, TBytes>;
    function Lump(AIndex: Integer): TBytes;
  public
    /// <summary>Nothing is owned. EArgumentNilException if one is nil</summary>
    constructor Create(AState: TGreedGameState; APictures: TGreedWeaponPictures; const AArchive: IGreedArchive;
      ACanvas: TGreedCanvas; const ALight: IGreedWeaponLight);
    destructor Destroy; override;
    /// <summary>AWindowHeight is windowHeight while the HUD is drawn (200)</summary>
    procedure Draw(AWeaponX, AWeaponY, AWindowHeight: Integer);
  end;

implementation

{ TGreedWeaponPainter }

constructor TGreedWeaponPainter.Create(AState: TGreedGameState; APictures: TGreedWeaponPictures;
  const AArchive: IGreedArchive; ACanvas: TGreedCanvas; const ALight: IGreedWeaponLight);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(APictures) then
    raise EArgumentNilException.Create('APictures');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(ACanvas) then
    raise EArgumentNilException.Create('ACanvas');
  if not Assigned(ALight) then
    raise EArgumentNilException.Create('ALight');
  FState := AState;
  FPictures := APictures;
  FArchive := AArchive;
  FCanvas := ACanvas;
  FLight := ALight;
  FLumps := TDictionary<Integer, TBytes>.Create;
end;

destructor TGreedWeaponPainter.Destroy;
begin
  FLumps.Free;
  inherited;
end;

function TGreedWeaponPainter.Lump(AIndex: Integer): TBytes;
begin
  if FLumps.TryGetValue(AIndex, Result) then
    Exit;
  if (AIndex < 0) or (AIndex >= FArchive.LumpCount) then
    Result := nil
  else
    Result := FArchive.ReadLump(AIndex);
  FLumps.Add(AIndex, Result);
end;

procedure TGreedWeaponPainter.Draw(AWeaponX, AWeaponY, AWindowHeight: Integer);
var
  LPicture: TBytes;
begin
  // only if alive
  if FState.Player.Angst = 0 then
    Exit;
  LPicture := Lump(FPictures.PictureLump(FState.WeapMode));
  if Length(LPicture) < GREED_PICTURE_HEADER_BYTES then
    Exit;
  if FState.WeapMode = 0 then
    FCanvas.DrawMaskedPicToBuffer2(AWeaponX, AWeaponY, LPicture, FLight.WeaponColormap(FState.Player.MapSpot),
      AWindowHeight)
  else
    FCanvas.DrawMaskedPicToBuffer(AWeaponX, AWeaponY, LPicture);
end;

end.
