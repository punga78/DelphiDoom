{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the lumps of the color regions                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.ColorRegionLumps;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types;

type
  /// <summary>
  ///   The lumps between CR_START and CR_END that really are color regions. The engine wants
  ///   REGION_COUNT of them, but a WAD (for instance the system WAD of Rad-X) can have fewer:
  ///   the lumps after CR_END are not color regions and must not be read into the tables
  /// </summary>
  TColorRegionLumps = class
  public
    /// <summary>
    ///   How many of the lumps that follow CR_START are color regions: the leading ones that
    ///   are not CR_END and have the size of a table (COLORMAP_ROW_SIZE bytes). The others
    ///   keep the identity table
    /// </summary>
    /// <param name="ANames">The names of the lumps after CR_START, in the order of the directory</param>
    /// <param name="ALengths">The sizes of those lumps, as many as the names</param>
    class function ValidCount(const ANames: TArray<string>;
      const ALengths: TArray<Integer>): Integer; static;
  end;

implementation

const
  SColorRegionsEnd = 'CR_END';

{ TColorRegionLumps }

class function TColorRegionLumps.ValidCount(const ANames: TArray<string>;
  const ALengths: TArray<Integer>): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(ANames) do
  begin
    if Result >= REGION_COUNT then
      Break;
    if SameText(ANames[LIndex], SColorRegionsEnd) then
      Break;
    if (LIndex > High(ALengths)) or (ALengths[LIndex] <> COLORMAP_ROW_SIZE) then
      Break;
    Inc(Result);
  end;
end;

end.
