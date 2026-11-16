{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixBitmapTable                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The table of the wall bitmaps that GenerateTextures and GenerateFlats of    }
{  radix_xlat_wad.pas read in the same way                                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.BitmapTable;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Intf;

type
  /// <summary>
  ///   Reads the lump "WallBitmaps": a word with the number of bitmaps, then the position of the
  ///   table, a record of 40 bytes for each bitmap (name, position of the pixels, height, width)
  /// </summary>
  TRadixBitmapTable = class
  public
    /// <summary>False when the container has no such lump; ERadixException when it is not good</summary>
    class function TryRead(const AContainer: IRadixContainer;
      out ATable: TArray<TRadixBitmapRecord>): Boolean; static;
  end;

implementation

{ TRadixBitmapTable }

class function TRadixBitmapTable.TryRead(const AContainer: IRadixContainer;
  out ATable: TArray<TRadixBitmapRecord>): Boolean;
var
  LIndex: Integer;
  LHead: TBytes;
  LCount: Integer;
  LStart: Integer;
  LBytes: TBytes;
begin
  LIndex := AContainer.IndexOf('WallBitmaps');
  Result := LIndex >= 0;
  if not Result then
  begin
    ATable := nil;
    Exit;
  end;
  LHead := AContainer.ReadAt(AContainer.Infos[LIndex].Position, 6);
  LCount := LHead[0] or (LHead[1] shl 8);
  LStart := Integer(LHead[2]) or (Integer(LHead[3]) shl 8) or (Integer(LHead[4]) shl 16) or
    (Integer(LHead[5]) shl 24);
  LBytes := AContainer.ReadAt(LStart, LCount * SizeOf(TRadixBitmapRecord));
  SetLength(ATable, LCount);
  if LCount > 0 then
    Move(LBytes[0], ATable[0], LCount * SizeOf(TRadixBitmapRecord));
end;

end.
