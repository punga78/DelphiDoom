{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed32 - the log on the console                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Sim.LogSink;

interface

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Intf;

type
  /// <summary>Writes the messages of the log on the console: the translator of the game warns about the data that it cannot use</summary>
  TSpeedConsoleLogSink = class(TInterfacedObject, ILogSink)
  public
    procedure Write(AChannel: TLogChannel; const AText: string);
  end;

implementation

{ TSpeedConsoleLogSink }

procedure TSpeedConsoleLogSink.Write(AChannel: TLogChannel; const AText: string);
begin
  System.Write(AText);
end;

end.
