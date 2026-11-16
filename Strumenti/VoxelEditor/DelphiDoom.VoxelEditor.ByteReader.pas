{******************************************************************************}
{                                                                              }
{  DelphiDoom: VoxelEditor library - reader of the numbers of the voxel files  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.ByteReader;

interface

uses
  System.SysUtils,
  DelphiDoom.Bytes.Reader;

type
  /// <summary>
  ///   Reads little endian numbers from the bytes of a file. A read beyond the end is an EVoxelEditorException: the
  ///   old loaders read what the stream gave, and a short file left the rest of their variables as they were. The
  ///   cursor is the common TByteReader of Framework\Bytes; this class only gives it the exception of this library
  /// </summary>
  TVoxelEditorByteReader = class(TByteReader)
  strict private
    function GetBytes: TBytes;
  protected
    procedure RaiseOverrun(ACount: Integer); override;
  public
    property Bytes: TBytes read GetBytes;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types;

resourcestring
  SByteReaderShort = 'the file ends too soon';

{ TVoxelEditorByteReader }

function TVoxelEditorByteReader.GetBytes: TBytes;
begin
  Result := Data;
end;

procedure TVoxelEditorByteReader.RaiseOverrun(ACount: Integer);
begin
  raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SByteReaderShort]);
end;

end.
