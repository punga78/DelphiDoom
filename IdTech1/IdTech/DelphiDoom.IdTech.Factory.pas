{******************************************************************************}
{                                                                              }
{  DelphiDoom: id Tech library - the factory: the composition root             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdTech.Factory;

interface

uses
  System.SysUtils, DelphiDoom.IdTech.Types, DelphiDoom.IdTech.Intf;

type
  /// <summary>The only place that knows the class behind IIdTechEngine</summary>
  TIdTechFactory = class
  public
    class function CreateEngine(AGeneration: TIdTechGeneration; const ASourcePort: string;
      const AVersion: TIdTechVersion): IIdTechEngine; static;
    /// <summary>
    ///   DelphiDoom is a port of the Doom engine, id Tech 1; AVersionNumber is the number the
    ///   engine writes (207 for 2.07)
    /// </summary>
    class function CreateDelphiDoom(AVersionNumber: Integer): IIdTechEngine; static;
  end;

implementation

uses
  DelphiDoom.IdTech.Engine;

const
  DELPHIDOOM_NAME = 'DelphiDoom';

{ TIdTechFactory }

class function TIdTechFactory.CreateEngine(AGeneration: TIdTechGeneration;
  const ASourcePort: string; const AVersion: TIdTechVersion): IIdTechEngine;
begin
  Result := TIdTechEngine.Create(AGeneration, ASourcePort, AVersion);
end;

class function TIdTechFactory.CreateDelphiDoom(AVersionNumber: Integer): IIdTechEngine;
begin
  Result := CreateEngine(TIdTechGeneration.IdTech1, DELPHIDOOM_NAME,
    TIdTechVersion.FromNumber(AVersionNumber));
end;

end.
