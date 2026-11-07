{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the end screen over Libs\Endoom                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Endoom.Screen;

interface

uses
  System.SysUtils,
  d_delphi,
  d_event,
  DelphiDoom.Endoom.Intf,
  DelphiDoom.Engine.Endoom.Intf;

type
  /// <summary>
  ///   E_Init, E_Drawer, E_Ticker, E_Responder and E_ShutDown of the old e_endoom.pas: the
  ///   bytes of the lump, of DOSFONT and the palette come from the WAD and the video of the
  ///   engine, the picture from the renderer of Libs\Endoom and the time from its session
  /// </summary>
  TEngineEndoomScreen = class(TInterfacedObject, IEngineEndoomScreen)
  private
    FRenderer: IEndoomRenderer;
    FSession: IEndoomSession;
    FLumpName: TFunc<string>;
    FScreen: TBytes;
    FFont: TBytes;
    FColors: TBytes;
{$IFDEF OPENGL}
    FScreen32: TArray<Cardinal>;
    FPixels32: PLongWordArray;
{$ENDIF}
    procedure SetGamePalette;
  public
    /// <param name="ALumpName">The name of the lump, asked when it is drawn (DEHACKED can change it)</param>
    /// <remarks>Raises EArgumentNilException if one of them is nil</remarks>
    constructor Create(const ARenderer: IEndoomRenderer; const ASession: IEndoomSession;
      const ALumpName: TFunc<string>);
    procedure Initialize;
    procedure Draw;
    procedure Tick;
    function Respond(const AEvent: Pevent_t): Boolean;
    procedure Shutdown;
    function Pixels32: PLongWordArray;
  end;

implementation

uses
  doomdef,
  DelphiDoom.Endoom.Types,
  i_system,
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  i_video,
{$ENDIF}
  v_data,
  v_video,
  w_wad,
  z_zone;

const
  SRendererIsNil = 'TEngineEndoomScreen: the renderer is nil';
  SSessionIsNil = 'TEngineEndoomScreen: the session is nil';
  SLumpNameIsNil = 'TEngineEndoomScreen: the name of the lump is nil';

{ TEngineEndoomScreen }

constructor TEngineEndoomScreen.Create(const ARenderer: IEndoomRenderer;
  const ASession: IEndoomSession; const ALumpName: TFunc<string>);
begin
  inherited Create;
  if not Assigned(ARenderer) then
    raise EArgumentNilException.Create(SRendererIsNil);
  if not Assigned(ASession) then
    raise EArgumentNilException.Create(SSessionIsNil);
  if not Assigned(ALumpName) then
    raise EArgumentNilException.Create(SLumpNameIsNil);
  FRenderer := ARenderer;
  FSession := ASession;
  FLumpName := ALumpName;
end;

procedure TEngineEndoomScreen.SetGamePalette;
var
  LPalette: PByteArray;
begin
  LPalette := V_ReadPalette(PU_STATIC);
  V_SetPalette(LPalette);
  I_SetPalette(LPalette);
  Z_ChangeTag(LPalette, PU_CACHE);
end;

procedure TEngineEndoomScreen.Initialize;
var
  LFontLump: Integer;
  LIndex: Integer;
  LSource: Pointer;
begin
  FSession.Start;
  LFontLump := W_CheckNumForName('DOSFONT');
  if LFontLump >= 0 then
  begin
    SetLength(FFont, W_LumpLength(LFontLump));
    if Length(FFont) > 0 then
    begin
      LSource := W_CacheLumpNum(LFontLump, PU_STATIC);
      Move(LSource^, FFont[0], Length(FFont));
      Z_ChangeTag(LSource, PU_CACHE);
    end;
  end
  else
  begin
    I_Warning('E_Init(): Can not find DOSFONT lump'#13#10);
    SetLength(FFont, 0);
  end;

  SetGamePalette;

  SetLength(FColors, ENDOOM_COLOR_COUNT);
  for LIndex := 0 to ENDOOM_COLOR_COUNT - 1 do
    FColors[LIndex] := V_FindAproxColorIndex(@curpal, ENDOOM_COLORS[LIndex]);
end;

procedure TEngineEndoomScreen.Draw;
var
  LLump: Integer;
  LData: TBytes;
  LSource: Pointer;
{$IFDEF OPENGL}
  LIndex: Integer;
  LPalette: array[0..ENDOOM_PALETTE_SIZE - 1] of Cardinal;
{$ENDIF}
begin
  SetGamePalette;

  if FSession.NeedsRedraw then
  begin
    LLump := W_GetNumForName(FLumpName());
    SetLength(LData, W_LumpLength(LLump));
    if Length(LData) > 0 then
    begin
      LSource := W_CacheLumpNum(LLump, PU_STATIC);
      Move(LSource^, LData[0], Length(LData));
      Z_ChangeTag(LSource, PU_CACHE);
    end;
    FRenderer.RenderIndexed(LData, FFont, FColors, FSession.IsBlinkVisible, FScreen);
    FSession.Drawn;
  end;

{$IFDEF OPENGL}
  // the texture is 1024x256: the renderer fills the first 200 rows, the rest stays at zero
  if Length(FScreen32) = 0 then
    SetLength(FScreen32, ENDOOM_TEXTURE_WIDTH * ENDOOM_TEXTURE_HEIGHT);
  for LIndex := 0 to ENDOOM_PALETTE_SIZE - 1 do
    LPalette[LIndex] := videopal[LIndex];
  FRenderer.ConvertToRgb32(FScreen, LPalette, ENDOOM_TEXTURE_WIDTH, FScreen32);
  FPixels32 := PLongWordArray(@FScreen32[0]);
{$ELSE}
  V_CopyCustomScreen(PByteArray(@FScreen[0]), ENDOOM_WIDTH, ENDOOM_HEIGHT, SCN_FG);
{$ENDIF}
end;

procedure TEngineEndoomScreen.Tick;
begin
  if FSession.Tick then
    I_Quit;
end;

function TEngineEndoomScreen.Respond(const AEvent: Pevent_t): Boolean;
begin
  if AEvent._type <> ev_keyup then
  begin
    Result := False;
    Exit;
  end;

  if gamestate = GS_ENDOOM then
  begin
    Result := FSession.AcceptsKey;
    if Result then
      I_Quit;
  end
  else
    Result := False;
end;

procedure TEngineEndoomScreen.Shutdown;
begin
  SetLength(FScreen, 0);
  SetLength(FFont, 0);
{$IFDEF OPENGL}
  FPixels32 := nil;
  SetLength(FScreen32, 0);
{$ENDIF}
end;

function TEngineEndoomScreen.Pixels32: PLongWordArray;
begin
{$IFDEF OPENGL}
  Result := FPixels32;
{$ELSE}
  Result := nil;
{$ENDIF}
end;

end.
