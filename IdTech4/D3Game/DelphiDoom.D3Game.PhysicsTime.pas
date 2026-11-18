{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idPhysics::SnapTimeToPhysicsFrame         }
{                                                                              }
{  Port of Doom 3 (id Software): game\physics\Physics.cpp.                     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.PhysicsTime;

interface

type
  /// <summary>The time of the physics frames</summary>
  TD3PhysicsTime = class
  public
    /// <summary>idPhysics::SnapTimeToPhysicsFrame: rounds a time up to a whole number of physics frames (16 ms)</summary>
    class function SnapToFrame(const ATime: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.D3Game.Types;

class function TD3PhysicsTime.SnapToFrame(const ATime: Integer): Integer;
var
  LSum: Integer;
begin
  LSum := ATime + D3_USERCMD_MSEC - 1;
  // % of C: the sign follows the dividend (Delphi's mod does the same)
  Result := LSum - LSum mod D3_USERCMD_MSEC;
end;

end.
