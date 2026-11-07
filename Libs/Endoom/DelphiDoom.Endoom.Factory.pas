{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the factory: the composition root               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.Factory;

interface

uses
  DelphiDoom.Endoom.Intf;

type
  /// <summary>The only place that knows the class behind IEndoomRenderer</summary>
  TEndoomFactory = class
  public
    class function CreateRenderer: IEndoomRenderer; static;
  end;

implementation

uses
  DelphiDoom.Endoom.Renderer;

{ TEndoomFactory }

class function TEndoomFactory.CreateRenderer: IEndoomRenderer;
begin
  Result := TEndoomRenderer.Create;
end;

end.
