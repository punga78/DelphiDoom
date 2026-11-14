{******************************************************************************}
{                                                                              }
{  DDXmi.dll: XMI/CMF to MIDI conversion for DelphiDoom                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDXmi;

// the 64-bit library is DD<Name>64.dll, so that it never overwrites or gets confused with the 32-bit one
{$IFDEF CPUX64}
{$LIBSUFFIX '64'}
{$ENDIF}

uses
  DelphiDoom.Xmi.Intf in 'DelphiDoom.Xmi.Intf.pas',
  DelphiDoom.Xmi.Midi.Types in 'DelphiDoom.Xmi.Midi.Types.pas',
  DelphiDoom.Xmi.Midi.Track in 'DelphiDoom.Xmi.Midi.Track.pas',
  DelphiDoom.Xmi.Midi.Song in 'DelphiDoom.Xmi.Midi.Song.pas',
  DelphiDoom.Xmi.Midi.ByteReader in 'DelphiDoom.Xmi.Midi.ByteReader.pas',
  DelphiDoom.Xmi.Iff in 'DelphiDoom.Xmi.Iff.pas',
  DelphiDoom.Xmi.Reader.SystemEvent in 'DelphiDoom.Xmi.Reader.SystemEvent.pas',
  DelphiDoom.Xmi.Reader.MidiTrack in 'DelphiDoom.Xmi.Reader.MidiTrack.pas',
  DelphiDoom.Xmi.Reader.Xmi in 'DelphiDoom.Xmi.Reader.Xmi.pas',
  DelphiDoom.Xmi.Reader.Cmf in 'DelphiDoom.Xmi.Reader.Cmf.pas',
  DelphiDoom.Xmi.Converter.XmiToMidi in 'DelphiDoom.Xmi.Converter.XmiToMidi.pas',
  DelphiDoom.Xmi.Converter.CmfToMidi in 'DelphiDoom.Xmi.Converter.CmfToMidi.pas',
  DelphiDoom.Xmi.Writer.Midi in 'DelphiDoom.Xmi.Writer.Midi.pas',
  DelphiDoom.Xmi.FormatDetector in 'DelphiDoom.Xmi.FormatDetector.pas',
  DelphiDoom.Xmi.Converter in 'DelphiDoom.Xmi.Converter.pas',
  DelphiDoom.Xmi.Engine in 'DelphiDoom.Xmi.Engine.pas';

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
