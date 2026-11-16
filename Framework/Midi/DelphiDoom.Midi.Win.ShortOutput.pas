{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - the MIDI output of Windows, message by message   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.Win.ShortOutput;

interface

uses
  Winapi.Windows, Winapi.MMSystem, DelphiDoom.Midi.Output.Intf;

type
  /// <summary>
  ///   IMidiShortOutput on midiOutOpen with the MIDI mapper (the "Microsoft GS Wavetable Synth" if the player has not
  ///   chosen another device in the sound settings of Windows) and midiOutShortMsg. Not thread safe: the program calls it
  ///   from one place at a time (the lock of the music player)
  /// </summary>
  TMidiWinShortOutput = class(TInterfacedObject, IMidiShortOutput)
  strict private
    FHandle: HMIDIOUT;
    FOpen: Boolean;
  public
    destructor Destroy; override;
    function Open: Boolean;
    procedure Close;
    function IsOpen: Boolean;
    procedure Send(AStatus, AData1, AData2: Byte);
  end;

implementation

{ TMidiWinShortOutput }

destructor TMidiWinShortOutput.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TMidiWinShortOutput.Open: Boolean;
begin
  if FOpen then
    Exit(True);
  Result := (midiOutGetNumDevs > 0) and
    (midiOutOpen(@FHandle, MIDI_MAPPER, 0, 0, CALLBACK_NULL) = MMSYSERR_NOERROR);
  FOpen := Result;
end;

procedure TMidiWinShortOutput.Close;
begin
  if not FOpen then
    Exit;
  FOpen := False;
  // the notes that sound stop at once: the device would hold them after the handle is gone
  midiOutReset(FHandle);
  midiOutClose(FHandle);
  FHandle := 0;
end;

function TMidiWinShortOutput.IsOpen: Boolean;
begin
  Result := FOpen;
end;

procedure TMidiWinShortOutput.Send(AStatus, AData1, AData2: Byte);
begin
  if not FOpen then
    Exit;
  midiOutShortMsg(FHandle, DWORD(AStatus) or (DWORD(AData1) shl 8) or (DWORD(AData2) shl 16));
end;

end.
