{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the lock between the sound output and the game    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.AudioLock;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf;

type
  /// <summary>A monitor: the thread that has it can enter again</summary>
  TKeenAudioLock = class(TInterfacedObject, IKeenAudioLock)
  public
    procedure Enter;
    procedure Leave;
  end;

implementation

{ TKeenAudioLock }

procedure TKeenAudioLock.Enter;
begin
  TMonitor.Enter(Self);
end;

procedure TKeenAudioLock.Leave;
begin
  TMonitor.Exit(Self);
end;

end.
