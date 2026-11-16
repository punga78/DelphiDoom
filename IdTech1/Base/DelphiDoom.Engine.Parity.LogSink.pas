{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the log sink of the parity tools                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Parity.LogSink;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Logging.Types,
  DelphiDoom.Parity.Intf;

type
  /// <summary>
  ///   The sink of the engine when the parity tools may be on: while they are off everything goes to the
  ///   real sink; when they are on the dialogs (the message box of I_Error, which also ends a recorded demo)
  ///   are left out, because nobody is there to click and the run would never end. The same text is still in
  ///   the output and in the file of the errors
  /// </summary>
  TEngineParityLogSink = class(TInterfacedObject, ILogSink)
  strict private
    FReal: ILogSink;
    FSwitch: IParitySwitch;
  public
    constructor Create(const AReal: ILogSink; const ASwitch: IParitySwitch);
    procedure Write(AChannel: TLogChannel; const AText: string);
  end;

implementation

uses
  System.SysUtils;

{ TEngineParityLogSink }

constructor TEngineParityLogSink.Create(const AReal: ILogSink; const ASwitch: IParitySwitch);
begin
  inherited Create;
  if not Assigned(AReal) then
    raise EArgumentNilException.Create('AReal');
  if not Assigned(ASwitch) then
    raise EArgumentNilException.Create('ASwitch');
  FReal := AReal;
  FSwitch := ASwitch;
end;

procedure TEngineParityLogSink.Write(AChannel: TLogChannel; const AText: string);
begin
  if (AChannel = TLogChannel.Dialog) and FSwitch.IsActive then
    Exit;
  FReal.Write(AChannel, AText);
end;

end.
