{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where the messages of the log go                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Log.Sink;

interface

uses
  d_delphi, DelphiDoom.Logging.Types, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   The sink of the engine: the output is printf (the startup window, the console of the game
  ///   and the stdout file, whichever is listening), the error file is stderr, the dialog is a
  ///   message box
  /// </summary>
  TEngineLogSink = class(TInterfacedObject, ILogSink)
  public
    procedure Write(AChannel: TLogChannel; const AText: string);
  end;

implementation

uses
  i_io;

{ TEngineLogSink }

procedure TEngineLogSink.Write(AChannel: TLogChannel; const AText: string);
begin
  case AChannel of
    TLogChannel.Output:
      printf(AText);
    TLogChannel.ErrorFile:
      fprintf(stderr, AText);
    TLogChannel.Dialog:
      I_IOErrorMessageBox(AText);
  end;
end;

end.
