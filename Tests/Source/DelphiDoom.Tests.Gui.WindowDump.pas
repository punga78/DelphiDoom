{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the dump of a window tree            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.WindowDump;

interface

uses
  System.Classes, DelphiDoom.Gui.Window;

/// <summary>
///   The state of a window and of its draw windows as text lines (the same format as the driver of the
///   C++ harness, Tools\Verifica\111): the floats are their 32 bits in hexadecimal. A simple window has
///   the lines of idSimpleWindow only.
/// </summary>
procedure DumpWindow(const AWindow: TGuiWindow; const ALines: TStrings);

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Gui.Window.Choice, DelphiDoom.Gui.Window.Slider;

function Bits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

function Vec4Bits(const AValue: TIdVec4): string;
begin
  Result := Bits(AValue.X) + ' ' + Bits(AValue.Y) + ' ' + Bits(AValue.Z) + ' ' + Bits(AValue.W);
end;

function RectBits(const AValue: TGuiRectangle): string;
begin
  Result := Bits(AValue.X) + ' ' + Bits(AValue.Y) + ' ' + Bits(AValue.W) + ' ' + Bits(AValue.H);
end;

function Flag(const AValue: Boolean): string;
begin
  if AValue then
    Result := '1'
  else
    Result := '0';
end;

procedure DumpSimple(const AWindow: TGuiWindow; const ALevel: Integer; const ALines: TStrings);
var
  LPad: string;
begin
  LPad := StringOfChar(' ', ALevel * 2);
  ALines.Add(Format('%sS %s flags=%s', [LPad, string(AWindow.Name), IntToHex(AWindow.Flags, 8)]));
  ALines.Add(Format('%s rect=%s back=%s fore=%s mat=%s border=%s', [LPad, RectBits(AWindow.Rect.Value),
    Vec4Bits(AWindow.BackColor.Value), Vec4Bits(AWindow.ForeColor.Value), Vec4Bits(AWindow.MatColor.Value),
    Vec4Bits(AWindow.BorderColor.Value)]));
  ALines.Add(Format('%s tscale=%s rot=%s vis=%s text="%s" bg="%s"', [LPad, Bits(AWindow.TextScale.Value),
    Bits(AWindow.Rotate.Value), Flag(AWindow.Visible.Value), string(AWindow.Text.AsText),
    string(AWindow.BackgroundName.AsText)]));
end;

procedure DumpOne(const AWindow: TGuiWindow; const ALevel: Integer; const ALines: TStrings);
var
  LPad: string;
  LMask: Integer;
  LEvent: TGuiScriptEvent;
  LIndex: Integer;
  LDraw: TGuiDrawWindow;
begin
  LPad := StringOfChar(' ', ALevel * 2);
  LMask := 0;
  for LEvent := Low(TGuiScriptEvent) to High(TGuiScriptEvent) do
    if Assigned(AWindow.Scripts[LEvent]) then
      LMask := LMask or (1 shl Ord(LEvent));
  ALines.Add(Format('%sW %s flags=%s simple=0 child=%d draw=%d scr=%s tl=%d named=%d tr=%d upd=%d cmd="%s"',
    [LPad, string(AWindow.Name), IntToHex(AWindow.Flags, 8), AWindow.ChildCount, AWindow.DrawWindowCount,
    IntToHex(LMask, 3), AWindow.TimeLineEventCount, AWindow.NamedEventCount, AWindow.TransitionCount,
    AWindow.UpdateVarCount, string(AWindow.Command)]));
  ALines.Add(Format('%s rect=%s back=%s fore=%s mat=%s border=%s hover=%s', [LPad, RectBits(AWindow.Rect.Value),
    Vec4Bits(AWindow.BackColor.Value), Vec4Bits(AWindow.ForeColor.Value), Vec4Bits(AWindow.MatColor.Value),
    Vec4Bits(AWindow.BorderColor.Value), Vec4Bits(AWindow.HoverColor.Value)]));
  ALines.Add(Format('%s tscale=%s rot=%s vis=%s noev=%s notime=%s text="%s" bg="%s"', [LPad,
    Bits(AWindow.TextScale.Value), Bits(AWindow.Rotate.Value), Flag(AWindow.Visible.Value),
    Flag(AWindow.NoEvents.Value), Flag(AWindow.NoTime.Value), string(AWindow.Text.AsText),
    string(AWindow.BackgroundName.AsText)]));
  for LIndex := 0 to AWindow.DefinedVarCount - 1 do
    ALines.Add(Format('%s var %s = %s', [LPad, string(AWindow.DefinedVars[LIndex].GetName),
      string(AWindow.DefinedVars[LIndex].AsText)]));
  if AWindow is TGuiChoiceWindow then
    ALines.Add(Format('%s X choice n=%d v=%d cur=%d', [LPad, TGuiChoiceWindow(AWindow).Choices.Count,
      TGuiChoiceWindow(AWindow).Values.Count, TGuiChoiceWindow(AWindow).CurrentChoice]));
  if AWindow is TGuiSliderWindow then
    ALines.Add(Format('%s X slider low=%s high=%s step=%s', [LPad, Bits(TGuiSliderWindow(AWindow).Low),
      Bits(TGuiSliderWindow(AWindow).High), Bits(TGuiSliderWindow(AWindow).StepSize)]));
  for LIndex := 0 to AWindow.DrawWindowCount - 1 do
  begin
    LDraw := AWindow.DrawWindows[LIndex];
    if LDraw.IsSimple then
      DumpSimple(LDraw.Window, ALevel + 1, ALines)
    else
      DumpOne(LDraw.Window, ALevel + 1, ALines);
  end;
end;

procedure DumpWindow(const AWindow: TGuiWindow; const ALines: TStrings);
begin
  DumpOne(AWindow, 0, ALines);
end;

end.
