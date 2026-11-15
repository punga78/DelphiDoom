{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the cursor of a command that waits                }
{                                                                              }
{  Port of war1 (acoto87/war1), the part of updateMapCursor of war_map.c that  }
{  looks at the command that waits for a target, (c) 2019 Alejandro Coto       }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandCursor;

{$R-}
{$Q-}

interface

type
  /// <summary>
  ///   Which cursor the mouse has over the map or the minimap while a command waits for its target. A red cross for what
  ///   attacks, a yellow one for what moves, orders or helps, the arrow while a building is placed. Over the map a
  ///   command that is not one of these (or none) leaves the choice to what is under the mouse
  /// </summary>
  TWarCommandCursor = class sealed
  public
    /// <summary>
    ///   The cursor of the command over the map panel: a WAR_CURSOR_* record, or -1 if the cursor depends on what is under
    ///   the mouse (the default case of the original)
    /// </summary>
    class function OverMap(ACommandType: Integer): Integer; static;
    /// <summary>The cursor of the command over the minimap: always one (the arrow for what does not use the minimap)</summary>
    class function OverMinimap(ACommandType: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.MapUi.Types;

{ TWarCommandCursor }

class function TWarCommandCursor.OverMap(ACommandType: Integer): Integer;
begin
  case ACommandType of
    WAR_COMMAND_ATTACK, WAR_COMMAND_SPELL_RAIN_OF_FIRE, WAR_COMMAND_SPELL_POISON_CLOUD:
      Result := WAR_CURSOR_RED_CROSSHAIR;
    WAR_COMMAND_MOVE, WAR_COMMAND_STOP, WAR_COMMAND_HARVEST, WAR_COMMAND_DELIVER, WAR_COMMAND_REPAIR,
    WAR_COMMAND_SPELL_HEALING, WAR_COMMAND_SPELL_FAR_SIGHT, WAR_COMMAND_SPELL_INVISIBILITY,
    WAR_COMMAND_SPELL_RAISE_DEAD, WAR_COMMAND_SPELL_DARK_VISION, WAR_COMMAND_SPELL_UNHOLY_ARMOR:
      Result := WAR_CURSOR_YELLOW_CROSSHAIR;
    WAR_COMMAND_BUILD_FIRST .. WAR_COMMAND_BUILD_WALL:
      Result := WAR_CURSOR_ARROW;
  else
    Result := -1;
  end;
end;

class function TWarCommandCursor.OverMinimap(ACommandType: Integer): Integer;
begin
  case ACommandType of
    WAR_COMMAND_ATTACK, WAR_COMMAND_SPELL_RAIN_OF_FIRE, WAR_COMMAND_SPELL_POISON_CLOUD:
      Result := WAR_CURSOR_RED_CROSSHAIR;
    WAR_COMMAND_MOVE, WAR_COMMAND_SPELL_FAR_SIGHT, WAR_COMMAND_SPELL_DARK_VISION:
      Result := WAR_CURSOR_YELLOW_CROSSHAIR;
  else
    Result := WAR_CURSOR_ARROW;
  end;
end;

end.
