{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the command that waits for a target               }
{                                                                              }
{  Port of war1 (acoto87/war1), WarMapCommandState of war_map.h and            }
{  consumeCommand of war_commands.c, (c) 2019 Alejandro Coto Gutierrez, zlib   }
{  License (see Games\War\LICENSE-war1.txt). This is an altered version, not   }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandState;

{$R-}
{$Q-}

interface

type
  /// <summary>
  ///   map->commandState: the command that the player chose with a button or a key and that waits for a click (or for the
  ///   next update), and the two flags that make the release of the button that gave an order not select and not move the
  ///   camera. One of these per map; the scene, the selection, the camera, the panel of the commands, the cursor and the
  ///   preview read it
  /// </summary>
  TWarMapCommandState = class
  strict private
    FCommandType: Integer;
    FSuppressSelectionOnRelease: Boolean;
    FSuppressMinimapViewportOnRelease: Boolean;
  public
    /// <summary>map->commandState.command.type != WAR_COMMAND_NONE</summary>
    function Pending: Boolean;
    /// <summary>consumeCommand: the command is done; a command that a click gave also stops the selection on release</summary>
    procedure Consume;
    /// <summary>map->commandState.command.type = WAR_COMMAND_NONE (the selection changed, or the player cancelled)</summary>
    procedure Clear;
    /// <summary>WarUnitCommand.type: WAR_COMMAND_NONE (0) when nothing waits</summary>
    property CommandType: Integer read FCommandType write FCommandType;
    property SuppressSelectionOnRelease: Boolean read FSuppressSelectionOnRelease write FSuppressSelectionOnRelease;
    property SuppressMinimapViewportOnRelease: Boolean read FSuppressMinimapViewportOnRelease
      write FSuppressMinimapViewportOnRelease;
  end;

implementation

uses
  DelphiDoom.War.Model.Commands.Types;

{ TWarMapCommandState }

function TWarMapCommandState.Pending: Boolean;
begin
  Result := FCommandType <> WAR_COMMAND_NONE;
end;

procedure TWarMapCommandState.Consume;
begin
  // only the commands that a left click on the map or the minimap executes stop the selection when the button goes up
  FSuppressSelectionOnRelease := (FCommandType = WAR_COMMAND_MOVE) or (FCommandType = WAR_COMMAND_HARVEST) or
    (FCommandType = WAR_COMMAND_REPAIR) or (FCommandType = WAR_COMMAND_ATTACK) or
    ((FCommandType >= WAR_COMMAND_SPELL_HEALING) and (FCommandType <= WAR_COMMAND_SPELL_UNHOLY_ARMOR)) or
    ((FCommandType >= WAR_COMMAND_BUILD_FIRST) and (FCommandType <= WAR_COMMAND_BUILD_WALL));
  FCommandType := WAR_COMMAND_NONE;
end;

procedure TWarMapCommandState.Clear;
begin
  FCommandType := WAR_COMMAND_NONE;
end;

end.
