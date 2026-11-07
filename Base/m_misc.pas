//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Main loop menu stuff.
//  Default Config File.
//  Screenshots.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_misc;

interface

uses
  DelphiDoom.Configuration.Intf,
  DelphiDoom.Platform.Intf,
  DelphiDoom.Screenshot.Intf;

//
// MISC
//

var
  screenshotformat: string = 'PNG';
  // write a JPEG file next to the TGA or PNG one
  mirrorjpgsshot: Boolean = True;

//==============================================================================
//
// M_WriteFile
//
//==============================================================================
function M_WriteFile(const name: string; source: pointer; len: integer): boolean;

//==============================================================================
//
// M_AppendFile
//
//==============================================================================
function M_AppendFile(const name: string; source: pointer; len: integer): integer;

//==============================================================================
//
// M_ReadFile
//
//==============================================================================
function M_ReadFile(const name: string; var buffer: Pointer): integer;

//==============================================================================
//
// M_ConfigureFiles
// Gives the unit the store of whole files behind M_WriteFile, M_AppendFile and M_ReadFile.
// The composition root calls it
//
//==============================================================================
procedure M_ConfigureFiles(const AStore: IFileStore);

//==============================================================================
//
// M_FixScreenshotFormat
//
//==============================================================================
procedure M_FixScreenshotFormat;

//==============================================================================
//
// M_ScreenShot
//
//==============================================================================
procedure M_ScreenShot(const filename: string = ''; const silent: boolean = false);

//==============================================================================
//
// M_ConfigureScreenshot
//
//==============================================================================
procedure M_ConfigureScreenshot(const AWriter: IScreenshotWriter;
  const ATargets: IScreenshotTargets);

//==============================================================================
//
// M_SetDefaults
//
//==============================================================================
procedure M_SetDefaults;

//==============================================================================
//
// M_SetDefault
//
//==============================================================================
procedure M_SetDefault(const parm: string);

//==============================================================================
//
// M_LoadDefaults
//
//==============================================================================
procedure M_LoadDefaults;

//==============================================================================
//
// M_SaveDefaults
//
//==============================================================================
procedure M_SaveDefaults;

//==============================================================================
//
// M_ConfigureDefaults
// Gives the unit the format of the configuration file. The composition root calls it
//
//==============================================================================
procedure M_ConfigureDefaults(const AFormat: IConfigurationFormat);


//==============================================================================
//
// M_ForceDefaultBoolean
//
//==============================================================================
function M_ForceDefaultBoolean(const name: string; const value: boolean): boolean;

//==============================================================================
//
// M_ForceDefaultInteger
//
//==============================================================================
function M_ForceDefaultInteger(const name: string; const value: integer): boolean;

//==============================================================================
//
// M_ForceDefaultString
//
//==============================================================================
function M_ForceDefaultString(const name: string; const value: string): boolean;

var
  yesnoStrings: array[boolean] of string = ('NO', 'YES');
  truefalseStrings: array[boolean] of string = ('FALSE', 'TRUE');
  confignotfound: Boolean = true;

implementation

uses
  System.SysUtils,
  d_delphi,
  c_cmds,
  doomdef,
  {$IFDEF  DOOM}
  doomstat,
  {$ENDIF}
  d_main,
  d_player,
  g_game,
  m_argv,
  m_base,
  m_defs,
  i_system,
  DelphiDoom.Screenshot.Types,
  DelphiDoom.Screenshot.Formats,
{$IFDEF OPENGL}
  gl_main,
  gl_defs,
{$ELSE}
  i_video,
{$ENDIF}
  z_zone,
  DelphiDoom.Platform.Types;

var
  // given by the composition root (M_ConfigureFiles)
  engine_files: IFileStore = nil;

//==============================================================================
//
// M_ConfigureFiles
//
//==============================================================================
procedure M_ConfigureFiles(const AStore: IFileStore);
begin
  engine_files := AStore;
end;

//==============================================================================
//
// M_FileStore
//
//==============================================================================
function M_FileStore: IFileStore;
begin
  if not Assigned(engine_files) then
    I_Error('The store of files was not given (M_ConfigureFiles)');
  Result := engine_files;
end;

//==============================================================================
//
// M_WriteFile
//
//==============================================================================
function M_WriteFile(const name: string; source: pointer; len: integer): boolean;
begin
  Result := M_FileStore.Write(name, source, len);
end;

//==============================================================================
//
// M_AppendFile
//
//==============================================================================
function M_AppendFile(const name: string; source: pointer; len: integer): integer;
begin
  Result := M_FileStore.Append(name, source, len);
end;

//==============================================================================
//
// M_ReadFile
//
//==============================================================================
function M_ReadFile(const name: string; var buffer: Pointer): integer;
var
  data: TBytes;
begin
  try
    data := M_FileStore.Read(name);
  except
    on EPlatformException do
      I_Error('M_ReadFile(): Could not read file %s', [name]);
  end;

  Result := Length(data);
  // JVAL
  // If Z_Malloc changed to malloc() a lot of changes must be made....
  buffer := Z_Malloc(Result, PU_STATIC, nil);
  if Result > 0 then
    Move(data[0], buffer^, Result);
end;

type
  TargaHeader = record
    id_length, colormap_type, image_type: byte;
    colormap_index, colormap_length: word;
    colormap_size: byte;
    x_origin, y_origin, width, height: word;
    pixel_size, attributes: byte;
  end;

const
  MSG_ERR_SCREENSHOT = 'Couldn''t create a screenshot';

var
  // given by the composition root (M_ConfigureScreenshot)
  screenshot_writer: IScreenshotWriter = nil;
  screenshot_targets: IScreenshotTargets = nil;

//==============================================================================
// M_FixScreenshotFormat
//
// M_ScreenShot
//
//==============================================================================
procedure M_FixScreenshotFormat;
begin
  trimprocU(screenshotformat);
  if CharPos('.', screenshotformat) = 1 then
    Delete(screenshotformat, 1, 1);
  if screenshotformat = '' then
  begin
    screenshotformat := 'PNG';
    exit;
  end;
  if screenshotformat <> 'PNG' then
    if screenshotformat <> 'JPG' then
      if screenshotformat <> 'TGA' then
        screenshotformat := 'PNG';
end;

//==============================================================================
//
// M_ConfigureScreenshot
//
//==============================================================================
procedure M_ConfigureScreenshot(const AWriter: IScreenshotWriter;
  const ATargets: IScreenshotTargets);
begin
  screenshot_writer := AWriter;
  screenshot_targets := ATargets;
end;

//==============================================================================
//
// M_ScreenShot
//
//==============================================================================
procedure M_ScreenShot(const filename: string = ''; const silent: boolean = false);
var
  target: TScreenshotTarget;
  shotformat: TScreenshotFormat;
  buffer: TBytes;
  gstr: string;
  ret: boolean;
  dir: string;
  date: TDateTime;
  dfmt: string;
begin
  if (screenshot_writer = nil) or (screenshot_targets = nil) then
    I_Error('M_ScreenShot(): the screenshots are not configured (M_ConfigureScreenshot)');

  M_FixScreenshotFormat;
  dir := M_SaveFileName('DATA');
  MkDir(dir);
  MkDir(dir + '\SCREENSHOTS');
  MkDir(dir + '\SCREENSHOTS\TGA');
  MkDir(dir + '\SCREENSHOTS\JPG');
  MkDir(dir + '\SCREENSHOTS\PNG');
  if filename = '' then
  begin
    {$IFDEF DOOM}
    if customgame in [cg_chex, cg_chex2] then
      gstr := 'CHEX'
    else if customgame = cg_hacx then
      gstr := 'HACX'
    else
    {$ENDIF}
    gstr := _GAME;

    date := NowTime;
    dfmt := formatDateTimeAsString('yyyymmdd', date) + '_' + formatDateTimeAsString('hhnnsszzz', date);

    TScreenshotFormats.TryParse(screenshotformat, shotformat);
    target := screenshot_targets.ForGenerated(gstr, dfmt, shotformat);
  end
  else
    target := screenshot_targets.ForFileName(filename);

  SetLength(buffer, SCREENWIDTH * SCREENHEIGHT * 4);
  I_ReadScreen32(Pointer(buffer));
  ret := screenshot_writer.Save(target, Pointer(buffer), SCREENWIDTH, SCREENHEIGHT,
    {$IFDEF OPENGL}True{$ELSE}False{$ENDIF}, mirrorjpgsshot);

  if not silent then
  begin
    if ret then
      players[consoleplayer]._message := 'screen shot'
    else
      players[consoleplayer]._message := MSG_ERR_SCREENSHOT;
  end;
end;

const
  VERFMT = 'ver %d.%.*d';

var
  defaultfile: string;

var
  // given by the composition root (M_ConfigureDefaults)
  config_format: IConfigurationFormat = nil;

//==============================================================================
//
// M_ConfigureDefaults
//
//==============================================================================
procedure M_ConfigureDefaults(const AFormat: IConfigurationFormat);
begin
  config_format := AFormat;
end;

//==============================================================================
//
// M_SaveDefaults
//
//==============================================================================
procedure M_SaveDefaults;
var
  i: integer;
  pd: Pdefault_t;
  s: TDStringList;
  writer: IConfigurationWriter;
  lines: TArray<string>;
begin
  if config_format = nil then
    exit;

  writer := config_format.CreateWriter(config_format.FormatHeader(AppTitle, D_EngineVersion));
  pd := @defaults[0];
  for i := 0 to NUMDEFAULTS - 1 do
  begin
    if pd._type = tInteger then
      writer.AddValue(pd.name, config_format.FormatInteger(PInteger(pd.location)^))
    else if pd._type = tString then
      writer.AddValue(pd.name, PString(pd.location)^)
    else if pd._type = tBoolean then
      writer.AddValue(pd.name, config_format.FormatBoolean(PBoolean(pd.location)^))
    else if pd._type = tGroup then
      writer.AddGroup(pd.name);
    inc(pd);
  end;

  s := TDStringList.Create;
  try
    lines := writer.Lines;
    for i := 0 to High(lines) do
      s.Add(lines[i]);
    s.SaveToFile(defaultfile);
  finally
    s.Free;
  end;
end;
//==============================================================================
//
// M_SetDefaults
//
//==============================================================================
procedure M_SetDefaults;
begin
  M_SetDefault('*');
end;

//==============================================================================
//
// M_SetDefault
//
//==============================================================================
procedure M_SetDefault(const parm: string);
var
  i: integer;
  def: string;
  parm1: string;
  pd: Pdefault_t;
  clist: TDStringList;
  rlist: TDStringList;
  setflags: byte;
begin
  // set parm1 to base value
  if parm = '' then
  begin
    printf('Please specify the variable to reset to default value'#13#10);
    exit;
  end;

  if netgame then
    setflags := DFS_NETWORK
  else
    setflags := DFS_SINGLEPLAYER;

  if CharPos('*', parm) > 0 then // Is a mask
  begin
    clist := TDStringList.Create;
    try
      pd := @defaults[0];
      for i := 0 to NUMDEFAULTS - 1 do
      begin
        if pd._type <> tGroup then
          clist.Add(pd.name);
        inc(pd);
      end;

      rlist := C_GetMachingList(clist, parm);
      try
        for i := 0 to rlist.Count - 1 do
          M_SetDefault(rlist[i]);
      finally
        rlist.Free;
      end;
    finally
      clist.Free;
    end;
    exit;
  end;

  def := strlower(parm);
  for i := 0 to NUMDEFAULTS - 1 do
    if defaults[i].name = def then
    begin
      if defaults[i].setable and setflags <> 0 then
      begin
        if defaults[i]._type = tInteger then
          PInteger(defaults[i].location)^ := defaults[i].defaultivalue
        else if defaults[i]._type = tBoolean then
          PBoolean(defaults[i].location)^ := defaults[i].defaultbvalue
        else if defaults[i]._type = tString then
          PString(defaults[i].location)^ := defaults[i].defaultsvalue
        else
          exit; // Ouch!
        printf('Setting default value for %s'#13#10, [parm]);
        C_ExecuteCmd('get', def); // Display the default value
      end
      else if C_CmdExists(def) then
      begin
        if defaults[i]._type = tInteger then
          parm1 := itoa(defaults[i].defaultivalue)
        else if defaults[i]._type = tBoolean then
          parm1 := yesnostrings[defaults[i].defaultbvalue]
        else if defaults[i]._type = tString then
          parm1 := defaults[i].defaultsvalue
        else
          exit; // Ouch!
        printf('Setting default value for %s'#13#10, [parm]);
        C_ExecuteCmd(def, parm1);
      end;
    end;
end;

//==============================================================================
//
// M_LoadDefaults
//
//==============================================================================
procedure M_LoadDefaults;
var
  i: integer;
  j: integer;
  idx: integer;
  pd: Pdefault_t;
  s: TDStringList;
  n: string;
  doc: IConfigurationDocument;
  lines: TArray<string>;
begin
  if config_format = nil then
    I_Error('M_LoadDefaults(): the configuration format was not given (M_ConfigureDefaults)');

  // set everything to base values
  for i := 0 to NUMDEFAULTS - 1 do
    if defaults[i]._type = tInteger then
      PInteger(defaults[i].location)^ := defaults[i].defaultivalue
    else if defaults[i]._type = tBoolean then
      PBoolean(defaults[i].location)^ := defaults[i].defaultbvalue
    else if defaults[i]._type = tString then
      PString(defaults[i].location)^ := defaults[i].defaultsvalue;

  if M_CheckParm('-defaultvalues') > 0 then
    exit;

  // check for a custom default file
  i := M_CheckParm('-config');
  if (i > 0) and (i < myargc - 1) then
  begin
    defaultfile := myargv[i + 1];
    printf(' default file: %s'#13#10, [defaultfile]);
  end
  else
    defaultfile := basedefault;

  s := TDStringList.Create;
  try
    // read the file in, overriding any set defaults
    if fexists(defaultfile) then
      s.LoadFromFile(defaultfile);

    if s.Count > 1 then
    begin
      SetLength(lines, s.Count);
      for i := 0 to s.Count - 1 do
        lines[i] := s[i];
      doc := config_format.Parse(lines);
      if config_format.AcceptsHeader(doc.Header, D_EngineVersion) then
      begin
        confignotfound := False;

        for i := 0 to doc.Count - 1 do
        begin
          idx := -1;
          n := doc.NameAt(i);
          for j := 0 to NUMDEFAULTS - 1 do
            if defaults[j].name = n then
            begin
              idx := j;
              break;
            end;

          if idx > -1 then
          begin
            pd := @defaults[idx];
            if pd._type = tInteger then
              PInteger(pd.location)^ := config_format.ParseInteger(doc.ValueOf(n))
            else if pd._type = tBoolean then
              PBoolean(pd.location)^ := config_format.ParseBoolean(doc.ValueOf(n))
            else if pd._type = tString then
              PString(pd.location)^ := doc.ValueOf(n);
          end;
        end;
      end;
    end;
  finally
    s.Free;
  end;
  {$IFNDEF STRIFE}
  if confignotfound then
    G_SetKeyboardMode(1);
  {$ENDIF}
  {$IFNDEF DEBUG}
  {$IFDEF OPENGL}
  gl_drawsky := true;
  {$ENDIF}
  {$ENDIF}
  defaultskill := GetIntegerInRange(defaultskill, Ord(sk_baby), Ord(sk_nightmare));
  startskill := skill_t(defaultskill);
  gameskill := startskill;
end;

//==============================================================================
//
// M_ForceDefaultBoolean
//
//==============================================================================
function M_ForceDefaultBoolean(const name: string; const value: boolean): boolean;
var
  i: integer;
  lname: string;
begin
  result := false;
  lname := strlower(name);
  for i := 0 to NUMDEFAULTS - 1 do
    if defaults[i]._type = tBoolean then
      if defaults[i].name = lname then
      begin
        if defaults[i].oldlocation = nil then
        begin
          defaults[i].oldlocation := defaults[i].location;
          defaults[i].defaultbvalue := PBoolean(defaults[i].location)^;
          PBoolean(defaults[i].location)^ := value;
          PBoolean(defaults[i].location) := @defaults[i].defaultbvalue;
          defaults[i].setable := DFS_NEVER;
        end
        else
          PBoolean(defaults[i].oldlocation)^ := value;
        result := true;
      end;
end;

//==============================================================================
//
// M_ForceDefaultInteger
//
//==============================================================================
function M_ForceDefaultInteger(const name: string; const value: integer): boolean;
var
  i: integer;
  lname: string;
begin
  result := false;
  lname := strlower(name);
  for i := 0 to NUMDEFAULTS - 1 do
    if defaults[i]._type = tInteger then
      if defaults[i].name = lname then
      begin
        if defaults[i].oldlocation = nil then
        begin
          defaults[i].oldlocation := defaults[i].location;
          defaults[i].defaultivalue := PInteger(defaults[i].location)^;
          PInteger(defaults[i].location)^ := value;
          PInteger(defaults[i].location) := @defaults[i].defaultivalue;
          defaults[i].setable := DFS_NEVER;
        end
        else
          PInteger(defaults[i].oldlocation)^ := value;
        result := true;
      end;
end;

//==============================================================================
//
// M_ForceDefaultString
//
//==============================================================================
function M_ForceDefaultString(const name: string; const value: string): boolean;
var
  i: integer;
  lname: string;
begin
  result := false;
  lname := strlower(name);
  for i := 0 to NUMDEFAULTS - 1 do
    if defaults[i]._type = tString then
      if defaults[i].name = lname then
      begin
        if defaults[i].oldlocation = nil then
        begin
          defaults[i].oldlocation := defaults[i].location;
          defaults[i].defaultsvalue := PString(defaults[i].location)^;
          PString(defaults[i].location)^ := value;
          PString(defaults[i].location) := @defaults[i].defaultsvalue;
          defaults[i].setable := DFS_NEVER;
        end
        else
          PString(defaults[i].oldlocation)^ := value;
        result := true;
      end;
end;

end.

