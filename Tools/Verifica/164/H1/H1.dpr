program H1;
// Harness of the golden files of Libs\ToolsCore: it runs the OLD ENDEDIT code (ee_filemenuhistory,
// ee_utils, ee_defs, ee_undo) on fixed scenarios and writes what it does.
{$APPTYPE CONSOLE}
uses
  Windows, SysUtils, Classes, ee_utils, ee_filemenuhistory, ee_defs, ee_undo;

var
  Out_: TStringList;
  State: string;

procedure Line(const s: string);
begin
  Out_.Add(s);
end;

procedure Mru;
const
  PATHS: array[0..15] of string = (
    'C:\a.bin', 'C:\b.bin', 'c:\A.BIN', 'D:\x\y\z.bin', '  ', '', ' C:\b.bin ', 'E:\1', 'E:\2', 'E:\3',
    'E:\4', 'E:\5', 'E:\6', 'E:\7', 'E:\8', 'E:\9');
  SCRIPTS: array[0..4] of string = (
    '0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15',
    '0 1 0 1 2 2 3 4 5 6 7 8 9 10 11 12 13 14 15 3 0',
    '4 5 6 4 4 4 15 14 13 12 11 10 9 8 7 6 5 0',
    '0 2 0 2 0 6 1 6 1 7',
    '15 14 13 12 11 10 9 8 7 3 4 5 6');
var
  h: TFileMenuHistory;
  sc, i, k: Integer;
  l: TStringList;
  s: string;
begin
  for sc := 0 to High(SCRIPTS) do
  begin
    h := TFileMenuHistory.Create(nil);
    l := TStringList.Create;
    l.Delimiter := ' ';
    l.DelimitedText := SCRIPTS[sc];
    for k := 0 to l.Count - 1 do
    begin
      h.AddPath(PATHS[StrToInt(l[k])]);
      s := '';
      for i := 0 to 9 do
        s := s + '|' + h.PathStringIdx(i);
      Line(Format('MRU %d.%d%s', [sc, k, s]));
    end;
    l.Free;
    h.Free;
  end;
end;

procedure Short;
var
  n: Integer;
  s: string;
begin
  s := '';
  for n := 0 to 60 do
  begin
    Line(Format('SHORT %d [%s]', [n, MkShortName(s)]));
    s := s + Chr(Ord('a') + (n mod 26));
  end;
end;

procedure SaveOldSettings(const title: string);
var
  fn: string;
  l: TStringList;
  i: Integer;
begin
  fn := ExtractFilePath(ParamStr(0)) + 'h1_settings.tmp';
  ee_SaveSettingsToFile(fn);
  l := TStringList.Create;
  l.LoadFromFile(fn);
  Line('SETTINGS ' + title);
  for i := 0 to l.Count - 1 do
    Line('| ' + l[i]);
  Line('END');
  l.Free;
  DeleteFile(fn);
end;

procedure LoadOldSettings(const title, text: string);
var
  fn: string;
  l: TStringList;
begin
  fn := ExtractFilePath(ParamStr(0)) + 'h1_settings_in.tmp';
  l := TStringList.Create;
  l.Text := text;
  l.SaveToFile(fn);
  l.Free;
  opt_showgrid := False;
  opt_zoom := 0;
  opt_textartmethod := 0;
  stringtobigstring('', @opt_filemenuhistory0);
  stringtobigstring('', @opt_filemenuhistory1);
  stringtobigstring('', @opt_filemenuhistory9);
  Line(Format('LOADRES %s %s', [title, BoolToStr(ee_LoadSettingFromFile(fn), True)]));
  Line(Format('LOAD %s grid=%d zoom=%d method=%d h0=[%s] h1=[%s] h9=[%s]', [title, Ord(opt_showgrid), opt_zoom,
    opt_textartmethod, bigstringtostring(@opt_filemenuhistory0), bigstringtostring(@opt_filemenuhistory1),
    bigstringtostring(@opt_filemenuhistory9)]));
  DeleteFile(fn);
end;

procedure Settings;
begin
  SaveOldSettings('defaults');
  opt_showgrid := True;
  opt_zoom := 7;
  opt_textartmethod := 3;
  stringtobigstring('C:\one.bin', @opt_filemenuhistory0);
  stringtobigstring('D:\dir with spaces\two.bin', @opt_filemenuhistory3);
  SaveOldSettings('changed');
  LoadOldSettings('plain', '[File Menu History]'#13#10'FILEMENUHISTORY0=C:\a.bin'#13#10'FILEMENUHISTORY1=C:\b.bin'#13#10#13#10'[Options]'#13#10'SHOWGRID=1'#13#10'ZOOM=12'#13#10'TEXTARTMETHOD=2'#13#10);
  LoadOldSettings('lowercase', 'showgrid = 1'#13#10'zoom=  5  '#13#10'textartmethod=4'#13#10'filemenuhistory9 = x:\y');
  LoadOldSettings('noval', 'SHOWGRID='#13#10'ZOOM=abc'#13#10'TEXTARTMETHOD=3'#13#10'FILEMENUHISTORY0='#13#10'# comment'#13#10'ZOOM=9=9');
  LoadOldSettings('dup', 'ZOOM=3'#13#10'ZOOM=4'#13#10'SHOWGRID=2');
end;

type
  TUndoTester = class
    FMan: TUndoRedoManager;
    procedure DoLoad(const s: TStream);
    procedure DoSave(const s: TStream);
  end;

procedure TUndoTester.DoLoad(const s: TStream);
var
  n: Integer;
begin
  s.Read(n, SizeOf(n));
  SetLength(State, n);
  if n > 0 then
    s.Read(State[1], n * SizeOf(Char));
end;

procedure TUndoTester.DoSave(const s: TStream);
var
  n: Integer;
begin
  n := Length(State);
  s.Write(n, SizeOf(n));
  if n > 0 then
    s.Write(State[1], n * SizeOf(Char));
end;

procedure Undo;
const
  SCRIPTS: array[0..5] of string = (
    'S c1 S c2 S c3 U U U U R R R R',
    'S c1 S c2 U c3 R S c4 U U R',
    'S c1 S c2 S c3 S c4 S c5 S c6 U U U U U U U R R R R R R R',
    'U R S c1 S c2 U U U S c9 R U',
    'S c1 S c2 S c3 U R S c4 S c5 S c6 S c7 U U U U U U',
    'S c1 S c2 S c3 S c4 C S c5 U');
  LIMITS: array[0..5] of Integer = (0, 1000, 3, 2, 3, 100);
var
  sc, k: Integer;
  t: TUndoTester;
  l: TStringList;
  op: string;
begin
  for sc := 0 to High(SCRIPTS) do
  begin
    t := TUndoTester.Create;
    t.FMan := TUndoRedoManager.Create;
    t.FMan.OnSaveToStream := t.DoSave;
    t.FMan.OnLoadFromStream := t.DoLoad;
    if LIMITS[sc] <> 1000 then
      t.FMan.UndoLimit := LIMITS[sc];
    State := 'init';
    l := TStringList.Create;
    l.Delimiter := ' ';
    l.DelimitedText := SCRIPTS[sc];
    for k := 0 to l.Count - 1 do
    begin
      op := l[k];
      if op = 'S' then
        t.FMan.SaveUndo
      else if op = 'U' then
        t.FMan.Undo
      else if op = 'R' then
        t.FMan.Redo
      else if op = 'C' then
        t.FMan.Clear
      else
        State := op;
      Line(Format('UNDO %d.%d %s state=%s canundo=%d canredo=%d', [sc, k, op, State, Ord(t.FMan.CanUndo), Ord(t.FMan.CanRedo)]));
    end;
    l.Free;
    t.FMan.Free;
    t.Free;
  end;
end;

begin
  Out_ := TStringList.Create;
  Mru;
  Short;
  Settings;
  Undo;
  Out_.SaveToFile(ParamStr(1));
  Out_.Free;
end.
