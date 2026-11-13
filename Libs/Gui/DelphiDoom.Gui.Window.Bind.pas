{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiBindWindow (bindDef)                          }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\BindWindow.h,           }
{  BindWindow.cpp (idBindWindow: the parse). Copyright (C) 1999-2011 id        }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Bind;

interface

uses
  DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.WinVar.Base,
  DelphiDoom.Gui.WinVar.Str;

type
  /// <summary>
  ///   idBindWindow: the variable <c>bind</c> (the name of the binding), bound to the state of the gui
  ///   after the parse. Not ported: waiting for a key and the key bindings.
  /// </summary>
  TGuiBindWindow = class(TGuiWindow)
  strict private
    FBindName: TGuiWinStr;
  protected
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    property BindName: TGuiWinStr read FBindName;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Window.Types;

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

end.
