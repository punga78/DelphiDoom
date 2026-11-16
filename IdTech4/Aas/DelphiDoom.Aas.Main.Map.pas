{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the map that is loaded                            }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Main.Map;

interface

uses
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Links, DelphiDoom.Aas.Main.Intf;

type
  /// <summary>A file with its entity links and the steps that initialize it; the links are owned</summary>
  TAasMap = class(TInterfacedObject, IAasMap)
  strict private
    FFile: IAasFile;
    FLinks: TAasEntityLinks;
    FSteps: IAasInitSteps;
  public
    constructor Create(const AFile: IAasFile; const ALinks: TAasEntityLinks; const ASteps: IAasInitSteps);
    destructor Destroy; override;
    function GetFile: IAasFile;
    function GetLinks: TAasEntityLinks;
    function GetSteps: IAasInitSteps;
  end;

implementation

constructor TAasMap.Create(const AFile: IAasFile; const ALinks: TAasEntityLinks; const ASteps: IAasInitSteps);
begin
  inherited Create;
  FFile := AFile;
  FLinks := ALinks;
  FSteps := ASteps;
end;

destructor TAasMap.Destroy;
begin
  // the steps may hold the links: they go first
  FSteps := nil;
  FLinks.Free;
  inherited Destroy;
end;

function TAasMap.GetFile: IAasFile;
begin
  Result := FFile;
end;

function TAasMap.GetLinks: TAasEntityLinks;
begin
  Result := FLinks;
end;

function TAasMap.GetSteps: IAasInitSteps;
begin
  Result := FSteps;
end;

end.