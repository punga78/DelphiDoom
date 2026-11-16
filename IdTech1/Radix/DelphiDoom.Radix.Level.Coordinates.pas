{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelCoordinates                          }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of fix_wall_coordXY and fix_wall_coordXYdef of radix_level.pas:        }
{  from the coordinates of Radix to the ones of the Doom map                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Coordinates;

interface

type
  TRadixLevelCoordinates = class
  strict private
    FSplitMap: Boolean;
  public
    /// <param name="ASplitMap">True for E3M2 of the 2.0: the part of the map past x = 48000 is moved to another place</param>
    constructor Create(ASplitMap: Boolean);
    /// <summary>fix_wall_coordXYdef: the usual position</summary>
    class procedure ConvertDefault(var AX, AY: Integer); static;
    /// <summary>fix_wall_coordXY: the usual position, or the one of the split part</summary>
    procedure Convert(var AX, AY: Integer);
    property SplitMap: Boolean read FSplitMap;
  end;

implementation

uses
  DelphiDoom.Radix.Level.Types;

{$Q-}
{$R-}

{ TRadixLevelCoordinates }

constructor TRadixLevelCoordinates.Create(ASplitMap: Boolean);
begin
  inherited Create;
  FSplitMap := ASplitMap;
end;

class procedure TRadixLevelCoordinates.ConvertDefault(var AX, AY: Integer);
begin
  AX := RADIX_MAP_X_MULT * AX + RADIX_MAP_X_ADD;
  AY := RADIX_MAP_Y_MULT * AY + RADIX_MAP_Y_ADD;
end;

procedure TRadixLevelCoordinates.Convert(var AX, AY: Integer);
begin
  if (AX >= E3M2_SPLIT_X) and FSplitMap then
  begin
    AX := RADIX_MAP_X_MULT * AX + RADIX_MAP_X_ADD2;
    AY := RADIX_MAP_Y_MULT * AY + RADIX_MAP_Y_ADD2;
    Exit;
  end;
  ConvertDefault(AX, AY);
end;

end.
