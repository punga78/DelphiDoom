{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the opened data of the game                       }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.GameData;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf;

type
  /// <summary>Graphics, maps and audio of the game, each with its own header and dictionary</summary>
  TKeenGameData = class(TInterfacedObject, IKeenGameData)
  strict private
    FGraphics: IKeenGraphics;
    FMaps: IKeenMapSource;
    FAudio: IKeenChunkSource;
  public
    constructor Create(const AGraphics: IKeenGraphics; const AMaps: IKeenMapSource;
      const AAudio: IKeenChunkSource);
    function GetGraphics: IKeenGraphics;
    function GetMaps: IKeenMapSource;
    function GetAudio: IKeenChunkSource;
  end;

implementation

{ TKeenGameData }

constructor TKeenGameData.Create(const AGraphics: IKeenGraphics; const AMaps: IKeenMapSource;
  const AAudio: IKeenChunkSource);
begin
  inherited Create;
  if not Assigned(AGraphics) then
    raise EArgumentNilException.Create('AGraphics');
  if not Assigned(AMaps) then
    raise EArgumentNilException.Create('AMaps');
  if not Assigned(AAudio) then
    raise EArgumentNilException.Create('AAudio');
  FGraphics := AGraphics;
  FMaps := AMaps;
  FAudio := AAudio;
end;

function TKeenGameData.GetGraphics: IKeenGraphics;
begin
  Result := FGraphics;
end;

function TKeenGameData.GetMaps: IKeenMapSource;
begin
  Result := FMaps;
end;

function TKeenGameData.GetAudio: IKeenChunkSource;
begin
  Result := FAudio;
end;

end.
