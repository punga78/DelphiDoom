{******************************************************************************}
{                                                                              }
{  DD_Tools: the clipboard of Windows for the voxel editor                      }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.VoxelClipboard;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Intf;

type
  /// <summary>
  ///   IVoxelEditorClipboard on the clipboard of the VCL: a bitmap goes in, and the bitmap that is there, stretched
  ///   to the size of the voxel, comes out
  /// </summary>
  TVclVoxelEditorClipboard = class(TInterfacedObject, IVoxelEditorClipboard)
  public
    function TryGetImage(ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
    procedure SetImage(const AImage: TVoxelEditorImage; ASize: Integer);
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Graphics, Vcl.Clipbrd,
  DelphiDoom.Tools.Win.VoxelBitmaps;

{ TVclVoxelEditorClipboard }

function TVclVoxelEditorClipboard.TryGetImage(ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
var
  LBitmap: TBitmap;
begin
  Result := Clipboard.HasFormat(CF_BITMAP);
  if not Result then
    Exit;
  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromClipboardFormat(CF_BITMAP, Clipboard.GetAsHandle(CF_BITMAP), 0);
    AImage := TVoxelBitmaps.FromBitmap(LBitmap, ASize);
  finally
    LBitmap.Free;
  end;
end;

procedure TVclVoxelEditorClipboard.SetImage(const AImage: TVoxelEditorImage; ASize: Integer);
var
  LBitmap: TBitmap;
begin
  LBitmap := TVoxelBitmaps.ToBitmap(AImage, ASize);
  try
    Clipboard.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

end.
