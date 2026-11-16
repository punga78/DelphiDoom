{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the contract of the sound output             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Audio.Intf;

interface

type
  /// <summary>
  ///   Where an output takes the sound to play: 16 bit samples, left and right, at the rate the output was opened
  ///   with. Called by the thread of the output, not by the one of the game
  /// </summary>
  IGameHostPcmSource = interface
    ['{0E7B4C92-A613-4D58-B9F0-52C81A6D3E47}']
    /// <summary>Fills AByteCount bytes (a multiple of 4) of ABuffer with samples; what has no sound is silence</summary>
    procedure Render(ABuffer: PByte; AByteCount: Integer);
  end;

  /// <summary>
  ///   The sound output of the machine: it asks the source for samples while it is open. The source is not kept
  ///   alive by the output (the mixer of a game owns its output, not the other way round): who opens the output
  ///   keeps the source until Close has returned
  /// </summary>
  IGameHostPcmOutput = interface
    ['{C3A91F06-78D2-4B4E-8A15-9D60E2B7F3C1}']
    /// <summary>Opens the device at the rate (16 bit stereo); false when there is no device that can play</summary>
    function Open(ARate: Integer; const ASource: IGameHostPcmSource): Boolean;
    /// <summary>Stops asking for samples and closes the device</summary>
    procedure Close;
    function IsOpen: Boolean;
    /// <summary>The buffers the device has finished playing since it was opened (proof that the output consumes)</summary>
    function CompletedBuffers: Integer;
  end;

implementation

end.
