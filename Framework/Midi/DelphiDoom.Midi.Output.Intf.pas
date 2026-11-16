{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - the contract of a MIDI output                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.Output.Intf;

interface

type
  /// <summary>
  ///   A MIDI output that takes one short message at a time, now (the midiOut* functions of Windows, or a fake in a
  ///   test): the program that has its own clock (a game that mixes the song with its other sounds) sends the events when
  ///   they are due and the device plays them. It is not the MIDI stream of Windows, where the device keeps the time
  /// </summary>
  IMidiShortOutput = interface
    ['{A4C7E219-3B58-4D06-91F2-7E80B5D3C61A}']
    /// <summary>Opens the device; False when the machine has none or it is busy</summary>
    function Open: Boolean;
    /// <summary>Puts every note off, and closes the device</summary>
    procedure Close;
    function IsOpen: Boolean;
    /// <summary>
    ///   A message of up to three bytes: the status (a channel message, $80 to $EF) and its data bytes (0 to 127). Nothing
    ///   happens when the device is not open
    /// </summary>
    procedure Send(AStatus, AData1, AData2: Byte);
  end;

implementation

end.
