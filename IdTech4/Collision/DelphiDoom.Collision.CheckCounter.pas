{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the check counter                           }
{                                                                              }
{  Replaces idCollisionModelManagerLocal::checkCount of Doom 3 GPL Source      }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
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
