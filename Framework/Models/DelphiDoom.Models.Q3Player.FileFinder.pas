{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the files of a     }
{  player                                                                      }
{                                                                              }
{  Port of CG_FileExists, CG_FindClientModelFile and CG_FindClientHeadFile of  }
{  cgame\cg_players.c. Based on the Quake III Arena GPL Source Code (id        }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.FileFinder;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>
  ///   The search order of the original: with a team folder first, then without; the files of the
  ///   team ("_red", "_blue") in a team game, "_default" otherwise; the folder "characters/" (or
  ///   "heads/") after the plain one. A file counts only if it is longer than 0 bytes. The names are
  ///   cut at 63 characters (the buffer of the original, with its warning). ALog may be nil.
  /// </summary>
  TQ3PlayerFileFinder = class(TInterfacedObject, IQ3PlayerFileFinder)
  strict private
    FProbe: IQ3FileProbe;
    FLog: ILog;
    function TeamWord(const AContext: TQ3TeamContext): AnsiString;
    function MakePath(const APath: string): AnsiString;
    function Exists(const AFileName: AnsiString): Boolean;
  public
    constructor Create(const AProbe: IQ3FileProbe; const ALog: ILog);
    function FindModelFile(const AContext: TQ3TeamContext; const ATeamName, AModelName, ASkinName,
      ABase, AExtension: AnsiString; out AFileName: AnsiString): Boolean;
    function FindHeadFile(const AContext: TQ3TeamContext; const ATeamName, AHeadModelName,
      AHeadSkinName, ABase, AExtension: AnsiString; out AFileName: AnsiString): Boolean;
  end;

implementation

constructor TQ3PlayerFileFinder.Create(const AProbe: IQ3FileProbe; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AProbe) then
    raise EArgumentNilException.Create('AProbe');
  FProbe := AProbe;
  FLog := ALog;
end;

function TQ3PlayerFileFinder.TeamWord(const AContext: TQ3TeamContext): AnsiString;
begin
  if AContext.TeamGame then
  begin
    // any team that is not blue is red, the spectators too
    if AContext.Team = qtBlue then
      Result := 'blue'
    else
      Result := 'red';
  end
  else
    Result := 'default';
end;

// Com_sprintf into a buffer of MAX_QPATH bytes
function TQ3PlayerFileFinder.MakePath(const APath: string): AnsiString;
begin
  Result := AnsiString(APath);
  if Length(Result) >= Q3_MAX_QPATH then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SQ3PathOverflow, [Length(Result), Q3_MAX_QPATH]));
    SetLength(Result, Q3_MAX_QPATH - 1);
  end;
end;

function TQ3PlayerFileFinder.Exists(const AFileName: AnsiString): Boolean;
begin
  Result := FProbe.FileLength(string(AFileName)) > 0;
end;

function TQ3PlayerFileFinder.FindModelFile(const AContext: TQ3TeamContext; const ATeamName,
  AModelName, ASkinName, ABase, AExtension: AnsiString; out AFileName: AnsiString): Boolean;
var
  LTeam, LFolder: string;
  LPass: Integer;
  LWithTeamName: Boolean;
begin
  LTeam := string(TeamWord(AContext));
  LFolder := '';
  AFileName := '';
  while True do
  begin
    for LPass := 0 to 1 do
    begin
      LWithTeamName := (LPass = 0) and (ATeamName <> '');
      if LWithTeamName then
        AFileName := MakePath(Format('models/players/%s%s/%s%s_%s_%s.%s', [LFolder, string(AModelName),
          string(ATeamName), string(ABase), string(ASkinName), LTeam, string(AExtension)]))
      else
        AFileName := MakePath(Format('models/players/%s%s/%s_%s_%s.%s', [LFolder, string(AModelName),
          string(ABase), string(ASkinName), LTeam, string(AExtension)]));
      if Exists(AFileName) then
        Exit(True);
      if AContext.TeamGame then
      begin
        if LWithTeamName then
          AFileName := MakePath(Format('models/players/%s%s/%s%s_%s.%s', [LFolder, string(AModelName),
            string(ATeamName), string(ABase), LTeam, string(AExtension)]))
        else
          AFileName := MakePath(Format('models/players/%s%s/%s_%s.%s', [LFolder, string(AModelName),
            string(ABase), LTeam, string(AExtension)]));
      end
      else
      begin
        if LWithTeamName then
          AFileName := MakePath(Format('models/players/%s%s/%s%s_%s.%s', [LFolder, string(AModelName),
            string(ATeamName), string(ABase), string(ASkinName), string(AExtension)]))
        else
          AFileName := MakePath(Format('models/players/%s%s/%s_%s.%s', [LFolder, string(AModelName),
            string(ABase), string(ASkinName), string(AExtension)]));
      end;
      if Exists(AFileName) then
        Exit(True);
      if ATeamName = '' then
        Break;
    end;
    // if tried the characters folder first
    if LFolder <> '' then
      Break;
    LFolder := 'characters/';
  end;
  Result := False;
end;

function TQ3PlayerFileFinder.FindHeadFile(const AContext: TQ3TeamContext; const ATeamName,
  AHeadModelName, AHeadSkinName, ABase, AExtension: AnsiString; out AFileName: AnsiString): Boolean;
var
  LTeam, LFolder, LModel: string;
  LPass: Integer;
  LWithTeamName: Boolean;
begin
  LTeam := string(TeamWord(AContext));
  LModel := string(AHeadModelName);
  if (LModel <> '') and (LModel[1] = '*') then
  begin
    LFolder := 'heads/';
    Delete(LModel, 1, 1);
  end
  else
    LFolder := '';
  AFileName := '';
  while True do
  begin
    for LPass := 0 to 1 do
    begin
      LWithTeamName := (LPass = 0) and (ATeamName <> '');
      if LWithTeamName then
        AFileName := MakePath(Format('models/players/%s%s/%s/%s%s_%s.%s', [LFolder, LModel,
          string(AHeadSkinName), string(ATeamName), string(ABase), LTeam, string(AExtension)]))
      else
        AFileName := MakePath(Format('models/players/%s%s/%s/%s_%s.%s', [LFolder, LModel,
          string(AHeadSkinName), string(ABase), LTeam, string(AExtension)]));
      if Exists(AFileName) then
        Exit(True);
      if AContext.TeamGame then
      begin
        if LWithTeamName then
          AFileName := MakePath(Format('models/players/%s%s/%s%s_%s.%s', [LFolder, LModel,
            string(ATeamName), string(ABase), LTeam, string(AExtension)]))
        else
          AFileName := MakePath(Format('models/players/%s%s/%s_%s.%s', [LFolder, LModel,
            string(ABase), LTeam, string(AExtension)]));
      end
      else
      begin
        if LWithTeamName then
          AFileName := MakePath(Format('models/players/%s%s/%s%s_%s.%s', [LFolder, LModel,
            string(ATeamName), string(ABase), string(AHeadSkinName), string(AExtension)]))
        else
          AFileName := MakePath(Format('models/players/%s%s/%s_%s.%s', [LFolder, LModel,
            string(ABase), string(AHeadSkinName), string(AExtension)]));
      end;
      if Exists(AFileName) then
        Exit(True);
      if ATeamName = '' then
        Break;
    end;
    // if tried the heads folder first
    if LFolder <> '' then
      Break;
    LFolder := 'heads/';
  end;
  Result := False;
end;

end.
