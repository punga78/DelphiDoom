{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - writing of the files                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.FileSink;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Intf;

type
  /// <summary>Writes the files with a file stream</summary>
  TScreenshotFileSink = class(TInterfacedObject, IScreenshotFileSink)
  public
    function Write(const APath: string; const AContent: TBytes): Boolean;
  end;

implementation

uses
  System.Classes;

{ TScreenshotFileSink }

function TScreenshotFileSink.Write(const APath: string; const AContent: TBytes): Boolean;
var
  LFile: TFileStream;
begin
  Result := False;
  if Length(AContent) = 0 then
    Exit;
  try
    LFile := TFileStream.Create(APath, fmCreate);
    try
      LFile.WriteBuffer(AContent[0], Length(AContent));
    finally
      LFile.Free;
    end;
    Result := True;
  except
    on EStreamError do
      Result := False;
    on EInOutError do
      Result := False;
  end;
end;

end.
