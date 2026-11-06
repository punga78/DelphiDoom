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
  DelphiDoom.MusInfo.Intf;

type
  /// <summary>
  ///   The number of a song by its name and the text of the MUSINFO lump, as the game has them.
  ///   The text is the raw one, without the script preprocessor (as it has always been)
  /// </summary>
  TEngineMusInfoServices = class(TInterfacedObject, IMusInfoMusicResolver, IMusInfoTextSource)
  public
    function MusicNumberFor(const AUpperName: string): Integer;
    function TryGetText(const AUpperName: string; out AText: string): Boolean;
  end;

implementation

uses
  sounds,
  w_wad;

{ TEngineMusInfoServices }

function TEngineMusInfoServices.MusicNumberFor(const AUpperName: string): Integer;
begin
  Result := S_GetMusicNumForName(AUpperName);
end;

function TEngineMusInfoServices.TryGetText(const AUpperName: string; out AText: string): Boolean;
var
  LLump: Integer;
begin
  LLump := W_CheckNumForName(AUpperName);
  Result := LLump >= 0;
  if Result then
    AText := W_TextLumpNum(LLump)
  else
    AText := '';
end;

end.
