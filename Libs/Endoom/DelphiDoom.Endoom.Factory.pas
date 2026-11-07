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
    /// <param name="ATicRate">The tics in a second</param>
    class function CreateSession(ATicRate: Integer): IEndoomSession; static;
  end;

implementation

uses
  DelphiDoom.Endoom.Renderer, DelphiDoom.Endoom.Session;

{ TEndoomFactory }

class function TEndoomFactory.CreateRenderer: IEndoomRenderer;
begin
  Result := TEndoomRenderer.Create;
end;

class function TEndoomFactory.CreateSession(ATicRate: Integer): IEndoomSession;
begin
  Result := TEndoomSession.Create(ATicRate);
end;

end.
