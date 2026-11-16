{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - the session the thunks write to          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.Session;

// A thunk is a plain procedure with the signature of a GL function: it cannot receive an object, so
// the recorder it writes to has to be reachable from a unit variable. This is the only global of the
// recorder, it is set only by a test executable (Hook.pas, GLRECORD) and the calls are made by the
// thread of the GL context, so there is no locking.

interface

uses
  DelphiDoom.OpenGl.Recorder.Intf,
  DelphiDoom.OpenGl.Recorder.Types;

/// <summary>Starts to send the calls of the thunks to ARecorder</summary>
procedure GlSessionStart(const ARecorder: IGlCallRecorder);

/// <summary>Stops: the thunks go on calling the original functions and write nothing</summary>
procedure GlSessionStop;

/// <summary>Called by a thunk before it calls the original function</summary>
procedure GlSessionRecord(const AName: string; const AValues: array of TGlValue);

implementation

uses
  System.SysUtils,
  DelphiDoom.OpenGl.Recorder.Encoder;

var
  GRecorder: IGlCallRecorder = nil;
  GEncoder: TGlCallEncoder = nil;

procedure GlSessionStart(const ARecorder: IGlCallRecorder);
begin
  GlSessionStop;
  GRecorder := ARecorder;
  GEncoder := TGlCallEncoder.Create;
end;

procedure GlSessionStop;
begin
  GRecorder := nil;
  FreeAndNil(GEncoder);
end;

procedure GlSessionRecord(const AName: string; const AValues: array of TGlValue);
begin
  // outside a frame the call is not encoded at all, but the state that the encoder follows
  // (unpack alignment, client arrays) has to see every call: it is encoded and thrown away
  if Assigned(GRecorder) and Assigned(GEncoder) then
    GRecorder.Call(GEncoder.Encode(AName, AValues));
end;

initialization

finalization
  GlSessionStop;

end.
