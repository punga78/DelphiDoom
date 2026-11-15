{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the buttons of the menus                          }
{                                                                              }
{  Port of war1 (acoto87/war1), the arguments that war_scene_menu.c and         }
{  war_map_ui.c give to imui_text_button and imui_image_button for the menus,   }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                         }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Widgets;

interface

uses
  DelphiDoom.War.Text.Types, DelphiDoom.War.Ui.Types;

type
  /// <summary>
  ///   The arguments of the controls that the menus of the game share (the main menu of the scenes and the menus of the
  ///   map): a button with a text in font 1 and its first letter highlighted, an arrow button and a caption in font 1
  /// </summary>
  TWarUiWidgets = class sealed
  public
    /// <summary>A button of the menus: background 241 and 242 if small, 239 and 240 if not, the first letter highlighted</summary>
    class function MenuButton(const AText: AnsiString; AX, AY: Single; AHotKey: TWarKey;
      ASmall: Boolean): TWarUiTextButtonArgs; static;
    /// <summary>An arrow: 244 and 245 to the left, 246 and 247 to the right</summary>
    class function ArrowButton(AX, AY: Single; ARight: Boolean): TWarUiImageButtonArgs; static;
    /// <summary>A line of text of the menus: font 1, in a box of AWidth x 12</summary>
    class function Caption(const AText: AnsiString; AX, AY, AWidth: Single;
      AHorizontal: TWarTextAlignment): TWarUiTextArgs; static;
  end;

implementation

{ TWarUiWidgets }

class function TWarUiWidgets.MenuButton(const AText: AnsiString; AX, AY: Single; AHotKey: TWarKey;
  ASmall: Boolean): TWarUiTextButtonArgs;
begin
  Result := TWarUiTextButtonArgs.Default;
  Result.FontIndex := 1;
  Result.Text := AText;
  if ASmall then
  begin
    Result.BackgroundNormal := 241;
    Result.BackgroundPressed := 242;
  end
  else
  begin
    Result.BackgroundNormal := 239;
    Result.BackgroundPressed := 240;
  end;
  Result.PositionX := AX;
  Result.PositionY := AY;
  Result.HotKey := AHotKey;
  Result.HighlightIndex := 0;
  Result.HighlightCount := 1;
end;

class function TWarUiWidgets.ArrowButton(AX, AY: Single; ARight: Boolean): TWarUiImageButtonArgs;
begin
  Result := TWarUiImageButtonArgs.Default;
  if ARight then
  begin
    Result.BackgroundNormal := 246;
    Result.BackgroundPressed := 247;
  end
  else
  begin
    Result.BackgroundNormal := 244;
    Result.BackgroundPressed := 245;
  end;
  Result.PositionX := AX;
  Result.PositionY := AY;
end;

class function TWarUiWidgets.Caption(const AText: AnsiString; AX, AY, AWidth: Single;
  AHorizontal: TWarTextAlignment): TWarUiTextArgs;
begin
  Result := TWarUiTextArgs.Default;
  Result.PositionX := AX;
  Result.PositionY := AY;
  Result.FontIndex := 1;
  Result.BoundingsX := AWidth;
  Result.BoundingsY := 12;
  Result.HorizontalAlign := AHorizontal;
  Result.VerticalAlign := wtaMiddle;
  Result.Text := AText;
end;

end.
