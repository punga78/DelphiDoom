{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a proportional font                               }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  fontstruct of id_vw.h and VWL_MeasureString of id_vw.c                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Font;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

const
  /// <summary>sizeof(fontstruct): the height, 256 offsets and 256 widths</summary>
  KEEN_FONT_HEADER_BYTES = 2 + 256 * 2 + 256;

type
  /// <summary>
  ///   A font chunk of the graphics file: the height in rows, for each character the offset of its bits from
  ///   the start of the chunk and its width in pixels. The bits of a character are one bit per pixel, row after
  ///   row, each row (width + 7) div 8 bytes
  /// </summary>
  TKeenFont = class
  strict private
    FBytes: TBytes;
    FHeight: Integer;
  public
    /// <summary>A chunk shorter than the header is an EKeenDataException</summary>
    constructor Create(const AChunk: TBytes);
    /// <summary>The width of a character in pixels (the C reads a signed char: the widths of a font are under 128)</summary>
    function CharWidth(ACharacter: Byte): Integer;
    /// <summary>The byte AColumn of the row ARow of a character; 0 where the chunk has no data</summary>
    function RowByte(ACharacter: Byte; ARow, AColumn: Integer): Byte;
    /// <summary>VWL_MeasureString: the sum of the widths of the characters</summary>
    function Measure(const AText: AnsiString): Integer;
    property Height: Integer read FHeight;
  end;

implementation

{ TKeenFont }

constructor TKeenFont.Create(const AChunk: TBytes);
begin
  inherited Create;
  if Length(AChunk) < KEEN_FONT_HEADER_BYTES then
    raise EKeenDataException.CreateFmt(SKeenFontTooShort, [Length(AChunk), KEEN_FONT_HEADER_BYTES]);
  FBytes := AChunk;
  FHeight := SmallInt(Word(AChunk[0]) or (Word(AChunk[1]) shl 8));
  if (FHeight < 0) or (FHeight > KEEN_FONT_MAX_HEIGHT) then
    raise EKeenDataException.CreateFmt(SKeenFontBadHeight, [FHeight]);
end;

function TKeenFont.CharWidth(ACharacter: Byte): Integer;
begin
  Result := FBytes[2 + 512 + ACharacter];
end;

function TKeenFont.RowByte(ACharacter: Byte; ARow, AColumn: Integer): Byte;
var
  LLocation: Integer;
  LOffset: Integer;
begin
  LLocation := Word(FBytes[2 + ACharacter * 2]) or (Word(FBytes[3 + ACharacter * 2]) shl 8);
  LOffset := LLocation + ARow * ((CharWidth(ACharacter) + 7) div 8) + AColumn;
  if (LOffset >= 0) and (LOffset < Length(FBytes)) then
    Result := FBytes[LOffset]
  else
    Result := 0;
end;

function TKeenFont.Measure(const AText: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 1 to Length(AText) do
    Inc(Result, CharWidth(Ord(AText[LIndex])));
end;

end.
