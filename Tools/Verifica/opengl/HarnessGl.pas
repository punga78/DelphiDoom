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
{    HarnessGl_AfterPreprocess  at the end of gld_PreprocessLevel              }
{                                                                              }
{  Second mode, -glfingerprint <file>: after the first level (-warp) it loads  }
{  every map of the IWAD with the loader, one after the other, and writes one  }
{  line of FNV-1a 64 sums per map (GL vertexes and texture coordinates, the    }
{  loops of every sector, flags of sectors and lines, vertexes, segs,          }
{  subsectors and nodes by value: no pointers), then Halt(0). Two executables  }
{  (old and new commit) give two files that must be identical.                 }{                                                                              }
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

uses
  DelphiDoom.Clock.Intf;

/// With -glrecord the clock of the program is a virtual one that advances by one tic at every end of a
/// frame (and at every Sleep/Wait): the sequence of tics and frames does not depend on the speed of the
/// machine (two runs of one executable are then identical). Without -glrecord the real clock is returned.
function HarnessGl_Clock(const AReal: IClock): IClock;

procedure HarnessGl_AfterExtensions;

procedure HarnessGl_AfterLevel(const AMapName: string; const ALoader: TObject; AEpisode, AMap, APlayerMask,
  ASkill: Integer);

procedure HarnessGl_FrameEnd;

procedure HarnessGl_AfterPreprocess(const AVertexes, ATexcoords: Pointer; ACount: Integer; const ASectorLoops: Pointer);

implementation

uses
  SysUtils,
  Classes,
  g_game,
  doomdef,
  doomdata,
  d_player,
  r_defs,
  p_setup,
  w_wad,
  gl_types,
  DelphiDoom.Engine.Level.Intf,
  DelphiDoom.OpenGl.Recorder.Fnv,
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
  GVirtualTic: Integer = 0;
  GVirtualReads: Integer = 0;

type
  TVirtualClock = class(TInterfacedObject, IClock)
  public
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    procedure Wait(AMilliseconds: Integer);
  end;

procedure CountRead;
begin
  // a loop that spins on the clock (until tics <> 0) has to end: every 100000 readings without a frame end are a tic
  Inc(GVirtualReads);
  if GVirtualReads >= 100000 then
  begin
    GVirtualReads := 0;
    Inc(GVirtualTic);
  end;
end;

function TVirtualClock.Seconds: Double;
begin
  CountRead;
  Result := GVirtualTic / 35;
end;

function TVirtualClock.Steps(ARate: Integer): Integer;
begin
  CountRead;
  Result := Integer((Int64(GVirtualTic) * ARate) div 35);
end;

function TVirtualClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  CountRead;
  Result := Integer((Int64(GVirtualTic) * ARate * AScale) div 35);
end;

procedure TVirtualClock.Sleep(AMilliseconds: Integer);
begin
  Inc(GVirtualTic);
end;

procedure TVirtualClock.Wait(AMilliseconds: Integer);
begin
  Inc(GVirtualTic);
end;

function HarnessGl_Clock(const AReal: IClock): IClock;
begin
  if GEnabled then
    Result := TVirtualClock.Create
  else
    Result := AReal;
end;

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

type
  THarnessLoop = record
    Mode: Cardinal;
    VertexCount: Integer;
    VertexIndex: Integer;
  end;
  PHarnessLoop = ^THarnessLoop;
  THarnessSector = record
    LoopCount: Integer;
    Loops: PHarnessLoop;
    List: Cardinal;
    ListTexScale: Single;
  end;
  PHarnessSector = ^THarnessSector;

var
  GFingerprintFile: string = '';
  GFingerprintRunning: Boolean = False;
  GFingerprint: TStringList = nil;
  GSeenMaps: TStringList = nil;
  GPreVertexes: Pointer = nil;
  GPreTexcoords: Pointer = nil;
  GPreCount: Integer = 0;
  GPreLoops: Pointer = nil;

procedure HarnessGl_AfterPreprocess(const AVertexes, ATexcoords: Pointer; ACount: Integer; const ASectorLoops: Pointer);
begin
  GPreVertexes := AVertexes;
  GPreTexcoords := ATexcoords;
  GPreCount := ACount;
  GPreLoops := ASectorLoops;
end;

function Mix(const AHash: UInt64; AValue: Int64): UInt64;
begin
  Result := TGlFnv.UpdateBuffer(AHash, @AValue, SizeOf(AValue));
end;

function VertexIndex(const AVertex: Pvertex_t): Integer;
begin
  if AVertex = nil then
    Result := -1
  else
    Result := (NativeInt(AVertex) - NativeInt(vertexes)) div SizeOf(vertex_t);
end;

function LineIndex(const ALine: Pline_t): Integer;
begin
  if ALine = nil then
    Result := -1
  else
    Result := (NativeInt(ALine) - NativeInt(lines)) div SizeOf(line_t);
end;

function SectorIndex(const ASector: Psector_t): Integer;
begin
  if ASector = nil then
    Result := -1
  else
    Result := (NativeInt(ASector) - NativeInt(sectors)) div SizeOf(sector_t);
end;

function SideIndex(const ASide: Pside_t): Integer;
begin
  if ASide = nil then
    Result := -1
  else
    Result := (NativeInt(ASide) - NativeInt(sides)) div SizeOf(side_t);
end;

function FingerprintLevel: string;
var
  LHash: UInt64;
  LIndex, LLoop: Integer;
  LLoops: PHarnessLoop;
  LSector: PHarnessSector;
  LParts: array[0..7] of UInt64;
  LSeg: Pseg_t;
begin
  LParts[0] := Mix(TGlFnv.Start, GPreCount);
  if GPreCount > 0 then
  begin
    LParts[0] := TGlFnv.UpdateBuffer(LParts[0], GPreVertexes, GPreCount * SizeOf(GLVertex));
    LParts[0] := TGlFnv.UpdateBuffer(LParts[0], GPreTexcoords, GPreCount * SizeOf(GLTexcoord));
  end;

  LHash := Mix(TGlFnv.Start, numsectors);
  for LIndex := 0 to numsectors - 1 do
  begin
    LSector := PHarnessSector(NativeInt(GPreLoops) + LIndex * SizeOf(THarnessSector));
    LHash := Mix(LHash, LSector.LoopCount);
    LLoops := LSector.Loops;
    for LLoop := 0 to LSector.LoopCount - 1 do
    begin
      LHash := Mix(LHash, LLoops.Mode);
      LHash := Mix(LHash, LLoops.VertexCount);
      LHash := Mix(LHash, LLoops.VertexIndex);
      Inc(LLoops);
    end;
  end;
  LParts[1] := LHash;

  LHash := Mix(TGlFnv.Start, numsectors);
  for LIndex := 0 to numsectors - 1 do
  begin
    LHash := Mix(LHash, sectors[LIndex].floorheight);
    LHash := Mix(LHash, sectors[LIndex].ceilingheight);
    LHash := Mix(LHash, sectors[LIndex].floorpic);
    LHash := Mix(LHash, sectors[LIndex].ceilingpic);
    LHash := Mix(LHash, sectors[LIndex].lightlevel);
    LHash := Mix(LHash, sectors[LIndex].special);
    LHash := Mix(LHash, sectors[LIndex].tag);
    LHash := Mix(LHash, sectors[LIndex].linecount);
    LHash := Mix(LHash, sectors[LIndex].renderflags);
    LHash := Mix(LHash, sectors[LIndex].flags);
    LHash := Mix(LHash, Ord(sectors[LIndex].no_toptextures));
    LHash := Mix(LHash, Ord(sectors[LIndex].no_bottomtextures));
  end;
  LParts[2] := LHash;

  LHash := Mix(TGlFnv.Start, numlines);
  for LIndex := 0 to numlines - 1 do
  begin
    LHash := Mix(LHash, VertexIndex(lines[LIndex].v1));
    LHash := Mix(LHash, VertexIndex(lines[LIndex].v2));
    LHash := Mix(LHash, lines[LIndex].sidenum[0]);
    LHash := Mix(LHash, lines[LIndex].sidenum[1]);
    LHash := Mix(LHash, lines[LIndex].flags);
    LHash := Mix(LHash, lines[LIndex].special);
    LHash := Mix(LHash, lines[LIndex].renderflags);
  end;
  LParts[3] := LHash;

  LHash := Mix(TGlFnv.Start, numvertexes);
  for LIndex := 0 to numvertexes - 1 do
  begin
    LHash := Mix(LHash, vertexes[LIndex].x);
    LHash := Mix(LHash, vertexes[LIndex].y);
  end;
  LParts[4] := LHash;

  LHash := Mix(TGlFnv.Start, numsegs);
  for LIndex := 0 to numsegs - 1 do
  begin
    LSeg := @segs[LIndex];
    LHash := Mix(LHash, VertexIndex(LSeg.v1));
    LHash := Mix(LHash, VertexIndex(LSeg.v2));
    LHash := Mix(LHash, LSeg.offset);
    LHash := Mix(LHash, LSeg.angle);
    LHash := Mix(LHash, SideIndex(LSeg.sidedef));
    LHash := Mix(LHash, LineIndex(LSeg.linedef));
    LHash := Mix(LHash, SectorIndex(LSeg.frontsector));
    LHash := Mix(LHash, SectorIndex(LSeg.backsector));
    LHash := TGlFnv.UpdateBuffer(LHash, @LSeg.length, SizeOf(LSeg.length));
    LHash := Mix(LHash, LSeg.iSegID);
  end;
  LParts[5] := LHash;

  LHash := Mix(TGlFnv.Start, numsubsectors);
  for LIndex := 0 to numsubsectors - 1 do
  begin
    LHash := Mix(LHash, SectorIndex(subsectors[LIndex].sector));
    LHash := Mix(LHash, subsectors[LIndex].numlines);
    LHash := Mix(LHash, subsectors[LIndex].firstline);
    LHash := Mix(LHash, subsectors[LIndex].x);
    LHash := Mix(LHash, subsectors[LIndex].y);
    LHash := Mix(LHash, subsectors[LIndex].flags);
  end;
  LParts[6] := LHash;

  LHash := Mix(TGlFnv.Start, numnodes);
  for LIndex := 0 to numnodes - 1 do
    LHash := TGlFnv.UpdateBuffer(LHash, @nodes[LIndex], SizeOf(node_t));
  LParts[7] := LHash;

  Result := Format('verts=%d sectors=%d lines=%d segs=%d ss=%d nodes=%d gl=%s loops=%s secflags=%s lineflags=%s vtx=%s segs=%s ss=%s nodes=%s',
    [GPreCount, numsectors, numlines, numsegs, numsubsectors, numnodes, TGlFnv.ToHex(LParts[0]),
     TGlFnv.ToHex(LParts[1]), TGlFnv.ToHex(LParts[2]), TGlFnv.ToHex(LParts[3]), TGlFnv.ToHex(LParts[4]),
     TGlFnv.ToHex(LParts[5]), TGlFnv.ToHex(LParts[6]), TGlFnv.ToHex(LParts[7])]);
end;

procedure RunFingerprint(const ALoader: ILevelLoader; ASkill, APlayerMask: Integer);
var
  LEpisode, LMap: Integer;
  LName: string;
  LCandidates: array[0..1] of string;
  LCandidate: Integer;
begin
  for LEpisode := 1 to 5 do
    for LMap := 1 to 40 do
    begin
      if LMap <= 9 then
        LCandidates[0] := Format('E%dM%d', [LEpisode, LMap])
      else
        LCandidates[0] := '';
      if LEpisode = 1 then
        LCandidates[1] := Format('MAP%.2d', [LMap])
      else
        LCandidates[1] := '';
      for LCandidate := 0 to 1 do
      begin
        LName := LCandidates[LCandidate];
        if (LName <> '') and (W_CheckNumForName(LName) >= 0) and (GSeenMaps.IndexOf(LName) < 0) then
          ALoader.SetupLevel(LEpisode, LMap, APlayerMask, skill_t(ASkill));
      end;
    end;
  GFingerprint.SaveToFile(GFingerprintFile);
  Halt(0);
end;

procedure HarnessGl_AfterLevel(const AMapName: string; const ALoader: TObject; AEpisode, AMap, APlayerMask,
  ASkill: Integer);
var
  LLoader: ILevelLoader;
begin
  if GFingerprintFile <> '' then
  begin
    if GSeenMaps.IndexOf(AMapName) < 0 then
    begin
      GSeenMaps.Add(AMapName);
      GFingerprint.Add(AMapName + ' ' + FingerprintLevel);
    end;
    if not GFingerprintRunning then
    begin
      GFingerprintRunning := True;
      if Supports(ALoader, ILevelLoader, LLoader) then
        RunFingerprint(LLoader, ASkill, APlayerMask);
    end;
    Exit;
  end;
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
  Inc(GVirtualTic);
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
    if SameText(ParamStr(LIndex), '-glfingerprint') and (LIndex < ParamCount) and GL_RECORDER_COMPILED then
    begin
      GFingerprintFile := ParamStr(LIndex + 1);
      GFingerprint := TStringList.Create;
      GSeenMaps := TStringList.Create;
    end;
  end;
end;

initialization
  Initialize;

finalization
  GStream.Free;

end.
