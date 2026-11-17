{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the cvars the game reads (fixed values)   }
{                                                                              }
{  Written for this repository (the original reads g_skill and the others      }
{  from the cvar system).                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.Settings;

interface

uses
  DelphiDoom.D3Game.Intf;

type
  /// <summary>
  ///   <c>ID3GameSettings</c> with the values given at creation: the skill (0 easy .. 3 nightmare), multiplayer and
  ///   <c>g_cinematic</c>. A program that has a cvar system gives its own adapter.
  /// </summary>
  TD3GameSettings = class(TInterfacedObject, ID3GameSettings)
  strict private
    FSkill: Integer;
    FIsMultiplayer: Boolean;
    FCinematicEnabled: Boolean;
  public
    constructor Create(const ASkill: Integer = 1; const AIsMultiplayer: Boolean = False;
      const ACinematicEnabled: Boolean = True);
    function GetSkill: Integer;
    function GetIsMultiplayer: Boolean;
    function GetCinematicEnabled: Boolean;
  end;

implementation

constructor TD3GameSettings.Create(const ASkill: Integer; const AIsMultiplayer: Boolean;
  const ACinematicEnabled: Boolean);
begin
  inherited Create;
  FSkill := ASkill;
  FIsMultiplayer := AIsMultiplayer;
  FCinematicEnabled := ACinematicEnabled;
end;

function TD3GameSettings.GetSkill: Integer;
begin
  Result := FSkill;
end;

function TD3GameSettings.GetIsMultiplayer: Boolean;
begin
  Result := FIsMultiplayer;
end;

function TD3GameSettings.GetCinematicEnabled: Boolean;
begin
  Result := FCinematicEnabled;
end;

end.
