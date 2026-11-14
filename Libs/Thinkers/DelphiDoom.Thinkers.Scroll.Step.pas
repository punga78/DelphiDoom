{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the tic of a scroller (T_Scroll)             }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Scroll.Step;

// The offsets are 16.16 fixed point and the old code let the sums wrap
{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The calculation of the tic of a generalized scroller (the T_Scroll of Boom, which was
  ///   copied in Doom and in Strife): how much it scrolls in this tic and which things a
  ///   carrying floor moves
  /// </summary>
  /// <remarks>
  ///   It runs for every scroller at every tic: it has no state, makes no allocation and calls
  ///   nothing but the fixed point product. The fields of the thinker are passed as they are
  /// </remarks>
  TScrollStep = class sealed
  public
    /// <summary>
    ///   The scroll of this tic. ADeltaX and ADeltaY enter as the speeds of the scroller and
    ///   leave as the amounts to apply; false when there is nothing to apply
    /// </summary>
    /// <param name="AControlled">True when a control sector drives the scroller</param>
    /// <param name="AControlHeight">Floor plus ceiling of the control sector (read only when AControlled)</param>
    /// <param name="ALastHeight">The height seen at the last tic (the field of the thinker)</param>
    /// <param name="AAccelerates">True when the amounts add up tic after tic</param>
    /// <param name="AVelocityX">The accumulated amount (the field of the thinker)</param>
    /// <param name="AVelocityY">The accumulated amount (the field of the thinker)</param>
    class function Advance(var ADeltaX, ADeltaY: Integer; AControlled: Boolean;
      AControlHeight: Integer; var ALastHeight: Integer; AAccelerates: Boolean;
      var AVelocityX, AVelocityY: Integer): Boolean; static;
    /// <summary>
    ///   True when a carrying floor moves a thing: it is clipped and either stands on the floor
    ///   with gravity or is under the water of the sector
    /// </summary>
    class function Carries(ANoClip, ANoGravity: Boolean; AThingZ, AFloorHeight,
      AWaterHeight: Integer): Boolean; static; inline;
    /// <summary>
    ///   The height of the water that carries also what floats: the floor of the height sector
    ///   when there is one above the floor, otherwise the lowest integer (nothing is under it)
    /// </summary>
    class function WaterHeight(AHasHeightSector: Boolean; AHeightSectorFloor,
      AFloorHeight: Integer): Integer; static; inline;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath;

{ TScrollStep }

class function TScrollStep.Advance(var ADeltaX, ADeltaY: Integer; AControlled: Boolean;
  AControlHeight: Integer; var ALastHeight: Integer; AAccelerates: Boolean;
  var AVelocityX, AVelocityY: Integer): Boolean;
var
  LDelta: Integer;
begin
  if AControlled then
  begin
    // the scroll follows the change of height of the control sector
    LDelta := AControlHeight - ALastHeight;
    ALastHeight := AControlHeight;
    ADeltaX := TFixedMath.Mul(ADeltaX, LDelta);
    ADeltaY := TFixedMath.Mul(ADeltaY, LDelta);
  end;

  if AAccelerates then
  begin
    ADeltaX := ADeltaX + AVelocityX;
    ADeltaY := ADeltaY + AVelocityY;
    AVelocityX := ADeltaX;
    AVelocityY := ADeltaY;
  end;

  Result := (ADeltaX or ADeltaY) <> 0;
end;

class function TScrollStep.Carries(ANoClip, ANoGravity: Boolean; AThingZ, AFloorHeight,
  AWaterHeight: Integer): Boolean;
begin
  Result := (not ANoClip) and
    (not (ANoGravity or (AThingZ > AFloorHeight)) or (AThingZ < AWaterHeight));
end;

class function TScrollStep.WaterHeight(AHasHeightSector: Boolean; AHeightSectorFloor,
  AFloorHeight: Integer): Integer;
begin
  if AHasHeightSector and (AHeightSectorFloor > AFloorHeight) then
    Result := AHeightSectorFloor
  else
    Result := Low(Integer);
end;

end.
