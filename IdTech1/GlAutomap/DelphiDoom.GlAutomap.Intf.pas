{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL automap - the contracts                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlAutomap.Intf;

interface

uses
  DelphiDoom.GlAutomap.Types;

type
  /// <summary>The items of the automap of one frame, in the order they have to be drawn</summary>
  /// <remarks>Colours are $RRGGBB (videopal); coordinates are pixels of the frame</remarks>
  IGlAutomapDisplayList = interface
    ['{7C1E5A94-3B60-4D2F-9A18-E5D04C7B6F31}']
    /// <summary>The rectangle (0, 0)-(AWidth, AHeight) that clears the map</summary>
    procedure AddBackground(const AWidth, AHeight: Integer; const AColor: Cardinal);
    procedure AddLine(const AX1, AY1, AX2, AY2: Integer; const AColor: Cardinal);
    procedure AddPatch(const AX, AY, ALump: Integer);
    /// <summary>A triangle of a floor: corners in pixels, texture coordinates in 16.16 fixed point</summary>
    procedure AddTriangle(const AX1, AY1, AU1, AV1, AX2, AY2, AU2, AV2, AX3, AY3, AU3, AV3: Integer;
      const AColor: Cardinal; const ALump: Integer; const AFloor: TGlAutomapFloor);
    function Count: Integer;
    /// <summary>The first item (the others follow it in memory); nil if the list is empty</summary>
    function First: PGlAutomapItem;
    /// <summary>Empties the list; the memory is kept for the next frame</summary>
    procedure Clear;
    /// <summary>Empties the list and gives the memory back</summary>
    procedure Release;
  end;

  /// <summary>Draws the items of the automap of one frame (one call per frame, never per item)</summary>
  IGlAutomapPainter = interface
    ['{2F8B6D13-A947-4E05-B3C2-18D7E9A5604B}']
    procedure Paint(const AFirst: PGlAutomapItem; const ACount: Integer);
  end;

implementation

end.
