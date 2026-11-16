{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the check counter                           }
{                                                                              }
{  Replaces idCollisionModelManagerLocal::checkCount of Doom 3 GPL Source      }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.CheckCounter;

interface

type
  /// <summary>
  ///   The counter of the "multi-check avoidance" of the C++ code: every operation takes a
  ///   new value and marks the polygons, brushes, edges and vertices it visited with it. It
  ///   is shared by the objects that work on the same models (the C++ manager has one
  ///   field), and is an object, not a global, so two managers do not disturb each other.
  /// </summary>
  TCollisionCheckCounter = class
  private
    FValue: Integer;
  public
    /// <summary>Current value (the one stamped on visited items)</summary>
    property Value: Integer read FValue;
    /// <summary>Starts a new operation and returns the new value (checkCount++)</summary>
    function Next: Integer;
  end;

implementation

{ TCollisionCheckCounter }

function TCollisionCheckCounter.Next: Integer;
begin
  Inc(FValue);
  Result := FValue;
end;

end.
