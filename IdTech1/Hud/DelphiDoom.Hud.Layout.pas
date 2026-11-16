{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the glyphs of a piece of text        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.Layout;

interface

uses
  DelphiDoom.Hud.Types;

type
  /// <summary>
  ///   Where the glyphs of a text go: the result of the layout, kept by the drawing and used again
  ///   for every frame (the list grows when needed and never shrinks, so a frame does not allocate)
  /// </summary>
  THudLayout = class sealed
  strict private
    FGlyphs: TArray<THudGlyph>;
    FCount: Integer;
    FCursorFits: Boolean;
    FCursorX: Integer;
    FCursorY: Integer;
    FEndX: Integer;
    FEndY: Integer;
  public
    constructor Create;
    /// <summary>Forgets the glyphs and the cursor</summary>
    procedure Reset;
    /// <summary>Adds a glyph</summary>
    procedure Add(const AIndex, AX, AY: Integer; const AHighlighted: Boolean = False);
    /// <summary>Glyphs, only the first Count are valid (read them, do not change them)</summary>
    property Glyphs: TArray<THudGlyph> read FGlyphs;
    /// <summary>Glyphs in the list</summary>
    property Count: Integer read FCount;
    /// <summary>The cursor fits on the screen and must be drawn at (CursorX, CursorY)</summary>
    property CursorFits: Boolean read FCursorFits write FCursorFits;
    property CursorX: Integer read FCursorX write FCursorX;
    property CursorY: Integer read FCursorY write FCursorY;
    /// <summary>Where the next character would go, when the layout ends</summary>
    property EndX: Integer read FEndX write FEndX;
    property EndY: Integer read FEndY write FEndY;
  end;

implementation

const
  INITIAL_CAPACITY = 128;

{ THudLayout }

constructor THudLayout.Create;
begin
  inherited Create;
  SetLength(FGlyphs, INITIAL_CAPACITY);
end;

procedure THudLayout.Reset;
begin
  FCount := 0;
  FCursorFits := False;
  FCursorX := 0;
  FCursorY := 0;
  FEndX := 0;
  FEndY := 0;
end;

procedure THudLayout.Add(const AIndex, AX, AY: Integer; const AHighlighted: Boolean);
begin
  if FCount = Length(FGlyphs) then
    SetLength(FGlyphs, FCount * 2);
  FGlyphs[FCount].Index := AIndex;
  FGlyphs[FCount].X := AX;
  FGlyphs[FCount].Y := AY;
  FGlyphs[FCount].Highlighted := AHighlighted;
  Inc(FCount);
end;

end.
