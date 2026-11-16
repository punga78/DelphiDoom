{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the samples and coefficients of one component            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.ComponentBuffers;

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   The memory of a component: the plane of samples that the inverse DCT
  ///   fills (a whole number of blocks in each direction) and, when the image
  ///   has more than one scan, the coefficients of all its blocks
  /// </summary>
  TJpegComponentBuffers = class
  private
    FPlane: TBytes;
    FPlaneStride: Integer;
    FPlaneRows: Integer;
    FCoefficients: TArray<Integer>;
    FBlockColumns: Integer;
    FBlockRows: Integer;
    class function CheckedSize(AFirst, ASecond, AThird: Int64): Integer; static;
  public
    /// <summary>
    ///   The size of the plane of the component: AWidthInBlocks x
    ///   AHeightInBlocks blocks. No memory is taken until AllocatePlane
    /// </summary>
    constructor Create(AWidthInBlocks, AHeightInBlocks: Integer);

    /// <summary>
    ///   Takes the memory of the plane
    /// </summary>
    /// <exception cref="EOutOfMemory">The plane does not fit in memory</exception>
    procedure AllocatePlane;

    /// <summary>
    ///   Sets every sample of the plane to AValue. A plane that the scans fill
    ///   completely does not need it; it is for a component that no scan of
    ///   an image in one scan gives, whose samples would be anything
    /// </summary>
    procedure FillPlane(AValue: Byte);

    /// <summary>
    ///   Room for the coefficients of AColumns x ARows blocks, all zero
    /// </summary>
    /// <exception cref="EOutOfMemory">They do not fit in memory</exception>
    procedure AllocateCoefficients(AColumns, ARows: Integer);

    /// <summary>The first sample of a row of the plane</summary>
    function PlaneRow(ARow: Integer): PByte; inline;

    /// <summary>The coefficients of the block at a row and a column of blocks</summary>
    function Block(ARow, AColumn: Integer): PJpegBlock; inline;

    property PlaneStride: Integer read FPlaneStride;
    property PlaneRows: Integer read FPlaneRows;
    property BlockColumns: Integer read FBlockColumns;
    property BlockRows: Integer read FBlockRows;
  end;

implementation

{ TJpegComponentBuffers }

class function TJpegComponentBuffers.CheckedSize(AFirst, ASecond,
  AThird: Int64): Integer;
var
  LSize: Int64;
begin
  // The memory of a stream is limited by what an array can hold
  LSize := AFirst * ASecond * AThird;
  if LSize > High(Integer) then
    OutOfMemoryError;
  Result := Integer(LSize);
end;

constructor TJpegComponentBuffers.Create(AWidthInBlocks, AHeightInBlocks: Integer);
begin
  inherited Create;
  FPlaneStride := AWidthInBlocks * JPEG_DCT_SIZE;
  FPlaneRows := AHeightInBlocks * JPEG_DCT_SIZE;
end;

procedure TJpegComponentBuffers.AllocatePlane;
begin
  SetLength(FPlane, CheckedSize(FPlaneStride, FPlaneRows, 1));
end;

procedure TJpegComponentBuffers.FillPlane(AValue: Byte);
begin
  if Length(FPlane) > 0 then
    FillChar(FPlane[0], Length(FPlane), AValue);
end;

procedure TJpegComponentBuffers.AllocateCoefficients(AColumns, ARows: Integer);
begin
  FBlockColumns := AColumns;
  FBlockRows := ARows;
  SetLength(FCoefficients, CheckedSize(AColumns, ARows, JPEG_DCT_SIZE2));
end;

function TJpegComponentBuffers.PlaneRow(ARow: Integer): PByte;
begin
  Result := @FPlane[ARow * FPlaneStride];
end;

function TJpegComponentBuffers.Block(ARow, AColumn: Integer): PJpegBlock;
begin
  Result := PJpegBlock(@FCoefficients[(ARow * FBlockColumns + AColumn) * JPEG_DCT_SIZE2]);
end;

end.
