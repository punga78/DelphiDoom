{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - integer ranges                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.Range;

interface

type
  /// <summary>The range test of the old code, where the limits can be given in either order</summary>
  TInfoRange = class sealed
  public
    /// <summary>True if AValue is between the two limits, both included (the old IsIntegerInRange)</summary>
    class function Contains(const AValue, ALimit1, ALimit2: Integer): Boolean; static;
  end;

implementation

{ TInfoRange }

class function TInfoRange.Contains(const AValue, ALimit1, ALimit2: Integer): Boolean;
begin
  if ALimit1 < ALimit2 then
    Result := (AValue >= ALimit1) and (AValue <= ALimit2)
  else
    Result := (AValue >= ALimit2) and (AValue <= ALimit1);
end;

end.
