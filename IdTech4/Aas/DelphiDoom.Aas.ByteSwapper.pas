{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - byte order of the lumps (AAS_SwapAASData)         }
{                                                                              }
{  Port of AAS_SwapAASData of be_aas_file.c. Based on the Quake III Arena GPL  }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.ByteSwapper;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types;

type
  /// <summary>
  ///   Reverses the bytes of every number of every lump. The file is little endian, as the
  ///   machines this runs on: the reader asks for it only if it is told that the machine is
  ///   not (the original macros LittleLong and LittleShort do nothing on a little endian
  ///   machine). Difference from the C: the original passes the floats of the bounding boxes
  ///   to LittleLong as if they were integers, which on a big endian machine converts the
  ///   value instead of swapping the bytes; here the bytes are swapped like every other float.
  /// </summary>
  TAasByteSwapper = class
  strict private
    class procedure SwapLongs(const AData: Pointer; const ACount: Integer); static;
  public
    class function SwapLong(const AValue: Cardinal): Cardinal; static;
    class function SwapShort(const AValue: Word): Word; static;
    /// <summary>The lumps in place (not the header: the reader does it as it reads it)</summary>
    class procedure Swap(var AData: TAasFileData); static;
  end;

implementation

{ TAasByteSwapper }

class function TAasByteSwapper.SwapLong(const AValue: Cardinal): Cardinal;
begin
  Result := ((AValue and $FF) shl 24) or ((AValue and $FF00) shl 8) or ((AValue shr 8) and $FF00) or
    (AValue shr 24);
end;

class function TAasByteSwapper.SwapShort(const AValue: Word): Word;
begin
  Result := Word((AValue shl 8) or (AValue shr 8));
end;

class procedure TAasByteSwapper.SwapLongs(const AData: Pointer; const ACount: Integer);
var
  LValue: PCardinal;
  LIndex: Integer;
begin
  LValue := PCardinal(AData);
  for LIndex := 1 to ACount do
  begin
    LValue^ := SwapLong(LValue^);
    Inc(LValue);
  end;
end;

class procedure TAasByteSwapper.Swap(var AData: TAasFileData);
var
  LIndex: Integer;
begin
  // every record of these lumps is made of 32 bit numbers
  if Length(AData.BBoxes) > 0 then
    SwapLongs(@AData.BBoxes[0], Length(AData.BBoxes) * SizeOf(TAasBBox) div 4);
  if Length(AData.Vertexes) > 0 then
    SwapLongs(@AData.Vertexes[0], Length(AData.Vertexes) * 3);
  if Length(AData.Planes) > 0 then
    SwapLongs(@AData.Planes[0], Length(AData.Planes) * SizeOf(TAasPlane) div 4);
  if Length(AData.Edges) > 0 then
    SwapLongs(@AData.Edges[0], Length(AData.Edges) * 2);
  if Length(AData.EdgeIndex) > 0 then
    SwapLongs(@AData.EdgeIndex[0], Length(AData.EdgeIndex));
  if Length(AData.Faces) > 0 then
    SwapLongs(@AData.Faces[0], Length(AData.Faces) * SizeOf(TAasFace) div 4);
  if Length(AData.FaceIndex) > 0 then
    SwapLongs(@AData.FaceIndex[0], Length(AData.FaceIndex));
  if Length(AData.Areas) > 0 then
    SwapLongs(@AData.Areas[0], Length(AData.Areas) * SizeOf(TAasArea) div 4);
  if Length(AData.AreaSettings) > 0 then
    SwapLongs(@AData.AreaSettings[0], Length(AData.AreaSettings) * SizeOf(TAasAreaSettings) div 4);
  // the reachabilities end with a 16 bit number and two bytes of padding
  for LIndex := 0 to High(AData.Reachability) do
  begin
    SwapLongs(@AData.Reachability[LIndex], 10);
    AData.Reachability[LIndex].TravelTime := SwapShort(AData.Reachability[LIndex].TravelTime);
  end;
  if Length(AData.Nodes) > 0 then
    SwapLongs(@AData.Nodes[0], Length(AData.Nodes) * 3);
  if Length(AData.Portals) > 0 then
    SwapLongs(@AData.Portals[0], Length(AData.Portals) * SizeOf(TAasPortal) div 4);
  if Length(AData.PortalIndex) > 0 then
    SwapLongs(@AData.PortalIndex[0], Length(AData.PortalIndex));
  if Length(AData.Clusters) > 0 then
    SwapLongs(@AData.Clusters[0], Length(AData.Clusters) * 4);
end;

end.
