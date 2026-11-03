{******************************************************************************}
{                                                                              }
{  DelphiDoom: libsndfile - implementation of ISndfile on top of the C code    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sndfile.Engine;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   Stateless factory of sounds: every sound has its own SNDFILE, so one
  ///   instance can be used by several threads as long as each opens its own
  ///   sounds one at a time (the error of a failed open is a global of the C code)
  /// </summary>
  TSndfileEngine = class(TInterfacedObject, ISndfile)
  public
    function GetVersion: PAnsiChar; stdcall;
    function OpenMemory(ASource: Pointer; ASourceSize: Cardinal;
      out ASoundFile: ISoundFile): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Sndfile.Native, DelphiDoom.Sndfile.SoundFile;

{ TSndfileEngine }

function TSndfileEngine.GetVersion: PAnsiChar;
begin
  Result := _sf_version_string;
end;

function TSndfileEngine.OpenMemory(ASource: Pointer; ASourceSize: Cardinal;
  out ASoundFile: ISoundFile): Integer;
var
  LSoundFile: TSndfileSoundFile;
begin
  ASoundFile := nil;
  LSoundFile := TSndfileSoundFile.Create;
  try
    Result := LSoundFile.Open(ASource, ASourceSize);
  except
    on EOutOfMemory do
      Result := SNDFILE_ERR_OUT_OF_MEMORY;
    else
      Result := SNDFILE_ERR_UNEXPECTED;
  end;

  if Result = SNDFILE_OK then
    ASoundFile := LSoundFile
  else
    LSoundFile.Free;
end;

end.
