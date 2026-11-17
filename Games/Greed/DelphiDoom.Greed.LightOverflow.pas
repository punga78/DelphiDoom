{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the light that the original writes outside the   }
{  map (a defect of sprites.pas, MoveSprites: reallight[mapspot + i * MAPCOLS   }
{  + j] without a check), for who wants the game with its defect                }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.LightOverflow;

// the integers of the original wrap
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.SpriteLogic.Intf,
  DelphiDoom.Greed.GameRenderer.Intf, DelphiDoom.Greed.PlayerControl;

type
  /// <summary>
  ///   What the original does when a sprite hotter than 256 stands on the first or on the last row of the map: the
  ///   light of the nine tiles around it is taken also from the "tiles" before and after the map, which are other
  ///   variables of r_render.pas (the compiler puts the variables of a unit in memory in the order in which they
  ///   are declared):
  ///   - before reallight there is mapflags, an array of bytes: reallight[-n] is the integer made of the four
  ///     bytes mapflags[4096 - 4 * n ..], so the flags of the tiles of the last rows change (and stay changed:
  ///     TimeUpdate clears reallight, not them);
  ///   - reallight[4096] is actionflag: when it is not 0 the renderer runs the action hook at its next
  ///     RF_CheckActionFlag, and the weapon of the player fires without the fire command. The hook is nil until
  ///     the player has fired once: before that the original calls a nil procedure and stops with an access
  ///     violation, here nothing happens;
  ///   - after actionflag: wallglow, wallglowindex, wallrotate, maplight, wallflicker1 .. 4, wallflags, wallcycle,
  ///     frameon and framevalid (the renderer: IGreedRenderMemory).
  ///   The game does not use this class unless it is asked to (TGreedGame.OriginalLightOverflow): by default the
  ///   light outside the map is dropped. The world and the control of the player are not owned
  /// </summary>
  TGreedLightOverflow = class(TInterfacedObject, IGreedLightOverflow)
  strict private
    FWorld: IGreedWorld;
    FControl: TGreedPlayerControl;
    FRenderMemory: IGreedRenderMemory;
    FWrites: Integer;
  public
    /// <summary>
    ///   ARenderMemory can be nil (a renderer without the variables of the original: what goes after actionflag is
    ///   dropped). EArgumentNilException if AWorld or AControl is nil
    /// </summary>
    constructor Create(const AWorld: IGreedWorld; AControl: TGreedPlayerControl;
      const ARenderMemory: IGreedRenderMemory);
    procedure LightOutsideTheMap(AIndex, AAmount: Integer);
    /// <summary>How many times the light went outside the map</summary>
    property Writes: Integer read FWrites;
  end;

implementation

constructor TGreedLightOverflow.Create(const AWorld: IGreedWorld; AControl: TGreedPlayerControl;
  const ARenderMemory: IGreedRenderMemory);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(AControl) then
    raise EArgumentNilException.Create('AControl');
  FWorld := AWorld;
  FControl := AControl;
  FRenderMemory := ARenderMemory;
end;

procedure TGreedLightOverflow.LightOutsideTheMap(AIndex, AAmount: Integer);
var
  LFirst, LByte: Integer;
  LValue: Cardinal;
begin
  Inc(FWrites);
  if AIndex < 0 then
  begin
    // an integer of four bytes of mapflags, the lowest byte first
    LFirst := GREED_MAP_TILES + AIndex * SizeOf(Integer);
    if LFirst < 0 then
      Exit;
    LValue := 0;
    for LByte := 3 downto 0 do
      LValue := (LValue shl 8) or FWorld.GetMapFlags(LFirst + LByte);
    LValue := Cardinal(Integer(LValue) - AAmount);
    for LByte := 0 to 3 do
    begin
      FWorld.SetMapFlags(LFirst + LByte, Byte(LValue));
      LValue := LValue shr 8;
    end;
  end
  else if AIndex = GREED_MAP_TILES then
  begin
    // actionflag := actionflag - amount: it was 0 or 1 and the amount is at least 128, so it is not 0 now
    if FControl.ActionHookSet then
      FControl.FirePending := True;
  end
  else if (AIndex > GREED_MAP_TILES) and Assigned(FRenderMemory) then
    FRenderMemory.SubtractAfterTileLights(AIndex - GREED_MAP_TILES, AAmount);
end;

end.
