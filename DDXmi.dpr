{******************************************************************************}
{                                                                              }
{  DDXmi.dll: XMI/CMF to MIDI conversion for DelphiDoom                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDXmi;

uses
  DelphiDoom.Xmi.Intf in 'Libs\Xmi\DelphiDoom.Xmi.Intf.pas',
  DelphiDoom.Xmi.Midi.Types in 'Libs\Xmi\DelphiDoom.Xmi.Midi.Types.pas',
  DelphiDoom.Xmi.Midi.Track in 'Libs\Xmi\DelphiDoom.Xmi.Midi.Track.pas',
  DelphiDoom.Xmi.Midi.Song in 'Libs\Xmi\DelphiDoom.Xmi.Midi.Song.pas',
  DelphiDoom.Xmi.Midi.ByteReader in 'Libs\Xmi\DelphiDoom.Xmi.Midi.ByteReader.pas',
  DelphiDoom.Xmi.Iff in 'Libs\Xmi\DelphiDoom.Xmi.Iff.pas',
  DelphiDoom.Xmi.Reader.SystemEvent in 'Libs\Xmi\DelphiDoom.Xmi.Reader.SystemEvent.pas',
  DelphiDoom.Xmi.Reader.MidiTrack in 'Libs\Xmi\DelphiDoom.Xmi.Reader.MidiTrack.pas',
  DelphiDoom.Xmi.Reader.Xmi in 'Libs\Xmi\DelphiDoom.Xmi.Reader.Xmi.pas',
  DelphiDoom.Xmi.Reader.Cmf in 'Libs\Xmi\DelphiDoom.Xmi.Reader.Cmf.pas',
  DelphiDoom.Xmi.Converter.XmiToMidi in 'Libs\Xmi\DelphiDoom.Xmi.Converter.XmiToMidi.pas',
  DelphiDoom.Xmi.Converter.CmfToMidi in 'Libs\Xmi\DelphiDoom.Xmi.Converter.CmfToMidi.pas',
  DelphiDoom.Xmi.Writer.Midi in 'Libs\Xmi\DelphiDoom.Xmi.Writer.Midi.pas',
  DelphiDoom.Xmi.FormatDetector in 'Libs\Xmi\DelphiDoom.Xmi.FormatDetector.pas',
  DelphiDoom.Xmi.Converter in 'Libs\Xmi\DelphiDoom.Xmi.Converter.pas',
  DelphiDoom.Xmi.Engine in 'Libs\Xmi\DelphiDoom.Xmi.Engine.pas';

function DDXmiCreate(out AXmi: IXmi): Integer; stdcall;
begin
  AXmi := nil;
  try
    AXmi := TXmiEngine.Create;
    Result := XMI_OK;
  except
    Result := XMI_ERROR_MEMORY;
  end;
end;

exports
  DDXmiCreate;

begin
end.
