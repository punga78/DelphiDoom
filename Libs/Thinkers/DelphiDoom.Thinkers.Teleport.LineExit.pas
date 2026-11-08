{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the exit of a silent line teleport           }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Teleport.LineExit;

// Fixed point and angles: the old code let the sums and the products wrap and so does this one
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types,
  DelphiDoom.Thinkers.Teleport.Intf;

type
  /// <summary>
  ///   What is needed to find where a thing comes out of the exit line of a silent line teleport
  ///   (by Lee Killough): the source line, the exit line, the angles of both (the angle of the
  ///   vector of the line, as R_PointToAngle2(0, 0, dx, dy) gives it) and the thing
  /// </summary>
  TTeleportLineInput = record
    SourceDx: TFixed;
    SourceDy: TFixed;
    SourceStartX: TFixed;
    SourceStartY: TFixed;
    SourceAngle: TAngle;
    ExitDx: TFixed;
    ExitDy: TFixed;
    ExitEndX: TFixed;
    ExitEndY: TFixed;
    ExitAngle: TAngle;
    ThingX: TFixed;
    ThingY: TFixed;
    /// <summary>The teleporter that flips the position across the exit line</summary>
    Reverse: Boolean;
    /// <summary>The thing is a player (not a voodoo doll)</summary>
    ThingIsPlayer: Boolean;
    /// <summary>Walking towards the first side of the exit line steps down</summary>
    StepDown: Boolean;
  end;

  /// <summary>Where the thing comes out and how it turns</summary>
  TTeleportLineOutput = record
    X: TFixed;
    Y: TFixed;
    /// <summary>The angle added to the thing (and used to turn its momentum)</summary>
    Angle: TAngle;
    Sine: TFixed;
    Cosine: TFixed;
  end;

  /// <summary>The position, angle and rotation of a thing that crosses a silent line teleporter</summary>
  TTeleportLineExit = class
  public
    /// <summary>
    ///   Interpolates the position across the exit line and then moves it by at most 10 units, one
    ///   at a time, until it is on the right side of the exit line: the side is 1 for a reversed
    ///   teleporter or for a player that steps down, 0 otherwise (the roundoff can leave the thing
    ///   on the wrong side)
    /// </summary>
    class procedure Compute(const AInput: TTeleportLineInput; const ASide: ITeleportLineSide;
      out AOutput: TTeleportLineOutput); static;
  end;

const
  /// <summary>The most that a thing is moved away from the interpolated exit (FUDGEFACTOR)</summary>
  TELEPORT_FUDGE_FACTOR = 10;

implementation

uses
  DelphiDoom.MathCore.FixedMath,
  DelphiDoom.MathCore.Trigonometry;

{ TTeleportLineExit }

class procedure TTeleportLineExit.Compute(const AInput: TTeleportLineInput;
  const ASide: ITeleportLineSide; out AOutput: TTeleportLineOutput);
var
  LPosition: TFixed;
  LAngle: TAngle;
  LX: TFixed;
  LY: TFixed;
  LFudge: Integer;
  LSide: Integer;
  LFlag: Integer;
begin
  // the position of the thing along the source line
  if Abs(AInput.SourceDx) > Abs(AInput.SourceDy) then
    LPosition := TFixedMath.Divide(AInput.ThingX - AInput.SourceStartX, AInput.SourceDx)
  else
    LPosition := TFixedMath.Divide(AInput.ThingY - AInput.SourceStartY, AInput.SourceDy);

  // the angle between the two lines, to turn the orientation and the momentum; 180 degrees more
  // and the position flipped across the exit line if the teleporter is reversed
  LAngle := AInput.ExitAngle - AInput.SourceAngle;
  if AInput.Reverse then
    LPosition := 65536 - LPosition
  else
    LAngle := LAngle + TAngle(ANG180);

  LX := AInput.ExitEndX - TFixedMath.Mul(LPosition, AInput.ExitDx);
  LY := AInput.ExitEndY - TFixedMath.Mul(LPosition, AInput.ExitDy);

  AOutput.Angle := LAngle;
  AOutput.Sine := TTrigonometry.FineSine(LAngle shr ANGLETOFINESHIFT);
  AOutput.Cosine := TTrigonometry.FineCosine(LAngle shr ANGLETOFINESHIFT);

  // the side of the exit line on which the thing must come out
  if AInput.Reverse or (AInput.ThingIsPlayer and AInput.StepDown) then
    LSide := 1
  else
    LSide := 0;

  LFudge := TELEPORT_FUDGE_FACTOR;
  while (ASide.PointOnSide(LX, LY) <> LSide) and (LFudge >= 0) do
  begin
    Dec(LFudge);
    if Abs(AInput.ExitDx) > Abs(AInput.ExitDy) then
    begin
      LFlag := Ord(Ord(AInput.ExitDx < 0) <> LSide);
      LY := LY - (1 - 2 * LFlag);
    end
    else
    begin
      LFlag := Ord(Ord(AInput.ExitDy < 0) <> LSide);
      LX := LX + (1 - 2 * LFlag);
    end;
  end;

  AOutput.X := LX;
  AOutput.Y := LY;
end;

end.
