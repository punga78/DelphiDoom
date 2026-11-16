{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text art: the types                             }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextArt.Types;

interface

type
  /// <summary>How a picture becomes a text screen (the textartmethod_t of ENDEDIT)</summary>
  TEndoomTextArtKind = (
    /// <summary>Only the background of each cell, from the average color of its four pixels</summary>
    eakBackgroundOnly,
    /// <summary>A background, or a foreground with a full block, whichever is nearest</summary>
    eakBackgroundForeground,
    /// <summary>The shades of the DOS font (a blend of a foreground and a background)</summary>
    eakDither,
    /// <summary>Block characters: the halves of a cell (six)</summary>
    eakSpecialCharacters,
    /// <summary>The block characters and nine frame corners, which cover three quarters of a cell</summary>
    eakExtendedSpecialCharacters
  );

const
  /// <summary>The names of the methods, as ENDEDIT shows them</summary>
  ENDOOM_TEXT_ART_NAMES: array[TEndoomTextArtKind] of string = (
    'Background only',
    'Background & Foreground',
    'Dithering',
    'Use Special Characters',
    'Use Extended Special Characters'
  );

type
  /// <summary>
  ///   The four pixels of the picture that a cell stands for, $00RRGGBB (a cell is 2x2 pixels of
  ///   the picture that was shrunk to 160x50)
  /// </summary>
  TEndoomTextArtSamples = record
    TopLeft: Cardinal;
    TopRight: Cardinal;
    BottomLeft: Cardinal;
    BottomRight: Cardinal;
    /// <summary>The sample 0..3 in the order top left, top right, bottom left, bottom right</summary>
    function Item(AIndex: Integer): Cardinal;
    /// <summary>The average of each channel (whole numbers, cut)</summary>
    function Average: Cardinal;
  end;

  /// <summary>A cell as a method sees it: the colors are indices of ENDOOM_COLORS, the code a character of the font</summary>
  TEndoomTextArtCell = record
    Background: Integer;
    Foreground: Integer;
    Code: Byte;
  end;

implementation

{ TEndoomTextArtSamples }

function TEndoomTextArtSamples.Item(AIndex: Integer): Cardinal;
begin
  case AIndex of
    0: Result := TopLeft;
    1: Result := TopRight;
    2: Result := BottomLeft;
  else
    Result := BottomRight;
  end;
end;

function TEndoomTextArtSamples.Average: Cardinal;
var
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
begin
  LRed := (Integer((TopLeft shr 16) and $FF) + Integer((TopRight shr 16) and $FF) +
    Integer((BottomLeft shr 16) and $FF) + Integer((BottomRight shr 16) and $FF)) div 4;
  LGreen := (Integer((TopLeft shr 8) and $FF) + Integer((TopRight shr 8) and $FF) +
    Integer((BottomLeft shr 8) and $FF) + Integer((BottomRight shr 8) and $FF)) div 4;
  LBlue := (Integer(TopLeft and $FF) + Integer(TopRight and $FF) + Integer(BottomLeft and $FF) +
    Integer(BottomRight and $FF)) div 4;
  Result := (Cardinal(LRed) shl 16) or (Cardinal(LGreen) shl 8) or Cardinal(LBlue);
end;

end.
