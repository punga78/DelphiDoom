{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the factory: the composition root            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Factory;

interface

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the lights</summary>
  TLightFactory = class
  public
    /// <summary>The fire flicker of a game: Strife has its own, the others the one of id Software</summary>
    class function CreateFlickerRules(AGame: TLightGame): ILightFlickerRules; static;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.FlickerRules.Standard, DelphiDoom.Thinkers.Light.FlickerRules.Strife;

{ TLightFactory }

class function TLightFactory.CreateFlickerRules(AGame: TLightGame): ILightFlickerRules;
begin
  if AGame = TLightGame.Strife then
    Result := TLightStrifeFlickerRules.Create
  else
    Result := TLightStandardFlickerRules.Create;
end;

end.
