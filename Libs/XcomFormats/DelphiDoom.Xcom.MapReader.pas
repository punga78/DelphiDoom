{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .MAP files of the battlescape         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.MapReader;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Map, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   What BattlescapeGenerator::loadMAP reads: three bytes with the size of the block (Y, X, Z in this order), that
  ///   the C++ keeps in a char, WITH SIGN, and then four bytes for every cell (floor, west wall, north wall, object),
  ///   x first, then y, then the layers from the top one down
  /// </summary>
  TXcomMapReader = class(TInterfacedObject, IXcomMapReader)
  public
    function ReadHeader(const ABytes: TBytes): TXcomMapHeader;
    function Read(const ABytes: TBytes): TXcomMap;
  end;

implementation

{ TXcomMapReader }

function TXcomMapReader.ReadHeader(const ABytes: TBytes): TXcomMapHeader;
begin
  if Length(ABytes) < SizeOf(TXcomMapHeader) then
    raise EXcomDataException.CreateFmt(SXcomHeaderTooShort, ['the MAP file', SizeOf(TXcomMapHeader), Length(ABytes)]);
  // a Shortint: 128..255 are negative, as (int)size[0] of a char with sign in the C++
  Result.SizeY := Shortint(ABytes[0]);
  Result.SizeX := Shortint(ABytes[1]);
  Result.SizeZ := Shortint(ABytes[2]);
end;

function TXcomMapReader.Read(const ABytes: TBytes): TXcomMap;
var
  LCells: Integer;
  LMaximum: Integer;
begin
  Result.Header := ReadHeader(ABytes);
  if (Result.Header.SizeX <= 0) or (Result.Header.SizeY <= 0) or (Result.Header.SizeZ <= 0) then
    raise EXcomDataException.CreateFmt(SXcomMapBadSize,
      [Result.Header.SizeX, Result.Header.SizeY, Result.Header.SizeZ]);
  LCells := (Length(ABytes) - SizeOf(TXcomMapHeader)) div SizeOf(TXcomMapCell);
  LMaximum := Result.Header.SizeX * Result.Header.SizeY * Result.Header.SizeZ;
  if LCells > LMaximum then
    raise EXcomDataException.CreateFmt(SXcomMapTooManyCells,
      [Result.Header.SizeX, Result.Header.SizeY, Result.Header.SizeZ, LMaximum, LCells]);
  SetLength(Result.Cells, LCells);
  if LCells > 0 then
    Move(ABytes[SizeOf(TXcomMapHeader)], Result.Cells[0], LCells * SizeOf(TXcomMapCell));
end;

end.
