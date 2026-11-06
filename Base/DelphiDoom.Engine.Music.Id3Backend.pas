{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - music backend of the files with an ID3 tag (ignored)    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.Id3Backend;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Engine.Music.BackendBase;

type
  /// <summary>
  ///   A song that starts with an ID3 tag is not played: it is recognized so that no other
  ///   backend tries it (as the old code did)
  /// </summary>
  TId3MusicBackend = class(TEngineMusicBackendBase)
  public
    function Register(AData: Pointer; ASize: Integer;
      out AContext: NativeInt): TMusicRegisterResult; override;
  end;

implementation

uses
  d_delphi,
  i_music;

{ TId3MusicBackend }

function TId3MusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
begin
  AContext := 0;
  if (ASize >= SizeOf(LongWord)) and (PLongWordArray(AData)[0] = ID3MAGIC) then
    Result := TMusicRegisterResult.Registered
  else
    Result := TMusicRegisterResult.NotRecognized;
end;

end.
