{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - a log that remembers the warnings            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.FakeLog;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf;

type
  TFakeMidiLog = class(TInterfacedObject, ILog)
  strict private
    FWarnings: Integer;
    FDevWarnings: Integer;
    FLast: string;
  public
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: Integer read FWarnings;
    property DevWarnings: Integer read FDevWarnings;
    property Last: string read FLast;
  end;

implementation

procedure TFakeMidiLog.Info(const AText: string);
begin
  FLast := AText;
end;

procedure TFakeMidiLog.Warning(const AText: string);
begin
  Inc(FWarnings);
  FLast := AText;
end;

procedure TFakeMidiLog.DevWarning(const AText: string);
begin
  Inc(FDevWarnings);
  FLast := AText;
end;

procedure TFakeMidiLog.Error(const AText: string);
begin
  FLast := AText;
end;

end.
