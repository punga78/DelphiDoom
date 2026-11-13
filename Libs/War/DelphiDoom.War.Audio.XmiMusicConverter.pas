{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - XMI to MIDI with the converter of Libs\Xmi        }
{                                                                              }
{  Replaces x2m_transcode of shl/xmi2mid.h (war1, acoto87/war1, MIT License)   }
{  with the converter the engine already has: no second XMI converter.         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.XmiMusicConverter;

interface

uses
  System.SysUtils, DelphiDoom.War.Audio.Intf;

type
  /// <summary>
  ///   First song of the XMI file, converted by TXmiConverter. The MIDI it gives has the same notes and controls
  ///   as the one of x2m_transcode (see the README of Libs\War), written differently
  /// </summary>
  TWarXmiMusicConverter = class(TInterfacedObject, IWarMusicConverter)
  public
    function TryConvert(const AXmi: TBytes; out AMidi: TBytes): Boolean;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Converter;

{ TWarXmiMusicConverter }

function TWarXmiMusicConverter.TryConvert(const AXmi: TBytes; out AMidi: TBytes): Boolean;
begin
  AMidi := nil;
  if Length(AXmi) = 0 then
    Exit(False);
  Result := TXmiConverter.ConvertToMidi(@AXmi[0], Length(AXmi), 0, AMidi) = TXmiConversionStatus.Ok;
end;

end.
