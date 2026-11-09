{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the cells of a .MAP                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Map;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types;

type
  /// <summary>The cells of a .MAP: a block of the battlescape. It is a value</summary>
  TXcomMap = record
  public
    Header: TXcomMapHeader;
    /// <summary>The cells in the order of the file: layers from the top one, then rows, then columns</summary>
    Cells: TArray<TXcomMapCell>;
    function SizeX: Integer;
    function SizeY: Integer;
    function SizeZ: Integer;
    /// <summary>
    ///   The cell at AX, AY, AZ of the block, with AZ = 0 the lowest layer as BattlescapeGenerator::loadMAP puts
    ///   it (the file lists the top layer first). A cell that the file does not have is empty (all zero)
    /// </summary>
    function CellAt(AX, AY, AZ: Integer): TXcomMapCell;
  end;

implementation

{ TXcomMap }

function TXcomMap.SizeX: Integer;
begin
  Result := Header.SizeX;
end;

function TXcomMap.SizeY: Integer;
begin
  Result := Header.SizeY;
end;

function TXcomMap.SizeZ: Integer;
begin
  Result := Header.SizeZ;
end;

function TXcomMap.CellAt(AX, AY, AZ: Integer): TXcomMapCell;
var
  LIndex: Integer;
begin
  if (AX < 0) or (AX >= SizeX) or (AY < 0) or (AY >= SizeY) or (AZ < 0) or (AZ >= SizeZ) then
    raise EXcomException.CreateFmt(SXcomMapCellOutside, [AX, AY, AZ, SizeX, SizeY, SizeZ]);
  LIndex := ((SizeZ - 1 - AZ) * SizeY + AY) * SizeX + AX;
  if LIndex >= Length(Cells) then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Exit;
  end;
  Result := Cells[LIndex];
end;

end.
