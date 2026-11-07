{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL math library - the contracts                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlMath.Intf;

interface

uses
  DelphiDoom.GlMath.Types;

type
  /// <summary>The six planes of the view frustum and the tests of what is inside</summary>
  IGlFrustum = interface
    ['{4B7C0E52-6D1F-4F0A-9B36-5A2E8C13D741}']
    /// <summary>
    ///   Takes the planes from the projection and the model view matrices (the caller reads them
    ///   from OpenGL) and normalizes them
    /// </summary>
    procedure Calculate(const AProjection, AModelView: TGlMatrix4);
    /// <summary>The value of a plane: A, B, C, D (index 0..3) of a side</summary>
    function GetPlane(const ASide: TGlFrustumSide; const AIndex: Integer): Single;
    /// <summary>True if the point is in front of all the planes</summary>
    function ContainsPoint(const AX, AY, AZ: Single): Boolean;
    /// <summary>True if the sphere is not entirely behind a plane</summary>
    function ContainsSphere(const AX, AY, AZ, ARadius: Single): Boolean;
    /// <summary>True if a corner of the box is in front of each plane (min and max points)</summary>
    function ContainsBox(const AX, AY, AZ, ASizeX, ASizeY, ASizeZ: Single): Boolean;
    /// <summary>True if a corner of the cube (the center and half its length) is in front of each plane</summary>
    function ContainsCube(const AX, AY, AZ, ASize: Single): Boolean;
  end;

  /// <summary>
  ///   The set of angles already hidden by walls (the clipper of the OpenGL renderer): a range
  ///   that is all in it is not visible. Angles wrap around, so a range can pass over the zero
  /// </summary>
  IGlAngleClipper = interface
    ['{7A1D9C34-2E85-4B6F-8D03-C94F1B6A5E28}']
    /// <summary>Empties the set; the memory of the nodes is kept for the next frame</summary>
    procedure Clear;
    /// <summary>Empties the set and gives the memory back</summary>
    procedure Release;
    /// <summary>Adds a range (in two parts if it passes over the zero)</summary>
    procedure SafeAddRange(const AStartAngle, AEndAngle: TGlAngle);
    /// <summary>False if the whole range is hidden</summary>
    function SafeCheckRange(const AStartAngle, AEndAngle: TGlAngle): Boolean;
    /// <summary>The number of ranges of the set, in angle order</summary>
    function GetRangeCount: Integer;
    /// <summary>The start of a range of the set (0 is the first in angle order)</summary>
    function GetRangeStart(const AIndex: Integer): TGlAngle;
    /// <summary>The end of a range of the set</summary>
    function GetRangeFinish(const AIndex: Integer): TGlAngle;
  end;

implementation

end.
