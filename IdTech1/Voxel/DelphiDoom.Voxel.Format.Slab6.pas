{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the VOX format of Slab6                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Format.Slab6;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>
  ///   A VOX file of Slab6: the three sizes, one palette index for each voxel (x, then y, then z;
  ///   255 is no voxel) and at the end the palette.
  /// </summary>
  TVoxelSlab6Format = class(TInterfacedObject, IVoxelFormat)
  public
    function Handles(const AExtension: string): Boolean;
    function Locate(const ASource: IVoxelFileSource; const AName: string; out ABytes: TBytes): Boolean;
    function Decode(const ABytes: TBytes): IVoxelModel;
  end;

implementation

uses
  DelphiDoom.Voxel.ByteReader,
  DelphiDoom.Voxel.KvxPalette,
  DelphiDoom.Voxel.Model;

{ TVoxelSlab6Format }

function TVoxelSlab6Format.Handles(const AExtension: string): Boolean;
begin
  Result := AExtension = '.VOX';
end;

function TVoxelSlab6Format.Locate(const ASource: IVoxelFileSource; const AName: string;
  out ABytes: TBytes): Boolean;
begin
  Result := ASource.TryReadFile(AName, ABytes);
end;

function TVoxelSlab6Format.Decode(const ABytes: TBytes): IVoxelModel;
var
  LPalette: TArray<Cardinal>;
  LReader: TVoxelByteReader;
  LSizeX, LSizeY, LSizeZ: Integer;
  LCells: TArray<Cardinal>;
  LIndex: Integer;
  LValue: Byte;
begin
  if Length(ABytes) < SLAB6_HEADER_SIZE + VOXEL_PALETTE_BYTES then
    raise EVoxelException.CreateFmt(SVoxelTooShort, [Length(ABytes)]);
  LPalette := TVoxelKvxPalette.Read(ABytes);

  LReader := TVoxelByteReader.Create(ABytes);
  try
    LSizeX := LReader.ReadInteger;
    LSizeY := LReader.ReadInteger;
    LSizeZ := LReader.ReadInteger;
    if (LSizeX < 1) or (LSizeX > VOXEL_MAX_SIZE) or (LSizeY < 1) or (LSizeY > VOXEL_MAX_SIZE) or
      (LSizeZ < 1) or (LSizeZ > VOXEL_MAX_SIZE) then
      raise EVoxelException.CreateFmt(SVoxelInvalidSize, [LSizeX, LSizeY, LSizeZ]);
    if SLAB6_HEADER_SIZE + LSizeX * LSizeY * LSizeZ > Length(ABytes) - VOXEL_PALETTE_BYTES then
      raise EVoxelException.CreateFmt(SVoxelTruncated,
        [Length(ABytes), LSizeX * LSizeY * LSizeZ, SLAB6_HEADER_SIZE]);

    SetLength(LCells, LSizeX * LSizeY * LSizeZ);
    for LIndex := 0 to High(LCells) do
    begin
      LValue := LReader.ReadByte;
      if LValue <> SLAB6_EMPTY then
        LCells[LIndex] := LPalette[LValue];
    end;
  finally
    LReader.Free;
  end;

  Result := TVoxelModel.Create(vfSlab6, LSizeX, LSizeY, LSizeZ, 0, 0, 0, LCells, nil);
end;

end.
