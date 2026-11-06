{******************************************************************************}
{                                                                              }
{  DelphiDoom: specials library - the factory                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Specials.Factory;

interface

uses
  DelphiDoom.Specials.Intf;

type
  /// <summary>The only place that knows the class behind ISpecialRegistry</summary>
  TSpecialsFactory = class
  public
    class function CreateRegistry: ISpecialRegistry; static;
  end;

implementation

uses
  DelphiDoom.Specials.Registry;

{ TSpecialsFactory }

class function TSpecialsFactory.CreateRegistry: ISpecialRegistry;
begin
  Result := TSpecialRegistry.Create;
end;

end.
