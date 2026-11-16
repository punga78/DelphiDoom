{******************************************************************************}
{                                                                              }
{  DelphiDoom: Voxel library - reader of the numbers of the voxel files        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.ByteReader;

interface

uses
  System.SysUtils,
  DelphiDoom.Bytes.Reader,
  DelphiDoom.Voxel.Types;

type
  /// <summary>
  ///   Reads numbers of the voxel files (little endian) from the bytes: a read beyond the end is
  ///   an EVoxelException, never a read of memory that is not there. The cursor is the common
  ///   TByteReader of Framework\Bytes; this class only gives it the exception of this library
  /// </summary>
  TVoxelByteReader = class(TByteReader)
  protected
    procedure RaiseOverrun(ACount: Integer); override;
  end;

implementation

{ TVoxelByteReader }

procedure TVoxelByteReader.RaiseOverrun(ACount: Integer);
begin
  raise EVoxelException.CreateFmt(SVoxelTruncated, [Size, ACount, Position]);
end;

end.
