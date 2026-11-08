{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the screenshots of the game over Libs\Screenshot       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Screenshot.Service;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Screenshot.Intf,
  DelphiDoom.Engine.Screenshot.Intf;

type
  /// <summary>
  ///   M_ScreenShot and M_FixScreenshotFormat of the old m_misc.pas: the screen is read once with
  ///   I_ReadScreen32 and given to the writer of Libs\Screenshot, which chooses the names and the
  ///   encoders (and the copy in JPEG of the option mirrorjpgsshot)
  /// </summary>
  TEngineScreenshotService = class(TInterfacedObject, IEngineScreenshot)
  strict private
    FWriter: IScreenshotWriter;
    FTargets: IScreenshotTargets;
    FSaveFileNames: ISaveFileNames;
  public
    /// <param name="ASaveFileNames">Where the folder DATA goes (the working folder of the CD-ROM when needed)</param>
    /// <remarks>Raises EArgumentNilException if one of them is nil</remarks>
    constructor Create(const AWriter: IScreenshotWriter; const ATargets: IScreenshotTargets;
      const ASaveFileNames: ISaveFileNames);
    procedure Take(const AFileName: string = ''; const ASilent: Boolean = False);
    procedure FixFormat;
  end;

implementation

uses
  d_delphi,
  doomdef,
{$IFDEF DOOM}
  doomstat,
{$ENDIF}
  d_player,
  g_game,
  d_main,
  m_base,
  m_misc,
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  i_video,
{$ENDIF}
  DelphiDoom.Screenshot.Types,
  DelphiDoom.Screenshot.Formats;

const
  SWriterIsNil = 'TEngineScreenshotService: the writer is nil';
  STargetsIsNil = 'TEngineScreenshotService: the names of the files are nil';
  SSaveFileNamesIsNil = 'TEngineScreenshotService: the names of the saved files are nil';
  SScreenshotFailed = 'Couldn''t create a screenshot';
  SScreenshotDone = 'screen shot';

{ TEngineScreenshotService }

constructor TEngineScreenshotService.Create(const AWriter: IScreenshotWriter;
  const ATargets: IScreenshotTargets; const ASaveFileNames: ISaveFileNames);
begin
  inherited Create;
  if not Assigned(AWriter) then
    raise EArgumentNilException.Create(SWriterIsNil);
  if not Assigned(ATargets) then
    raise EArgumentNilException.Create(STargetsIsNil);
  if not Assigned(ASaveFileNames) then
    raise EArgumentNilException.Create(SSaveFileNamesIsNil);
  FWriter := AWriter;
  FTargets := ATargets;
  FSaveFileNames := ASaveFileNames;
end;

procedure TEngineScreenshotService.FixFormat;
begin
  trimprocU(screenshotformat);
  if CharPos('.', screenshotformat) = 1 then
    Delete(screenshotformat, 1, 1);
  if screenshotformat = '' then
  begin
    screenshotformat := 'PNG';
    Exit;
  end;
  if screenshotformat <> 'PNG' then
    if screenshotformat <> 'JPG' then
      if screenshotformat <> 'TGA' then
        screenshotformat := 'PNG';
end;

procedure TEngineScreenshotService.Take(const AFileName: string = ''; const ASilent: Boolean = False);
var
  LTarget: TScreenshotTarget;
  LFormat: TScreenshotFormat;
  LBuffer: TBytes;
  LGame: string;
  LSaved: Boolean;
  LFolder: string;
  LDate: TDateTime;
  LStamp: string;
begin
  FixFormat;
  LFolder := FSaveFileNames.ResolveName('DATA');
  MkDir(LFolder);
  MkDir(LFolder + '\SCREENSHOTS');
  MkDir(LFolder + '\SCREENSHOTS\TGA');
  MkDir(LFolder + '\SCREENSHOTS\JPG');
  MkDir(LFolder + '\SCREENSHOTS\PNG');
  if AFileName = '' then
  begin
{$IFDEF DOOM}
    if customgame in [cg_chex, cg_chex2] then
      LGame := 'CHEX'
    else if customgame = cg_hacx then
      LGame := 'HACX'
    else
{$ENDIF}
    LGame := _GAME;

    LDate := NowTime;
    LStamp := formatDateTimeAsString('yyyymmdd', LDate) + '_' + formatDateTimeAsString('hhnnsszzz', LDate);

    TScreenshotFormats.TryParse(screenshotformat, LFormat);
    LTarget := FTargets.ForGenerated(LGame, LStamp, LFormat);
  end
  else
    LTarget := FTargets.ForFileName(AFileName);

  SetLength(LBuffer, SCREENWIDTH * SCREENHEIGHT * 4);
  I_ReadScreen32(Pointer(LBuffer));
  LSaved := FWriter.Save(LTarget, Pointer(LBuffer), SCREENWIDTH, SCREENHEIGHT,
    {$IFDEF OPENGL}True{$ELSE}False{$ENDIF}, mirrorjpgsshot);

  if not ASilent then
  begin
    if LSaved then
      players[consoleplayer]._message := SScreenshotDone
    else
      players[consoleplayer]._message := SScreenshotFailed;
  end;
end;

end.
