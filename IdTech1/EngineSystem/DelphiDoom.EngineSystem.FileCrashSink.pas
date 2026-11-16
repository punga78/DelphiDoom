{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the file of the crash report            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.FileCrashSink;

// Writes with WriteFile on a handle that is already open: no stream, no string, no exception.
// The sink is made when the logger is installed, the file is opened when the crash comes.

interface

uses
  Winapi.Windows, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>The crash report in a file, written as it comes</summary>
  TFileCrashSink = class(TInterfacedObject, ICrashFileSink)
  strict private
    FHandle: THandle;
  public
    constructor Create;
    procedure SetTarget(AHandle: NativeUInt);
    procedure Write(AText: PAnsiChar);
  end;

implementation

{ TFileCrashSink }

constructor TFileCrashSink.Create;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
end;

procedure TFileCrashSink.SetTarget(AHandle: NativeUInt);
begin
  FHandle := THandle(AHandle);
end;

procedure TFileCrashSink.Write(AText: PAnsiChar);
var
  LWritten: DWORD;
begin
  WriteFile(FHandle, AText^, lstrlenA(AText), LWritten, nil);
end;

end.
