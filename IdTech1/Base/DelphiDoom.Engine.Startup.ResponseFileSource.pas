{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the files of the response files (@name)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Startup.ResponseFileSource;

interface

uses
  DelphiDoom.CommandLine.Intf;

type
  /// <summary>Reads a response file from the disk: its bytes are the characters of the text (8 bit)</summary>
  TEngineResponseFileSource = class(TInterfacedObject, IResponseFileSource)
  public
    function TryRead(const AFileName: string; out AText: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.Classes;

{ TEngineResponseFileSource }

function TEngineResponseFileSource.TryRead(const AFileName: string; out AText: string): Boolean;
var
  LStream: TFileStream;
  LBytes: AnsiString;
begin
  AText := '';
  Result := False;
  if not FileExists(AFileName) then
    Exit;
  try
    LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  except
    on EFOpenError do
      Exit;
  end;
  try
    SetLength(LBytes, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(LBytes[1], LStream.Size);
  finally
    LStream.Free;
  end;
  AText := string(LBytes);
  Result := True;
end;

end.
