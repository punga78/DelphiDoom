{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - the merge of two entries                    }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.Merger;

interface

uses
  DelphiDoom.MapInfo.Types, DelphiDoom.MapInfo.Intf;

type
  /// <summary>
  ///   Puts what a newer entry says over an older one (the old UpdateMapEntry): an empty
  ///   text, a zero or a False does not change anything. The next secret map is not merged,
  ///   as in the old code
  /// </summary>
  TMapInfoMerger = class
  public
    class procedure Update(var ATarget: TMapInfoEntry; const ANewer: TMapInfoEntry;
      const AMusic: IMapMusicResolver); static;
  end;

implementation

{ TMapInfoMerger }

class procedure TMapInfoMerger.Update(var ATarget: TMapInfoEntry; const ANewer: TMapInfoEntry;
  const AMusic: IMapMusicResolver);
begin
  if ANewer.MapName <> '' then
    ATarget.MapName := ANewer.MapName;
  if ANewer.LevelName <> '' then
    ATarget.LevelName := ANewer.LevelName;
  if ANewer.MapLabel <> '' then
    ATarget.MapLabel := ANewer.MapLabel;
  if ANewer.InterText <> '' then
    ATarget.InterText := ANewer.InterText;
  if ANewer.InterTextSecret <> '' then
    ATarget.InterTextSecret := ANewer.InterTextSecret;
  if ANewer.LevelPic <> '' then
    ATarget.LevelPic := ANewer.LevelPic;
  if ANewer.NextMap <> '' then
    ATarget.NextMap := ANewer.NextMap;
  if ANewer.Music <> '' then
  begin
    ATarget.Music := ANewer.Music;
    ATarget.MusicNumber := AMusic.MusicNumberFor(ATarget.Music);
  end;
  if ANewer.SkyTexture <> '' then
    ATarget.SkyTexture := ANewer.SkyTexture;
  if ANewer.SkyTexture2 <> '' then
    ATarget.SkyTexture2 := ANewer.SkyTexture2;
  if ANewer.EndPic <> '' then
    ATarget.EndPic := ANewer.EndPic;
  if ANewer.ExitPic <> '' then
    ATarget.ExitPic := ANewer.ExitPic;
  if ANewer.EnterPic <> '' then
    ATarget.EnterPic := ANewer.EnterPic;
  if ANewer.InterBackdrop <> '' then
    ATarget.InterBackdrop := ANewer.InterBackdrop;
  if ANewer.InterMusic <> '' then
  begin
    ATarget.InterMusic := ANewer.InterMusic;
    ATarget.InterMusicNumber := AMusic.MusicNumberFor(ATarget.InterMusic);
  end;
  if ANewer.ParTime <> 0 then
    ATarget.ParTime := ANewer.ParTime;
  if ANewer.Lightning then
    ATarget.Lightning := True;
  if ANewer.NoJump then
    ATarget.NoJump := True;
  if ANewer.NoCrouch then
    ATarget.NoCrouch := True;
  if ANewer.NoIntermission then
    ATarget.NoIntermission := True;
  if ANewer.SaysBossActions then
  begin
    ATarget.BossActionsCleared := ANewer.BossActionsCleared;
    ATarget.BossActions := Copy(ANewer.BossActions);
  end;
end;

end.
