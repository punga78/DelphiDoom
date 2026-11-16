{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a font of the game                               }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): font_t and FN_RawWidth of   }
{  d_font.pas                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Font;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types;

const
  /// <summary>SizeOf(font_t): the height (a word), 256 widths (bytes) and 256 offsets (words)</summary>
  GREED_FONT_HEADER_BYTES = 2 + 256 + 512;

type
  /// <summary>
  ///   A font lump (FONT1, FONT2, FONT3): font_t and, at the offset of each character counted from the start of
  ///   the lump, its pixels a COLUMN after the other, each of Height bytes from the top down. A pixel 0 is the
  ///   background; the others are added to the base color of the text. A character above 255 is taken modulo 256
  ///   (the original indexes its tables with the UTF-16 code and reads outside them)
  /// </summary>
  TGreedFont = class
  strict private
    FLump: TBytes;
    FHeight: Integer;
  public
    constructor Create(const ALump: TBytes);
    /// <summary>font.width[ch]</summary>
    function CharWidth(ACharacter: Char): Integer; inline;
    /// <summary>font.charofs[ch]: where the columns of the character start in the lump (a word with sign)</summary>
    function CharOffset(ACharacter: Char): Integer;
    /// <summary>The byte of the lump at that place; 0 outside the lump (the original reads the memory beside it)</summary>
    function DataAt(AOffset: Integer): Byte; inline;
    /// <summary>FN_RawWidth: the widths of the characters, each followed by the spacing. Newlines are not handled</summary>
    function RawWidth(const AText: string; ASpacing: Integer = 1): Integer;
    /// <summary>font.height</summary>
    property Height: Integer read FHeight;
  end;

implementation

uses
  DelphiDoom.Greed.LittleEndian;

const
  WIDTHS_AT = 2;
  OFFSETS_AT = 2 + 256;

{ TGreedFont }

constructor TGreedFont.Create(const ALump: TBytes);
begin
  inherited Create;
  if Length(ALump) < GREED_FONT_HEADER_BYTES then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, ['font', Length(ALump), GREED_FONT_HEADER_BYTES]);
  FLump := ALump;
  FHeight := TGreedLittleEndian.ReadSmallInt(ALump, 0);
end;

function TGreedFont.CharWidth(ACharacter: Char): Integer;
begin
  Result := FLump[WIDTHS_AT + (Ord(ACharacter) and $FF)];
end;

function TGreedFont.CharOffset(ACharacter: Char): Integer;
begin
  Result := TGreedLittleEndian.ReadSmallInt(FLump, OFFSETS_AT + 2 * (Ord(ACharacter) and $FF));
end;

function TGreedFont.DataAt(AOffset: Integer): Byte;
begin
  if (AOffset < 0) or (AOffset >= Length(FLump)) then
    Result := 0
  else
    Result := FLump[AOffset];
end;

function TGreedFont.RawWidth(const AText: string; ASpacing: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 1 to Length(AText) do
    Result := Result + CharWidth(AText[LIndex]) + ASpacing;
end;

end.
