{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the entities of a map file                }
{                                                                              }
{  Written for this repository (the original reads idMapFile directly).        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.MapFileSource;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Map, DelphiDoom.D3Game.Intf;

type
  /// <summary>
  ///   <c>ID3MapSource</c> over a parsed map file: entity 0 is the world, each entity has its pairs. The map file is
  ///   not owned: the caller keeps it alive while the game spawns from it.
  /// </summary>
  TD3MapFileSource = class(TInterfacedObject, ID3MapSource)
  strict private
    FMap: TMapFile;
  public
    constructor Create(const AMap: TMapFile);
    function GetNumEntities: Integer;
    function GetEntityEpairs(const AIndex: Integer): TIdDict;
  end;

implementation

constructor TD3MapFileSource.Create(const AMap: TMapFile);
begin
  inherited Create;
  FMap := AMap;
end;

function TD3MapFileSource.GetNumEntities: Integer;
begin
  Result := FMap.GetNumEntities;
end;

function TD3MapFileSource.GetEntityEpairs(const AIndex: Integer): TIdDict;
begin
  Result := FMap.GetEntity(AIndex).Epairs;
end;

end.
