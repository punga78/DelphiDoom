{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the contracts of the teleports               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Teleport.Intf;

interface

type
  /// <summary>
  ///   Makes the teleport fog: it is the part of the teleports that creates an object of the game
  ///   and plays a sound, so the library asks the game to do it
  /// </summary>
  ITeleportFogSpawner = interface
    ['{5A91D3C6-E208-4F47-B1A5-7D40C9E2B836}']
    /// <summary>
    ///   Makes a teleport fog at the position (fixed point) and, if ASound is true, plays the
    ///   teleport sound at the fog
    /// </summary>
    procedure SpawnFog(AX, AY, AZ: Integer; ASound: Boolean);
  end;

  /// <summary>On which side of a line a point is; the line is the one of the exit of a teleport</summary>
  ITeleportLineSide = interface
    ['{C71E4B09-3D5A-46F2-8A18-F2B6D0937E54}']
    /// <summary>0 if the point is on the front of the line, 1 on the back (P_PointOnLineSide)</summary>
    function PointOnSide(AX, AY: Integer): Integer;
  end;

implementation

end.
