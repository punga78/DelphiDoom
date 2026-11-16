{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiFieldWindow (fieldDef)                        }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\FieldWindow.h,          }
{  FieldWindow.cpp (idFieldWindow: the parse). Copyright (C) 1999-2011 id      }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Field;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Window;

type
  /// <summary>idFieldWindow: the keys <c>cursorvar</c> and <c>showcursor</c>. Not ported: the cursor and the drawing.</summary>
  TGuiFieldWindow = class(TGuiWindow)
  strict private
    FCursorVar: AnsiString;
    FShowCursor: Boolean;
    FCursorPos: Integer;
    FLastTextLength: Integer;
    FLastCursorPos: Integer;
    FPaintOffset: Integer;
    procedure CalcPaintOffset(const ALength: Integer);
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
  public
    /// <summary>idFieldWindow::Draw: the text from the paint offset with the cursor of the variable of the state</summary>
    procedure Draw(const ATime: Integer; const AX, AY: Single); override;
    property PaintOffset: Integer read FPaintOffset;
    property CursorVar: AnsiString read FCursorVar;
    property ShowCursor: Boolean read FShowCursor;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.DrawContext;

function TGuiFieldWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'cursorvar') = 0 then
    ParseString(ASource, FCursorVar)
  else if TIdStrings.Icmp(AName, 'showcursor') = 0 then
    FShowCursor := ASource.ParseBool
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

procedure TGuiFieldWindow.CalcPaintOffset(const ALength: Integer);
var
  LLength, LWidth: Integer;
  LDc: TGuiDrawContext;
begin
  LDc := Context.DrawContext;
  LLength := ALength;
  FLastCursorPos := FCursorPos;
  FLastTextLength := LLength;
  FPaintOffset := 0;
  LWidth := LDc.TextWidth(Text.AsText, TextScale.Value, -1);
  if LWidth < TextRect.W then
    Exit;
  while (LWidth > TextRect.W) and (LLength > 0) do
  begin
    Dec(LLength);
    LWidth := LDc.TextWidth(Text.AsText, TextScale.Value, LLength);
    Inc(FPaintOffset);
  end;
end;

procedure TGuiFieldWindow.Draw(const ATime: Integer; const AX, AY: Single);
var
  LLength, LCursor: Integer;
  LDc: TGuiDrawContext;
  LText: AnsiString;
begin
  LDc := Context.DrawContext;
  LLength := Text.Length;
  FCursorPos := Context.StateDict.GetInt(FCursorVar);
  if (LLength <> FLastTextLength) or (FCursorPos <> FLastCursorPos) then
    CalcPaintOffset(LLength);
  if FPaintOffset >= LLength then
    FPaintOffset := 0;
  if FCursorPos > LLength then
    FCursorPos := LLength;
  LText := Copy(Text.AsText, FPaintOffset + 1, MaxInt);
  if ((Flags and WIN_FOCUS) <> 0) or FShowCursor then
    LCursor := FCursorPos - FPaintOffset
  else
    LCursor := -1;
  LDc.DrawText(LText, TextScale.Value, 0, ForeColor.Value, TextRect, False, LCursor);
end;

end.