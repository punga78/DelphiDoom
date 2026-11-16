{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the video, the lumps and the font of the overlay       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The only class that reads the video buffers, the palette, the lumps, the    }
{  font and the level time for the overlay drawer of the scripts, and that    }
{  puts the overlay over a frame (with the threads of the engine).             }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Overlay.Canvas;

interface

uses
  DelphiDoom.ScriptHost.Overlay.Intf,
  DelphiDoom.ScriptHost.Overlay.Types;

type
  /// <summary>The overlay canvas of the game: v_video, r_hires, w_wad, hu_stuff and the level time</summary>
  TEngineOverlayCanvas = class(TInterfacedObject, IOverlayCanvas)
  public
    function ScreenWidth: Integer;
    function ScreenHeight: Integer;
    function LevelTime: Integer;
    function FindColorIndex(const ARed, AGreen, ABlue: Byte): Byte;
    function FindPatchLump(const AName: string): Integer;
    function CachePatch(const ALump: Integer): Pointer;
    function FontPatch(const AChar: Char): Pointer;
    function IsFirstInterpolation: Boolean;
    procedure Warning(const AText: string);
    procedure MarkScreenDirty;
    procedure Flash(const AData: TOverlayFlashData);
  end;

implementation

uses
  d_net,
  hu_stuff,
  i_system,
  i_threads,
  mt_utils,
  p_tick,
  r_defs,
{$IFNDEF OPENGL}
  r_hires,
{$ENDIF}
  v_data,
  v_video,
  w_wad,
  z_zone;

type
  /// <summary>The part of the overlay that a thread flashes: the pixels from Start to Finish</summary>
  TOverlayFlashPart = record
    Data: POverlayFlashData;
    Start: Integer;
    Finish: Integer;
  end;
  POverlayFlashPart = ^TOverlayFlashPart;

{$IFNDEF OPENGL}

// the 8 bit screen: the pixels of the overlay that are not 0 replace those of the frame
function OverlayFlashThread8(AParameter: Pointer): Integer; stdcall;
var
  AParameters: POverlayFlashPart;
  LDestination: PByte;
  LSource: PByte;
  LStart, LFinish: Integer;
  LValue: Byte;
  LLookup: POverlayLookup;
begin
  Result := 0;
  AParameters := AParameter;
  // read once: the loop runs for every pixel of the screen that the overlay covers
  LLookup := AParameters.Data.Lookup;

  LStart := AParameters.Data.FirstLookup[AParameters.Start];
  LDestination := @screens[SCN_FG][LStart];

  LFinish := AParameters.Data.LastLookup[AParameters.Finish];

  repeat
    LSource := LLookup[LStart];
    if PLongWord(LSource)^ = 0 then
    begin
      Inc(LStart, 4);
      Inc(LDestination, 4);
    end
    else
    begin
      LValue := LSource^;
      if LValue <> 0 then
        LDestination^ := LValue;
      Inc(LStart);
      Inc(LDestination);
    end;
  until LStart > LFinish;
end;
{$ENDIF}

// the 32 bit screen: the colors of the palette for the pixels of the overlay that are not 0
function OverlayFlashThread32(AParameter: Pointer): Integer; stdcall;
var
  AParameters: POverlayFlashPart;
  LDestination: PLongWord;
  LSource: PByte;
  LStart, LFinish: Integer;
  LValue: Byte;
  LLookup: POverlayLookup;
begin
  Result := 0;
  AParameters := AParameter;
  // read once: the loop runs for every pixel of the screen that the overlay covers
  LLookup := AParameters.Data.Lookup;

  LStart := AParameters.Data.FirstLookup[AParameters.Start];
  LDestination := @screen32[LStart];

  LFinish := AParameters.Data.LastLookup[AParameters.Finish];

  repeat
    LSource := LLookup[LStart];
    if PLongWord(LSource)^ = 0 then
    begin
      Inc(LStart, 4);
      Inc(LDestination, 4);
    end
    else
    begin
      LValue := LSource^;
      if LValue <> 0 then
        LDestination^ := videopal[LValue];
      Inc(LStart);
      Inc(LDestination);
    end;
  until LStart > LFinish;
end;

// the overlay is flashed by the threads of the engine when it covers more than 8 rows of 320 pixels
procedure FlashParts(const AData: TOverlayFlashData; const AThread: threadfunc_t);
var
  LParts: array[0..16] of TOverlayFlashPart;
  LThread: threadfunc_t;
  I: Integer;
  LThreads: Integer;
  LSize: Integer;
begin
  LThread := AThread;
  LSize := AData.Finish - AData.Start;
  if usemultithread and (LSize > 8 * 320) then
  begin
    LThreads := I_GetNumCPUs;
    if LThreads < 2 then
      LThreads := 2
    else if LThreads > 17 then
      LThreads := 17;
    LSize := LSize div LThreads;
    LParts[0].Data := @AData;
    LParts[0].Start := AData.Start;
    for I := 1 to LThreads - 1 do
    begin
      LParts[I].Data := @AData;
      LParts[I - 1].Finish := AData.Start + LSize * I;
      LParts[I].Start := LParts[I - 1].Finish + 1;
    end;
    LParts[LThreads - 1].Finish := AData.Finish;
    case LThreads of
      2:
        MT_Execute(
          LThread, @LParts[0],
          LThread, @LParts[1]
        );
      3:
        MT_Execute(
          LThread, @LParts[0],
          LThread, @LParts[1],
          LThread, @LParts[2]
        );
      4:
        MT_Execute4(
          LThread, @LParts[0],
          LThread, @LParts[1],
          LThread, @LParts[2],
          LThread, @LParts[3]
        );
      5:
        MT_Execute(
          LThread, @LParts[0],
          LThread, @LParts[1],
          LThread, @LParts[2],
          LThread, @LParts[3],
          LThread, @LParts[4]
        );
      6:
        MT_Execute6(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5]
        );
      7:
        MT_Execute(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6]
        );
      8:
        MT_Execute8(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7]
        );
      9:
        MT_Execute(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8]
        );
     10:
        MT_Execute(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8],
         LThread, @LParts[9]
        );
     11:
        MT_Execute(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8],
         LThread, @LParts[9],
         LThread, @LParts[10]
        );
     12:
        MT_Execute12(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8],
         LThread, @LParts[9],
         LThread, @LParts[10],
         LThread, @LParts[11]
        );
     13:
        MT_Execute(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8],
         LThread, @LParts[9],
         LThread, @LParts[10],
         LThread, @LParts[11],
         LThread, @LParts[12]
        );
     14:
        MT_Execute(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8],
         LThread, @LParts[9],
         LThread, @LParts[10],
         LThread, @LParts[11],
         LThread, @LParts[12],
         LThread, @LParts[13]
        );
     15:
        MT_Execute(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8],
         LThread, @LParts[9],
         LThread, @LParts[10],
         LThread, @LParts[11],
         LThread, @LParts[12],
         LThread, @LParts[13],
         LThread, @LParts[14]
        );
     16:
        MT_Execute16(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8],
         LThread, @LParts[9],
         LThread, @LParts[10],
         LThread, @LParts[11],
         LThread, @LParts[12],
         LThread, @LParts[13],
         LThread, @LParts[14],
         LThread, @LParts[15]
        );
      else
        MT_Execute(
         LThread, @LParts[0],
         LThread, @LParts[1],
         LThread, @LParts[2],
         LThread, @LParts[3],
         LThread, @LParts[4],
         LThread, @LParts[5],
         LThread, @LParts[6],
         LThread, @LParts[7],
         LThread, @LParts[8],
         LThread, @LParts[9],
         LThread, @LParts[10],
         LThread, @LParts[11],
         LThread, @LParts[12],
         LThread, @LParts[13],
         LThread, @LParts[14],
         LThread, @LParts[15],
         LThread, @LParts[16]
        );
    end;
  end
  else
  begin
    LParts[0].Data := @AData;
    LParts[0].Start := AData.Start;
    LParts[0].Finish := AData.Finish;
    LThread(@LParts[0]);
  end;
end;

{ TEngineOverlayCanvas }

function TEngineOverlayCanvas.ScreenWidth: Integer;
begin
  Result := V_GetScreenWidth(SCN_FG);
end;

function TEngineOverlayCanvas.ScreenHeight: Integer;
begin
  Result := V_GetScreenHeight(SCN_FG);
end;

function TEngineOverlayCanvas.LevelTime: Integer;
begin
  // qualified: a method with the name of a global hides the global
  Result := p_tick.leveltime;
end;

function TEngineOverlayCanvas.FindColorIndex(const ARed, AGreen, ABlue: Byte): Byte;
begin
  Result := Byte(V_FindAproxColorIndex(@videopal,
    LongWord(ABlue) or (LongWord(AGreen) shl 8) or (LongWord(ARed) shl 16)));
end;

function TEngineOverlayCanvas.FindPatchLump(const AName: string): Integer;
begin
  Result := W_CheckNumForName(AName, TYPE_PATCH or TYPE_SPRITE);
end;

function TEngineOverlayCanvas.CachePatch(const ALump: Integer): Pointer;
begin
  Result := W_CacheLumpNum(ALump, PU_STATIC);
end;

function TEngineOverlayCanvas.FontPatch(const AChar: Char): Pointer;
begin
  if (AChar >= HU_FONTSTART) and
     (AChar <= {$IFDEF DOOM_OR_STRIFE}HU_FONTEND{$ELSE}HU_CFONTEND{$ENDIF}) then
    Result := {$IFDEF DOOM_OR_STRIFE}hu_font{$ELSE}hu_font3{$ENDIF}[Ord(AChar) - Ord(HU_FONTSTART)]
  else
    Result := nil;
end;

function TEngineOverlayCanvas.IsFirstInterpolation: Boolean;
begin
  Result := d_net.firstinterpolation;
end;

procedure TEngineOverlayCanvas.Warning(const AText: string);
begin
  I_Warning(AText);
end;

procedure TEngineOverlayCanvas.MarkScreenDirty;
begin
  r_defs.needsbackscreen := True;
end;

procedure TEngineOverlayCanvas.Flash(const AData: TOverlayFlashData);
begin
{$IFDEF OPENGL}
  FlashParts(AData, @OverlayFlashThread32);
{$ELSE}
  if videomode = vm32bit then
    FlashParts(AData, @OverlayFlashThread32)
  else
    FlashParts(AData, @OverlayFlashThread8);
{$ENDIF}
end;

end.
