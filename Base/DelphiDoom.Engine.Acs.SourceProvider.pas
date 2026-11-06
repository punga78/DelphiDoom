{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the files that an ACS script includes                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Acs.SourceProvider;

interface

uses
  SysUtils,
  DelphiDoom.Acs.Intf;

type
  /// <summary>An included file is looked for like the files of the game: on disk first, then in the PAKs</summary>
  TEngineAcsSourceProvider = class(TInterfacedObject, IAcsSourceProvider)
  public
    function TryLoad(const AName: string; out AText: TBytes): Boolean;
  end;

implementation

uses
  d_delphi,
  w_pak;

{ TEngineAcsSourceProvider }

function TEngineAcsSourceProvider.TryLoad(const AName: string; out AText: TBytes): Boolean;
var
  LStream: TPakStream;
  LSize: integer;
begin
  AText := nil;
  LStream := TPakStream.Create(AName, pm_short);
  try
    if LStream.IOResult <> 0 then
    begin
      Result := False;
      Exit;
    end;

    LSize := LStream.Size;
    SetLength(AText, LSize);
    LStream.Seek(0, sFromBeginning);
    Result := (LSize = 0) or (LStream.Read(AText[0], LSize) = LSize);
  finally
    LStream.Free;
  end;
end;

end.
