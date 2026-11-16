{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - Adler-32 checksum of a map                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.Adler32;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Intf;

type
  /// <summary>
  ///   The checksum that glBSP writes in the GL nodes of a map (and the engine in the name of the
  ///   GWA): Adler-32 over the bytes of VERTEXES followed by those of LINEDEFS
  /// </summary>
  TNodesAdler32 = class sealed
  public
    /// <summary>Adler-32 over the buffers one after the other, as if they were one</summary>
    class function OfBuffers(const ABuffers: array of TBytes): Cardinal; static;
    /// <summary>The checksum of the map whose label is AMapLabel</summary>
    class function OfMap(const ASource: INodesLumpSource; AMapLabel: Integer): Cardinal; static;
  end;

implementation

uses
  DelphiDoom.Nodes.Types;

const
  ADLER_MODULUS = 65521;

{ TNodesAdler32 }

class function TNodesAdler32.OfBuffers(const ABuffers: array of TBytes): Cardinal;
var
  LSumA: Cardinal;
  LSumB: Cardinal;
  LBuffer: Integer;
  LIndex: Integer;
begin
  LSumA := 1;
  LSumB := 0;
  for LBuffer := 0 to High(ABuffers) do
    for LIndex := 0 to High(ABuffers[LBuffer]) do
    begin
      LSumA := (LSumA + ABuffers[LBuffer][LIndex]) mod ADLER_MODULUS;
      LSumB := (LSumB + LSumA) mod ADLER_MODULUS;
    end;
  Result := LSumB * 65536 + LSumA;
end;

class function TNodesAdler32.OfMap(const ASource: INodesLumpSource;
  AMapLabel: Integer): Cardinal;
begin
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  Result := OfBuffers([ASource.ReadLump(AMapLabel + NODES_MAP_VERTEXES),
    ASource.ReadLump(AMapLabel + NODES_MAP_LINEDEFS)]);
end;

end.
