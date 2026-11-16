{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - which MIDI player and which device      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.MidiPlayerSelection;

// What I_InitMidi and I_SelectDefaultMidiDevice of i_midi.pas decided with the command line
// (issue #185).

interface

uses
  DelphiDoom.CommandLine.Intf;

type
  /// <summary>The choice of the MIDI player and of the MIDI device from the command line</summary>
  TMidiPlayerSelection = class
  public
    /// <summary>
    ///   The player after -uselegacymidiplayer (1), -nouselegacymidiplayer (0) and -internalmidiplayer
    ///   (2): the last one that the command line lists in this order wins; AConfigured when none is there
    /// </summary>
    class function ResolvePlayer(const ACommandLine: ICommandLine;
      AConfigured: Integer): Integer; static;
    /// <summary>True for the value of the legacy player</summary>
    class function IsLegacy(APlayer: Integer): Boolean; static;
    /// <summary>
    ///   The number after -mididevice, or ADefault (the MIDI mapper) when it is missing or is not
    ///   a number; "0x" and "#" prefixes are read as the atoui of the old code
    /// </summary>
    class function ResolveDevice(const ACommandLine: ICommandLine;
      ADefault: Cardinal): Cardinal; static;
    /// <summary>atoui(AText, ADefault) of the old code: Val, "0x" and hexadecimal digits, "#" and decimal digits</summary>
    class function ParseDevice(const AText: string; ADefault: Cardinal): Cardinal; static;
  end;

implementation

uses
  DelphiDoom.EngineSystem.Types;

{ TMidiPlayerSelection }

class function TMidiPlayerSelection.ResolvePlayer(const ACommandLine: ICommandLine;
  AConfigured: Integer): Integer;
begin
  Result := AConfigured;
  // the three questions are always asked, in this order: the queried command line remembers them
  if ACommandLine.IndexOf('-uselegacymidiplayer') > 0 then
    Result := MIDI_PLAYER_LEGACY;
  if ACommandLine.IndexOf('-nouselegacymidiplayer') > 0 then
    Result := MIDI_PLAYER_STREAM;
  if ACommandLine.IndexOf('-internalmidiplayer') > 0 then
    Result := MIDI_PLAYER_INTERNAL;
end;

class function TMidiPlayerSelection.IsLegacy(APlayer: Integer): Boolean;
begin
  Result := APlayer = MIDI_PLAYER_LEGACY;
end;

class function TMidiPlayerSelection.ParseDevice(const AText: string; ADefault: Cardinal): Cardinal;
var
  LCode: Integer;
  LOther: Cardinal;
begin
  Val(AText, Result, LCode);
  if LCode <> 0 then
  begin
    LOther := ADefault;
    if (Length(AText) >= 2) and (AText[1] = '0') and (AText[2] = 'x') then
      Val('$' + Copy(AText, 3, Length(AText) - 2), LOther, LCode)
    else if (Length(AText) >= 1) and (AText[1] = '#') then
      Val(Copy(AText, 2, Length(AText) - 1), LOther, LCode);
    if LCode = 0 then
      Result := LOther
    else
      Result := ADefault;
  end;
end;

class function TMidiPlayerSelection.ResolveDevice(const ACommandLine: ICommandLine;
  ADefault: Cardinal): Cardinal;
var
  LIndex: Integer;
begin
  Result := ADefault;
  LIndex := ACommandLine.IndexOf('-mididevice');
  if (LIndex > 0) and (LIndex < ACommandLine.Count) then
  begin
    // the old code read myargv[p + 1], an empty string after the last argument
    if LIndex + 1 < ACommandLine.Count then
      Result := ParseDevice(ACommandLine[LIndex + 1], ADefault)
    else
      Result := ParseDevice('', ADefault);
  end;
end;

end.
