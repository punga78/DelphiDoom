{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - the factory: the composition root                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.Factory;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Midi.Intf;

type
  /// <summary>The only place that knows the classes behind the MIDI contracts</summary>
  TMidiFactory = class
  public
    /// <summary>A sequencer with nothing loaded; ALog may be nil</summary>
    class function CreateSequencer(const ALog: ILog): IMidiStreamSequencer; static;
    /// <summary>The maker of sequencers: each one it makes warns ALog (that may be nil)</summary>
    class function CreateSequencerFactory(const ALog: ILog): IMidiStreamSequencerFactory; static;
  end;

implementation

uses
  DelphiDoom.Midi.StreamSequencer;

type
  /// <summary>Makes a sequencer for each song, all with the same log</summary>
  TMidiSequencerFactory = class(TInterfacedObject, IMidiStreamSequencerFactory)
  strict private
    FLog: ILog;
  public
    constructor Create(const ALog: ILog);
    function CreateSequencer: IMidiStreamSequencer;
  end;

{ TMidiSequencerFactory }

constructor TMidiSequencerFactory.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

function TMidiSequencerFactory.CreateSequencer: IMidiStreamSequencer;
begin
  Result := TMidiStreamSequencer.Create(FLog);
end;

{ TMidiFactory }

class function TMidiFactory.CreateSequencer(const ALog: ILog): IMidiStreamSequencer;
begin
  Result := TMidiStreamSequencer.Create(ALog);
end;

class function TMidiFactory.CreateSequencerFactory(const ALog: ILog): IMidiStreamSequencerFactory;
begin
  Result := TMidiSequencerFactory.Create(ALog);
end;

end.
