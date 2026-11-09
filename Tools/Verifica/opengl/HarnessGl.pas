{******************************************************************************}
{                                                                              }
{  TEMPORARY HARNESS of issue #177 (never part of the engine projects):        }
{  records the GL calls of the frames after a level has been loaded and        }
{  writes them to glrecord_<MAP>.txt, so that two executables can be           }
{  compared line by line (Confronta.ps1).                                      }
{                                                                              }
{    HarnessGl_AfterExtensions  in GL_InitGraphics, after ReadExtensions       }
{    HarnessGl_AfterLevel       at the end of TLevelLoader.SetupLevel          }
{    HarnessGl_FrameEnd         in gld_Finish, after SwapBuffers               }
{                                                                              }
{  Active only with  -glrecord <n>  on the command line, and only in an        }
{  executable compiled with GLRECORD (Compila.ps1 does it).                    }
{    -glrecord <n>       record n consecutive tics, then Halt(0)               }
{    -glrecordstart <t>  first tic to record (default 35: one second of game)  }
{                                                                              }
{  For each tic the harness keeps only the FIRST frame drawn with that tic:    }
{  the number of frames per tic depends on the speed of the machine, the       }
{  first one does not. If a tic is skipped (the machine was too slow) a        }
{  line  # SKIPPED  is written and the two runs will differ.                   }
{                                                                              }
{******************************************************************************}
unit HarnessGl;

interface

procedure HarnessGl_AfterExtensions;

procedure HarnessGl_AfterLevel(const AMapName: string);

procedure HarnessGl_FrameEnd;

implementation

uses
  SysUtils,
  Classes,
  g_game,
  DelphiDoom.OpenGl.Recorder.Intf,
  DelphiDoom.OpenGl.Recorder.CallRecorder,
  DelphiDoom.OpenGl.Recorder.Hook;

var
  GEnabled: Boolean = False;
  GArmed: Boolean = False;
  GLimit: Integer = 0;
  GStartTic: Integer = 35;
  GTarget: Integer = 0;
  GKept: Integer = 0;
  GSkipped: Integer = 0;
  GMap: string = '';
  GHooked: Integer = 0;
  GStream: TMemoryStream = nil;
  GRecorder: IGlCallRecorder = nil;

procedure WriteText(const AText: AnsiString);
begin
  if Length(AText) > 0 then
    GStream.WriteBuffer(AText[1], Length(AText));
end;

procedure Finish;
var
  LFile: TFileStream;
  LHeader: AnsiString;
begin
  LHeader := AnsiString(Format('# glrecord map=%s tics=%d..%d frames=%d skipped=%d hooked=%d missing=[%s]'#10,
    [GMap, GStartTic, GTarget - 1, GKept, GSkipped, GHooked, GlRecorderMissing]));
  LFile := TFileStream.Create('glrecord_' + GMap + '.txt', fmCreate);
  try
    LFile.WriteBuffer(LHeader[1], Length(LHeader));
    if GStream.Size > 0 then
      LFile.WriteBuffer(GStream.Memory^, GStream.Size);
  finally
    LFile.Free;
  end;
  GlRecorderUninstall;
  GRecorder := nil;
  Halt(0);
end;

procedure HarnessGl_AfterExtensions;
begin
  if not GEnabled then
    Exit;
  GStream := TMemoryStream.Create;
  GRecorder := TGlCallRecorder.Create(GStream);
  GHooked := GlRecorderInstall(GRecorder);
end;

procedure HarnessGl_AfterLevel(const AMapName: string);
begin
  if not GEnabled or GArmed or not Assigned(GRecorder) then
    Exit;
  GArmed := True;
  GMap := AMapName;
  GTarget := GStartTic;
  GRecorder.BeginFrame;
end;

procedure HarnessGl_FrameEnd;
var
  LTic: Integer;
begin
  if not GArmed then
    Exit;
  LTic := g_game.gametic;
  if LTic < GTarget then
    GRecorder.DiscardFrame
  else
  begin
    if LTic > GTarget then
    begin
      Inc(GSkipped);
      WriteText(AnsiString(Format('# SKIPPED tic %d..%d'#10, [GTarget, LTic - 1])));
    end;
    GRecorder.EndFrame('tic=' + IntToStr(LTic));
    GTarget := LTic + 1;
    Inc(GKept);
    if GKept >= GLimit then
      Finish;
  end;
  GRecorder.BeginFrame;
end;

procedure Initialize;
var
  LIndex: Integer;
begin
  for LIndex := 1 to ParamCount do
  begin
    if SameText(ParamStr(LIndex), '-glrecord') and (LIndex < ParamCount) then
    begin
      GLimit := StrToIntDef(ParamStr(LIndex + 1), 0);
      GEnabled := (GLimit > 0) and GL_RECORDER_COMPILED;
    end;
    if SameText(ParamStr(LIndex), '-glrecordstart') and (LIndex < ParamCount) then
      GStartTic := StrToIntDef(ParamStr(LIndex + 1), 35);
  end;
end;

initialization
  Initialize;

finalization
  GStream.Free;

end.
