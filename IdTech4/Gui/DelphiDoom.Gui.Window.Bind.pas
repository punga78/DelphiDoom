{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiBindWindow (bindDef)                          }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\BindWindow.h,           }
{  BindWindow.cpp (idBindWindow: the parse). Copyright (C) 1999-2011 id        }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Bind;

interface

uses
  DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.WinVar.Base,
  DelphiDoom.Gui.WinVar.Str, DelphiDoom.Gui.Window.Keys;

type
  /// <summary>
  ///   idBindWindow: the variable <c>bind</c> (the name of the binding), bound to the state of the gui
  ///   after the parse. Not ported: waiting for a key and the key bindings.
  /// </summary>
  TGuiBindWindow = class(TGuiWindow)
  strict private
    FBindName: TGuiWinStr;
    FWaitingOnKey: Boolean;
  protected
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    /// <summary>idBindWindow::HandleEvent: the left mouse button waits for a key; the key (or escape) gives the command</summary>
    function HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString; override;
    procedure Draw(const ATime: Integer; const AX, AY: Single); override;
    procedure Activate(const AActivate: Boolean; var AAct: AnsiString); override;
    property BindName: TGuiWinStr read FBindName;
    property WaitingOnKey: Boolean read FWaitingOnKey;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Gui.DrawContext;

constructor TGuiBindWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FBindName := TGuiWinStr.Create;
end;

destructor TGuiBindWindow.Destroy;
begin
  FBindName.Free;
  inherited Destroy;
end;

function TGuiBindWindow.GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
  out AOwner: IGuiWindowNode): TGuiWinVar;
begin
  AOwner := nil;
  if TIdStrings.Icmp(AName, 'bind') = 0 then
    Exit(FBindName);
  Result := inherited GetWinVarByName(AName, AFixup, AOwner);
end;

procedure TGuiBindWindow.PostParse;
begin
  inherited PostParse;
  FBindName.SetGuiInfo(Context.StateDict, FBindName.AsText);
  FBindName.Update;
  SetFlag(WIN_HOLDCAPTURE or WIN_CANFOCUS);
end;

function TGuiBindWindow.HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString;
begin
  Result := '';
  if not ((AEvent.EventType = GUI_SE_KEY) and (AEvent.Value2 <> 0)) then
    Exit;
  if FWaitingOnKey then
  begin
    FWaitingOnKey := False;
    // the original keeps the command in a buffer of 256 characters
    if AEvent.Value = GUI_K_ESCAPE then
      Result := Copy(AnsiString(Format('clearbind "%s"', [string(FBindName.GetName)])), 1, 255)
    else
      Result := Copy(AnsiString(Format('bind %d "%s"', [AEvent.Value, string(FBindName.GetName)])), 1, 255);
  end
  else if AEvent.Value = GUI_K_MOUSE1 then
  begin
    FWaitingOnKey := True;
    Context.BindHandler := Self;
  end;
end;

procedure TGuiBindWindow.Draw(const ATime: Integer; const AX, AY: Single);
var
  LColor: TIdVec4;
  LText: AnsiString;
  LDc: TGuiDrawContext;
begin
  LColor := ForeColor.Value;
  LDc := Context.DrawContext;
  if FWaitingOnKey then
    LText := TranslateString('#str_07000')
  else if FBindName.Length > 0 then
    LText := FBindName.AsText
  else
    LText := TranslateString('#str_07001');
  if FWaitingOnKey or (Hover and (not NoEvents.Value) and ContainsPoint(Context.CursorX, Context.CursorY)) then
    LColor := HoverColor.Value
  else
    Hover := False;
  LDc.DrawText(LText, TextScale.Value, TextAlign, LColor, TextRect, False, -1);
end;

procedure TGuiBindWindow.Activate(const AActivate: Boolean; var AAct: AnsiString);
begin
  inherited Activate(AActivate, AAct);
  FBindName.Update;
end;

end.