{******************************************************************************}
{                                                                              }
{  DelphiDoom: id Tech library - an id Tech engine and its version             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdTech.Engine;

interface

uses
  System.SysUtils, DelphiDoom.IdTech.Types, DelphiDoom.IdTech.Intf;

type
  /// <summary>An id Tech engine: a generation, the source port that runs it and its version</summary>
  TIdTechEngine = class(TInterfacedObject, IIdTechEngine)
  private
    FGeneration: TIdTechGeneration;
    FSourcePort: string;
    FVersion: TIdTechVersion;
  public
    /// <summary>Raises EIdTechException when ASourcePort is empty</summary>
    constructor Create(AGeneration: TIdTechGeneration; const ASourcePort: string;
      const AVersion: TIdTechVersion);
    function GetGeneration: TIdTechGeneration;
    function GetSourcePort: string;
    function GetVersion: TIdTechVersion;
    function GetName: string;
    function GetDisplayName: string;
  end;

implementation

const
  SNoSourcePort = 'The source port needs a name';

{ TIdTechEngine }

constructor TIdTechEngine.Create(AGeneration: TIdTechGeneration; const ASourcePort: string;
  const AVersion: TIdTechVersion);
begin
  inherited Create;
  if Trim(ASourcePort) = '' then
    raise EIdTechException.Create(SNoSourcePort);
  FGeneration := AGeneration;
  FSourcePort := Trim(ASourcePort);
  FVersion := AVersion;
end;

function TIdTechEngine.GetGeneration: TIdTechGeneration;
begin
  Result := FGeneration;
end;

function TIdTechEngine.GetSourcePort: string;
begin
  Result := FSourcePort;
end;

function TIdTechEngine.GetVersion: TIdTechVersion;
begin
  Result := FVersion;
end;

function TIdTechEngine.GetName: string;
begin
  Result := FGeneration.Name;
end;

function TIdTechEngine.GetDisplayName: string;
begin
  Result := Format('%s %s (%s)', [FSourcePort, FVersion.ToString, FGeneration.Name]);
end;

end.
