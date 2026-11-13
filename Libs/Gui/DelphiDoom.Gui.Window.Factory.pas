{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWindowFactory                                 }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): the keywords of            }
{  idWindow::Parse (editDef, choiceDef, sliderDef, markerDef, bindDef, listDef,}
{  fieldDef, renderDef). Copyright (C) 1999-2011 id Software LLC, a ZeniMax    }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Factory;

interface

uses
  DelphiDoom.Gui.Context, DelphiDoom.Gui.Window;

type
  /// <summary>
  ///   Makes the window of a keyword. The game windows of the original (<c>gameSSDDef</c>,
  ///   <c>gameBearShootDef</c>, <c>gameBustOutDef</c>) are not ported: they are no keyword here and the parse
  ///   treats them as any unknown key. It must be attached to the context of the gui before it is used.
  /// </summary>
  TGuiWindowFactory = class
  strict private
    FContext: TGuiContext;
    function CreateWindow(const AKeyword: AnsiString): TGuiWindow;
  public
    procedure Attach(const AContext: TGuiContext);
    /// <summary>The creator that the windows call for the keyword of a child</summary>
    function GetCreator: TGuiWindowCreator;
  end;

implementation

uses
  DelphiDoom.Gui.Window.Edit, DelphiDoom.Gui.Window.Choice, DelphiDoom.Gui.Window.Slider,
  DelphiDoom.Gui.Window.Marker, DelphiDoom.Gui.Window.Bind, DelphiDoom.Gui.Window.List,
  DelphiDoom.Gui.Window.Field, DelphiDoom.Gui.Window.Render;

procedure TGuiWindowFactory.Attach(const AContext: TGuiContext);
begin
  FContext := AContext;
end;

function TGuiWindowFactory.GetCreator: TGuiWindowCreator;
begin
  Result := function(const AKeyword: AnsiString): TGuiWindow
    begin
      Result := CreateWindow(AKeyword);
    end;
end;

function TGuiWindowFactory.CreateWindow(const AKeyword: AnsiString): TGuiWindow;
var
  LCreator: TGuiWindowCreator;
begin
  Result := nil;
  LCreator := GetCreator();
  if AKeyword = 'editDef' then
    Result := TGuiEditWindow.Create(FContext, LCreator)
  else if AKeyword = 'choiceDef' then
    Result := TGuiChoiceWindow.Create(FContext, LCreator)
  else if AKeyword = 'sliderDef' then
    Result := TGuiSliderWindow.Create(FContext, LCreator)
  else if AKeyword = 'markerDef' then
    Result := TGuiMarkerWindow.Create(FContext, LCreator)
  else if AKeyword = 'bindDef' then
    Result := TGuiBindWindow.Create(FContext, LCreator)
  else if AKeyword = 'listDef' then
    Result := TGuiListWindow.Create(FContext, LCreator)
  else if AKeyword = 'fieldDef' then
    Result := TGuiFieldWindow.Create(FContext, LCreator)
  else if AKeyword = 'renderDef' then
    Result := TGuiRenderWindow.Create(FContext, LCreator);
end;

end.
