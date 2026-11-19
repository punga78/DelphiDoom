{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the structures   }
{  of a module                                                                 }
{                                                                              }
{  refEntity_t, refdef_t and polyVert_t as cgame lays them out in the memory   }
{  of the virtual machine (tr_types.h, 32 bit, little endian), read as the C   }
{  reads them through a pointer. Written for the repository (licence GPL v2 or }
{  later).                                                                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Scene.Reader;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Render.Scene.Types;

type
  /// <summary>Reads the structures of the renderer from the memory of a program</summary>
  TQ3SceneReader = class sealed
  public
    /// <summary>The refEntity_t at the address (140 bytes)</summary>
    class function ReadRefEntity(const AMemory: IQvmMemory; AAddress: Integer): TQ3RefEntity; static;
    /// <summary>The refdef_t at the address (368 bytes): the deform texts are not read</summary>
    class function ReadRefDef(const AMemory: IQvmMemory; AAddress: Integer): TQ3RefDef; static;
    /// <summary>ACount polyVert_t (24 bytes each)</summary>
    class function ReadPolyVerts(const AMemory: IQvmMemory; AAddress, ACount: Integer): TArray<TQ3PolyVert>; static;
    /// <summary>Four floats, or none for the address 0 (NULL: the caller takes white)</summary>
    class function ReadColor(const AMemory: IQvmMemory; AAddress: Integer): TArray<Single>; static;
  end;

implementation

class function TQ3SceneReader.ReadRefEntity(const AMemory: IQvmMemory; AAddress: Integer): TQ3RefEntity;
var
  LBytes: TBytes;
begin
  LBytes := AMemory.ReadBytes(AAddress, Q3_REFENTITY_SIZE);
  Move(LBytes[0], Result, Q3_REFENTITY_SIZE);
end;

class function TQ3SceneReader.ReadRefDef(const AMemory: IQvmMemory; AAddress: Integer): TQ3RefDef;
var
  LBytes: TBytes;
  LIndex: Integer;

  function ReadInt(AOffset: Integer): Integer;
  begin
    Result := PInteger(@LBytes[AOffset])^;
  end;

  function ReadFloat(AOffset: Integer): Single;
  begin
    Result := PSingle(@LBytes[AOffset])^;
  end;

begin
  LBytes := AMemory.ReadBytes(AAddress, Q3_REFDEF_SIZE);
  Result := Default(TQ3RefDef);
  Result.X := ReadInt(0);
  Result.Y := ReadInt(4);
  Result.Width := ReadInt(8);
  Result.Height := ReadInt(12);
  Result.FovX := ReadFloat(16);
  Result.FovY := ReadFloat(20);
  for LIndex := 0 to 2 do
    Result.ViewOrigin[LIndex] := ReadFloat(24 + 4 * LIndex);
  for LIndex := 0 to 8 do
    Result.ViewAxis[LIndex div 3][LIndex mod 3] := ReadFloat(36 + 4 * LIndex);
  Result.Time := ReadInt(72);
  Result.RdFlags := ReadInt(76);
  Move(LBytes[80], Result.AreaMask[0], Q3_MAX_MAP_AREA_BYTES);
end;

class function TQ3SceneReader.ReadPolyVerts(const AMemory: IQvmMemory; AAddress, ACount: Integer):
  TArray<TQ3PolyVert>;
var
  LBytes: TBytes;
begin
  SetLength(Result, 0);
  if ACount <= 0 then
    Exit;
  LBytes := AMemory.ReadBytes(AAddress, ACount * Q3_POLYVERT_SIZE);
  SetLength(Result, ACount);
  Move(LBytes[0], Result[0], ACount * Q3_POLYVERT_SIZE);
end;

class function TQ3SceneReader.ReadColor(const AMemory: IQvmMemory; AAddress: Integer): TArray<Single>;
var
  LBytes: TBytes;
begin
  SetLength(Result, 0);
  if AAddress = 0 then
    Exit;
  LBytes := AMemory.ReadBytes(AAddress, 16);
  SetLength(Result, 4);
  Move(LBytes[0], Result[0], 16);
end;

end.
