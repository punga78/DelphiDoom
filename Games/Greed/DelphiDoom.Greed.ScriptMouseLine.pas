{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a line of a script that moves the mouse          }
{  The lines "mouse", "mousebutton" and "click" of the scripts of keys          }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ScriptMouseLine;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Mouse.Intf;

type
  TGreedScriptMouseKind = (smkMove, smkButton, smkClick);

  /// <summary>
  ///   What a script asks of the mouse at a tic. The words of the line after the tic are
  ///     mouse DX DY                       the cursor moves DX pixels to the right and DY down
  ///     mousebutton fire|use|north down|up   the left, right or middle button goes down or up
  ///     click X Y                         a click of the left button at the pixel X, Y of the menus (320 x 200)
  /// </summary>
  TGreedScriptMouseLine = record
    Kind: TGreedScriptMouseKind;
    /// <summary>smkMove: the distance; smkClick: the pixel</summary>
    X: Integer;
    Y: Integer;
    /// <summary>smkButton</summary>
    Button: TGreedMouseButton;
    Down: Boolean;
    /// <summary>The word after the tic is one of the three of the mouse</summary>
    class function IsMouseWord(const AWord: string): Boolean; static;
    /// <summary>A line of the script is for the mouse (well written or not); False for a nil script</summary>
    class function AnyIn(AScript: TStrings): Boolean; static;
    /// <summary>
    ///   AWords are the words of the line, the tic first. False if the line is not written as one of the three
    ///   forms above
    /// </summary>
    class function TryParse(const AWords: TArray<string>; out ALine: TGreedScriptMouseLine): Boolean; static;
    /// <summary>EArgumentNilException if AMouse is nil</summary>
    procedure ApplyTo(const AMouse: IGreedScriptMouse);
  end;

implementation

const
  WORD_MOUSE = 'mouse';
  WORD_BUTTON = 'mousebutton';
  WORD_CLICK = 'click';
  WORD_DOWN = 'down';
  WORD_UP = 'up';
  BUTTON_NAMES: array[TGreedMouseButton] of string = ('fire', 'use', 'north');

{ TGreedScriptMouseLine }

class function TGreedScriptMouseLine.IsMouseWord(const AWord: string): Boolean;
begin
  Result := SameText(AWord, WORD_MOUSE) or SameText(AWord, WORD_BUTTON) or SameText(AWord, WORD_CLICK);
end;

class function TGreedScriptMouseLine.AnyIn(AScript: TStrings): Boolean;
var
  LIndex: Integer;
  LWords: TArray<string>;
begin
  Result := False;
  if not Assigned(AScript) then
    Exit;
  for LIndex := 0 to AScript.Count - 1 do
  begin
    LWords := Trim(AScript[LIndex]).Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
    if (Length(LWords) >= 2) and (LWords[0][1] <> '#') and IsMouseWord(LWords[1]) then
      Exit(True);
  end;
end;

class function TGreedScriptMouseLine.TryParse(const AWords: TArray<string>;
  out ALine: TGreedScriptMouseLine): Boolean;
var
  LButton: TGreedMouseButton;
begin
  ALine := Default(TGreedScriptMouseLine);
  if Length(AWords) <> 4 then
    Exit(False);
  if SameText(AWords[1], WORD_MOUSE) or SameText(AWords[1], WORD_CLICK) then
  begin
    if SameText(AWords[1], WORD_MOUSE) then
      ALine.Kind := smkMove
    else
      ALine.Kind := smkClick;
    Exit(TryStrToInt(AWords[2], ALine.X) and TryStrToInt(AWords[3], ALine.Y));
  end;
  if not SameText(AWords[1], WORD_BUTTON) then
    Exit(False);
  ALine.Kind := smkButton;
  if SameText(AWords[3], WORD_DOWN) then
    ALine.Down := True
  else if not SameText(AWords[3], WORD_UP) then
    Exit(False);
  for LButton := Low(TGreedMouseButton) to High(TGreedMouseButton) do
    if SameText(AWords[2], BUTTON_NAMES[LButton]) then
    begin
      ALine.Button := LButton;
      Exit(True);
    end;
  Result := False;
end;

procedure TGreedScriptMouseLine.ApplyTo(const AMouse: IGreedScriptMouse);
begin
  if not Assigned(AMouse) then
    raise EArgumentNilException.Create('AMouse');
  case Kind of
    smkMove:
      AMouse.Move(X, Y);
    smkButton:
      AMouse.SetButton(Button, Down);
    smkClick:
      AMouse.Click(X, Y);
  end;
end;

end.
