{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the numbers of the sounds for the text maps             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Udmf.SoundResolver;

interface

uses
  DelphiDoom.Udmf.Intf;

type
  /// <summary>The sound of a sector, by name, is the number that the sound table of the game gives it</summary>
  TEngineUdmfSoundResolver = class(TInterfacedObject, IUdmfSoundResolver)
  public
    function NumberOf(const AName: string): Integer;
  end;

implementation

uses
  sounds;

{ TEngineUdmfSoundResolver }

function TEngineUdmfSoundResolver.NumberOf(const AName: string): Integer;
begin
  Result := S_GetSoundNumForName(AName);
end;

end.