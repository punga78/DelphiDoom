{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - things and lines of a map in the Hexen format   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.HexenConverter;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Types;

type
  /// <summary>
  ///   A map with a BEHAVIOR lump is in the Hexen format, but the engine of the other games
  ///   reads THINGS and LINEDEFS in their own format: before the node builder (which is told
  ///   that the map is a Hexen one) reads them, they are written as Hexen records, without
  ///   height, tid, arguments (and without the special of a line if it does not fit in a byte)
  /// </summary>
  TNodesHexenConverter = class sealed
  public
    /// <summary>THINGS of 10 bytes to THINGS of 20 bytes; a last partial record is dropped</summary>
    class function ConvertThings(const ABytes: TBytes): TBytes; static;
    /// <summary>LINEDEFS of 14 bytes to LINEDEFS of 16 bytes; a last partial record is dropped</summary>
    class function ConvertLinedefs(const ABytes: TBytes): TBytes; static;
  end;

implementation

{ TNodesHexenConverter }

class function TNodesHexenConverter.ConvertThings(const ABytes: TBytes): TBytes;
var
  LCount: Integer;
  LIndex: Integer;
  LVanilla: TNodesVanillaThing;
  LHexen: TNodesHexenThing;
begin
  LCount := Length(ABytes) div SizeOf(TNodesVanillaThing);
  SetLength(Result, LCount * SizeOf(TNodesHexenThing));
  for LIndex := 0 to LCount - 1 do
  begin
    Move(ABytes[LIndex * SizeOf(TNodesVanillaThing)], LVanilla, SizeOf(LVanilla));
    FillChar(LHexen, SizeOf(LHexen), 0);
    LHexen.X := LVanilla.X;
    LHexen.Y := LVanilla.Y;
    LHexen.Angle := LVanilla.Angle;
    LHexen.ThingType := LVanilla.ThingType;
    LHexen.Options := LVanilla.Options;
    Move(LHexen, Result[LIndex * SizeOf(TNodesHexenThing)], SizeOf(LHexen));
  end;
end;

class function TNodesHexenConverter.ConvertLinedefs(const ABytes: TBytes): TBytes;
var
  LCount: Integer;
  LIndex: Integer;
  LVanilla: TNodesVanillaLinedef;
  LHexen: TNodesHexenLinedef;
begin
  LCount := Length(ABytes) div SizeOf(TNodesVanillaLinedef);
  SetLength(Result, LCount * SizeOf(TNodesHexenLinedef));
  for LIndex := 0 to LCount - 1 do
  begin
    Move(ABytes[LIndex * SizeOf(TNodesVanillaLinedef)], LVanilla, SizeOf(LVanilla));
    FillChar(LHexen, SizeOf(LHexen), 0);
    LHexen.Vertex1 := LVanilla.Vertex1;
    LHexen.Vertex2 := LVanilla.Vertex2;
    LHexen.Flags := LVanilla.Flags;
    if (LVanilla.Special >= 0) and (LVanilla.Special <= 255) then
      LHexen.Special := LVanilla.Special;
    // sidenum[1] is -1 if the line has one side
    LHexen.SideNumber[0] := LVanilla.SideNumber[0];
    LHexen.SideNumber[1] := LVanilla.SideNumber[1];
    Move(LHexen, Result[LIndex * SizeOf(TNodesHexenLinedef)], SizeOf(LHexen));
  end;
end;

end.
