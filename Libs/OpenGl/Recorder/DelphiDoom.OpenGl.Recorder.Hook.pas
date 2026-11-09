{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - the switch (GLRECORD)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.Hook;

// The recorder is built only when GLRECORD is defined (the test executables of Tools\Verifica\opengl,
// compiled with the environment variable DCC_Define=GLRECORD). Without the define this unit does
// nothing and does not even use the generated thunks, so that a normal build is the same as before.

interface

uses
  DelphiDoom.OpenGl.Recorder.Intf;

const
  /// <summary>True if this executable was compiled with GLRECORD</summary>
{$IFDEF GLRECORD}
  GL_RECORDER_COMPILED = True;
{$ELSE}
  GL_RECORDER_COMPILED = False;
{$ENDIF}

/// <summary>
///   Replaces the GL functions of dglOpenGL with the recording thunks and starts to send the calls
///   to ARecorder; the number of functions replaced. Call it after ReadExtensions: the variables
///   have to hold the functions of the driver. Does nothing (0) if GLRECORD is not defined.
/// </summary>
function GlRecorderInstall(const ARecorder: IGlCallRecorder): Integer;

/// <summary>The functions that the driver did not give and that are not recorded, separated by spaces</summary>
function GlRecorderMissing: string;

/// <summary>Puts the original functions back and stops the session</summary>
procedure GlRecorderUninstall;

implementation

{$IFDEF GLRECORD}
uses
  System.SysUtils,
  DelphiDoom.OpenGl.Recorder.Installer,
  DelphiDoom.OpenGl.Recorder.Session,
  DelphiDoom.OpenGl.Recorder.Thunks;

var
  GInstaller: TGlHookInstaller = nil;

function GlRecorderInstall(const ARecorder: IGlCallRecorder): Integer;
begin
  GlRecorderUninstall;
  GlSessionStart(ARecorder);
  GInstaller := TGlHookInstaller.Create(CreateGlHookTable);
  Result := GInstaller.Install;
end;

function GlRecorderMissing: string;
var
  LName: string;
begin
  Result := '';
  if not Assigned(GInstaller) then
    Exit;
  for LName in GInstaller.Missing do
    Result := Result + LName + ' ';
  Result := Trim(Result);
end;

procedure GlRecorderUninstall;
begin
  if Assigned(GInstaller) then
    GInstaller.Uninstall;
  FreeAndNil(GInstaller);
  GlSessionStop;
end;
{$ELSE}
function GlRecorderInstall(const ARecorder: IGlCallRecorder): Integer;
begin
  Result := 0;
end;

function GlRecorderMissing: string;
begin
  Result := '';
end;

procedure GlRecorderUninstall;
begin
end;
{$ENDIF}

end.
