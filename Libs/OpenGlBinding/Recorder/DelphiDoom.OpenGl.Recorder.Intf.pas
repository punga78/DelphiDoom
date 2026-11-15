{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - the contracts                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.Intf;

interface

uses
  System.Classes;

type
  /// <summary>
  ///   Collects the GL calls of the frames of a renderer and writes them, one line per call, to a
  ///   text stream. After the lines of a frame comes a line with the number of calls and a FNV-1a
  ///   sum of all of them (see Libs\OpenGl\README.md for the format).
  /// </summary>
  IGlCallRecorder = interface
    ['{6F0E2C1A-84D5-4B77-9A3E-5D21C7B90E14}']
    /// <summary>Opens a frame. Calls made out of a frame are not recorded.</summary>
    procedure BeginFrame;
    /// <summary>
    ///   Closes the open frame and writes it to the stream, with its sum line; the label (for example
    ///   the tic, which is known only at the end of a frame) is written in the sum line.
    /// </summary>
    procedure EndFrame(const ALabel: string);
    /// <summary>Closes the open frame and forgets it (nothing is written)</summary>
    procedure DiscardFrame;
    /// <summary>Adds one line (a call already written as text) to the open frame; ignored if no frame is open</summary>
    procedure Call(const ALine: string);
    /// <summary>The stream the frames are written to</summary>
    function Stream: TStream;
    /// <summary>The number of frames written so far</summary>
    function FrameCount: Integer;
    /// <summary>True between BeginFrame and EndFrame/DiscardFrame</summary>
    function InFrame: Boolean;
  end;

  /// <summary>
  ///   The table of the functions that can be replaced: for each one its name, the address of the
  ///   variable that holds it (a procedure variable of the binding), and the thunk that records
  ///   the call. The table is the only thing that knows the binding.
  /// </summary>
  IGlHookTable = interface
    ['{2B9D4E7C-13A8-4F60-B5C2-8E7A61D3F095}']
    function Count: Integer;
    function Name(const AIndex: Integer): string;
    /// <summary>The address of the variable of the function</summary>
    function Slot(const AIndex: Integer): PPointer;
    /// <summary>The address of the thunk</summary>
    function Thunk(const AIndex: Integer): Pointer;
    /// <summary>Remembers the function that was in the variable before the thunk, so that the thunk can call it</summary>
    procedure SetOriginal(const AIndex: Integer; const AValue: Pointer);
  end;

implementation

end.
