{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the minimum size of the zone memory                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Startup.ZoneSize;

interface

type
  /// <summary>
  ///   The minimum size in megabytes of the zone memory: a base that depends on the game (Hexen
  ///   needs more) plus the megabytes of the screen buffers
  /// </summary>
  TStartupZoneSize = class sealed
  public
    const
      DefaultBaseMegabytes = 6;
      HexenBaseMegabytes = 8;
    /// <summary>The base of the game plus the whole megabytes that the screen buffers use</summary>
    class function MinimumMegabytes(const ABaseMegabytes, AScreensBytes: Integer): Integer; static;
  end;

implementation

class function TStartupZoneSize.MinimumMegabytes(const ABaseMegabytes, AScreensBytes: Integer): Integer;
begin
  Result := ABaseMegabytes + AScreensBytes div (1024 * 1024);
end;

end.