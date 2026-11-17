{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - vectors and trace_t in the data of     }
{  the program                                                                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): trace_t of     }
{  q_shared.h. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived  }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.TraceMemory;

interface

uses
  DelphiDoom.Qvm.Intf, DelphiDoom.Collision.Q3.Types;

type
  /// <summary>
  ///   The vec3_t and the trace_t of the C where the program keeps them (little endian, 4 byte words, the layout of
  ///   Tests\Data\Q3Host\layout.golden.txt: 56 bytes, the plane at 24, the padding of the plane at zero)
  /// </summary>
  TQ3TraceMemory = class
  public
    const
      TRACE_SIZE = 56;
    /// <summary>Three floats; a null address (the VMA of a NULL pointer) is the zero vector: vec3_origin</summary>
    class function ReadVec3(const AMemory: IQvmMemory; AAddress: Integer): TQ3Vec3; static;
    class procedure WriteVec3(const AMemory: IQvmMemory; AAddress: Integer; const AValue: TQ3Vec3); static;
    class function ReadTrace(const AMemory: IQvmMemory; AAddress: Integer): TQ3Trace; static;
    class procedure WriteTrace(const AMemory: IQvmMemory; AAddress: Integer; const ATrace: TQ3Trace); static;
  end;

implementation

function Bits(AValue: Single): Integer; inline;
begin
  Result := PInteger(@AValue)^;
end;

function Float(AValue: Integer): Single; inline;
begin
  Result := PSingle(@AValue)^;
end;

class function TQ3TraceMemory.ReadVec3(const AMemory: IQvmMemory; AAddress: Integer): TQ3Vec3;
var
  LIndex: Integer;
begin
  if AAddress = 0 then
  begin
    Result[0] := 0;
    Result[1] := 0;
    Result[2] := 0;
    Exit;
  end;
  for LIndex := 0 to 2 do
    Result[LIndex] := Float(AMemory.ReadInt32(AAddress + 4 * LIndex));
end;

class procedure TQ3TraceMemory.WriteVec3(const AMemory: IQvmMemory; AAddress: Integer; const AValue: TQ3Vec3);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    AMemory.WriteInt32(AAddress + 4 * LIndex, Bits(AValue[LIndex]));
end;

class function TQ3TraceMemory.ReadTrace(const AMemory: IQvmMemory; AAddress: Integer): TQ3Trace;
begin
  Result.AllSolid := AMemory.ReadInt32(AAddress) <> 0;
  Result.StartSolid := AMemory.ReadInt32(AAddress + 4) <> 0;
  Result.Fraction := Float(AMemory.ReadInt32(AAddress + 8));
  Result.EndPos := ReadVec3(AMemory, AAddress + 12);
  Result.Plane.Normal := ReadVec3(AMemory, AAddress + 24);
  Result.Plane.Dist := Float(AMemory.ReadInt32(AAddress + 36));
  Result.Plane.PlaneType := AMemory.ReadByte(AAddress + 40);
  Result.Plane.SignBits := AMemory.ReadByte(AAddress + 41);
  Result.SurfaceFlags := AMemory.ReadInt32(AAddress + 44);
  Result.Contents := AMemory.ReadInt32(AAddress + 48);
  Result.EntityNum := AMemory.ReadInt32(AAddress + 52);
end;

class procedure TQ3TraceMemory.WriteTrace(const AMemory: IQvmMemory; AAddress: Integer; const ATrace: TQ3Trace);
begin
  AMemory.WriteInt32(AAddress, Ord(ATrace.AllSolid));
  AMemory.WriteInt32(AAddress + 4, Ord(ATrace.StartSolid));
  AMemory.WriteInt32(AAddress + 8, Bits(ATrace.Fraction));
  WriteVec3(AMemory, AAddress + 12, ATrace.EndPos);
  WriteVec3(AMemory, AAddress + 24, ATrace.Plane.Normal);
  AMemory.WriteInt32(AAddress + 36, Bits(ATrace.Plane.Dist));
  AMemory.WriteInt32(AAddress + 40, 0);
  AMemory.WriteByte(AAddress + 40, ATrace.Plane.PlaneType);
  AMemory.WriteByte(AAddress + 41, ATrace.Plane.SignBits);
  AMemory.WriteInt32(AAddress + 44, ATrace.SurfaceFlags);
  AMemory.WriteInt32(AAddress + 48, ATrace.Contents);
  AMemory.WriteInt32(AAddress + 52, ATrace.EntityNum);
end;

end.
