{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the MUSINFO library asks of the game              }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.MusInfo.Services;

interface

uses
  DelphiDoom.MusInfo.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>
  ///   The number of a song by its name and the text of the MUSINFO lump, as the game has them.
  ///   The text is the raw one, without the script preprocessor (as it has always been)
  /// </summary>
  TEngineMusInfoServices = class(TInterfacedObject, IMusInfoMusicResolver, IMusInfoTextSource)
  strict private
    FLumps: IEngineLumps;
  public
    constructor Create(const ALumps: IEngineLumps);
    function MusicNumberFor(const AUpperName: string): Integer;
    function TryGetText(const AUpperName: string; out AText: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  sounds;

{ TEngineMusInfoServices }

constructor TEngineMusInfoServices.Create(const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
end;

function TEngineMusInfoServices.MusicNumberFor(const AUpperName: string): Integer;
begin
  Result := S_GetMusicNumForName(AUpperName);
end;

function TEngineMusInfoServices.TryGetText(const AUpperName: string; out AText: string): Boolean;
var
  LLump: Integer;
begin
  LLump := FLumps.CheckNumForName(AUpperName);
  Result := LLump >= 0;
  if Result then
    AText := FLumps.TextOf(LLump)
  else
    AText := '';
end;

end.
