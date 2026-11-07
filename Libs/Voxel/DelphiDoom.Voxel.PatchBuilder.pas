{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the sprite patch of a voxel                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.PatchBuilder;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>
  ///   The sprite of a voxel: the patch (the picture lump of Doom) of the cube seen from the top
  ///   of the z axis. For each x and y the first voxel along z gives the color; the color becomes
  ///   the nearest of the palette of the game. The side is made even and the origin of the
  ///   patch is the middle of the bottom. This is the old CreateDoomPatch, byte by byte.
  /// </summary>
  TVoxelPatchBuilder = class(TInterfacedObject, IVoxelPatchBuilder)
  strict private
    FMapper: IVoxelColorMapper;
  public
    constructor Create(const AMapper: IVoxelColorMapper);
    function Build(const ACube: IVoxelCube): TBytes;
  end;

implementation

uses
  System.Classes;

{ TVoxelPatchBuilder }

constructor TVoxelPatchBuilder.Create(const AMapper: IVoxelColorMapper);
begin
  inherited Create;
  if not Assigned(AMapper) then
    raise EArgumentNilException.Create('AMapper');
  FMapper := AMapper;
end;

function TVoxelPatchBuilder.Build(const ACube: IVoxelCube): TBytes;
var
  LImage: TArray<Cardinal>;
  LCells: TArray<Cardinal>;
  LSide: Integer;
  LX, LY, LZ: Integer;
  LColor: Cardinal;
  LColumns: TBytesStream;
  LHead: TBytesStream;
  LOffsets: TArray<Integer>;
  LPixels: TBytes;
  LPixelCount: Integer;

  procedure WriteByte(const AStream: TStream; const AValue: Integer);
  var
    LByte: Byte;
  begin
    LByte := Byte(AValue and $FF);
    AStream.WriteBuffer(LByte, 1);
  end;

  procedure WriteSmallInt(const AStream: TStream; const AValue: Integer);
  var
    LValue: SmallInt;
  begin
    LValue := SmallInt(AValue);
    AStream.WriteBuffer(LValue, 2);
  end;

  procedure FlushPixels(const ARow: Integer);
  begin
    if LPixelCount > 0 then
    begin
      // a post: top, length, a byte of padding, the pixels and a byte of padding
      WriteByte(LColumns, ARow - LPixelCount);
      WriteByte(LColumns, LPixelCount);
      WriteByte(LColumns, 0);
      LColumns.WriteBuffer(LPixels[0], LPixelCount);
      WriteByte(LColumns, 0);
      LPixelCount := 0;
    end;
  end;

begin
  if not Assigned(ACube) then
    raise EArgumentNilException.Create('ACube');
  LSide := ACube.Size;
  LCells := ACube.Cells;

  // the top view
  SetLength(LImage, LSide * LSide);
  for LX := 0 to LSide - 1 do
    for LY := 0 to LSide - 1 do
    begin
      LColor := 0;
      for LZ := 0 to LSide - 1 do
        if LCells[(LX * LSide + LY) * LSide + LZ] <> 0 then
        begin
          LColor := LCells[(LX * LSide + LY) * LSide + LZ];
          Break;
        end;
      LImage[LX * LSide + LY] := LColor;
    end;

  if Odd(LSide) then
    Inc(LSide);

  LColumns := TBytesStream.Create;
  LHead := TBytesStream.Create;
  try
    SetLength(LPixels, LSide);
    SetLength(LOffsets, LSide);
    WriteSmallInt(LHead, LSide);
    WriteSmallInt(LHead, LSide);
    WriteSmallInt(LHead, LSide div 2);
    WriteSmallInt(LHead, LSide);

    for LX := 0 to LSide - 1 do
    begin
      LOffsets[LX] := LColumns.Position + 8 + LSide * SizeOf(Integer);
      LPixelCount := 0;
      for LY := 0 to LSide - 1 do
      begin
        // the side of the image is the one of the cube: the extra column and row are empty
        if (LX < ACube.Size) and (LY < ACube.Size) then
          LColor := LImage[LX * ACube.Size + LY]
        else
          LColor := 0;
        if LColor and $FFFFFF = 0 then
        begin
          FlushPixels(LY);
          Continue;
        end;
        LPixels[LPixelCount] := FMapper.PaletteIndex(LColor);
        Inc(LPixelCount);
      end;
      FlushPixels(LSide);
      // the end of the column
      WriteByte(LColumns, 255);
      WriteByte(LColumns, 0);
    end;

    for LX := 0 to LSide - 1 do
      LHead.WriteBuffer(LOffsets[LX], SizeOf(Integer));

    SetLength(Result, LHead.Size + LColumns.Size);
    Move(LHead.Bytes[0], Result[0], LHead.Size);
    if LColumns.Size > 0 then
      Move(LColumns.Bytes[0], Result[LHead.Size], LColumns.Size);
  finally
    LHead.Free;
    LColumns.Free;
  end;
end;

end.
