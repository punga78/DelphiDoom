{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MUSINFO library - the corpus of texts             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MusInfo.Corpus;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Tests\Data\MusInfo\cases.txt: the texts that were given to the old code to make the
  ///   golden file. A line "@@@ name" starts a case; "@@ run [lf|cr] [notrail]" starts the
  ///   text of the lump for a call of P_InitMusInfo (the lines are joined with CR LF, LF or CR
  ///   and the last one is followed by a break unless notrail); "@@ missing" is a call with no
  ///   lump; "@@ find ID MAP" asks for the music after all the calls. The dump has the format
  ///   that the harness of the old code wrote
  /// </summary>
  TMusInfoCorpus = class
  private
    FLines: TStringList;
    class function Escape(const AText: string): string; static;
  public
    constructor Create(const ACasesFileName: string);
    destructor Destroy; override;
    /// <summary>Runs every case the way the game reads it and dumps the result</summary>
    function Dump: TStringList;
    /// <summary>Lines of a file, whatever its line breaks are (the caller frees the list)</summary>
    class function LoadLines(const AFileName: string): TStringList; static;
  end;

implementation

uses
  System.IOUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.MusInfo.Types, DelphiDoom.MusInfo.Intf,
  DelphiDoom.MusInfo.Factory, DelphiDoom.Tests.MusInfo.Fakes;

type
  TCaseRun = record
    Present: Boolean;
    Text: string;
  end;

{ TMusInfoCorpus }

class function TMusInfoCorpus.LoadLines(const AFileName: string): TStringList;
var
  LBytes: TBytes;
  LIndex: Integer;
  LLine: string;
begin
  Result := TStringList.Create;
  LBytes := TFile.ReadAllBytes(AFileName);
  LLine := '';
  for LIndex := 0 to High(LBytes) do
    if LBytes[LIndex] = 10 then
    begin
      if (LLine <> '') and (LLine[Length(LLine)] = #13) then
        Delete(LLine, Length(LLine), 1);
      Result.Add(LLine);
      LLine := '';
    end
    else
      LLine := LLine + Char(LBytes[LIndex]);
  if LLine <> '' then
    Result.Add(LLine);
end;

constructor TMusInfoCorpus.Create(const ACasesFileName: string);
begin
  inherited Create;
  FLines := LoadLines(ACasesFileName);
end;

destructor TMusInfoCorpus.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

class function TMusInfoCorpus.Escape(const AText: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LChar := AText[LIndex];
    if LChar = '\' then
      Result := Result + '\\'
    else if LChar = #13 then
      Result := Result + '\r'
    else if LChar = #10 then
      Result := Result + '\n'
    else if (Ord(LChar) < 32) or (Ord(LChar) > 126) then
      Result := Result + '\x' + IntToHex(Ord(LChar), 2)
    else
      Result := Result + LChar;
  end;
end;

function TMusInfoCorpus.Dump: TStringList;
var
  LCaseName: string;
  LRuns: TList<TCaseRun>;
  LFinds: TStringList;
  LJoiner: string;
  LTrail: Boolean;
  LCurrent: string;
  LLineNumber: Integer;
  LCollecting: Boolean;

  procedure FlushText;
  var
    LRun: TCaseRun;
  begin
    if not LCollecting then
      Exit;
    if LTrail then
      LCurrent := LCurrent + LJoiner;
    LRun.Present := True;
    LRun.Text := LCurrent;
    LRuns[LRuns.Count - 1] := LRun;
    LCollecting := False;
  end;

  procedure EndCase;
  var
    LLog: TFakeLog;
    LLogIntf: ILog;
    LCatalog: IMusInfoCatalog;
    LParser: IMusInfoParser;
    LRun: TCaseRun;
    LEntry: TMusInfoEntry;
    LIndex: Integer;
    LFind: string;
    LSpace: Integer;
    LId: Integer;
    LMap: string;
  begin
    if LCaseName = '' then
      Exit;
    FlushText;
    LLog := TFakeLog.Create;
    LLogIntf := LLog;
    LCatalog := TMusInfoFactory.CreateCatalog(TFakeMusic.Create, LLogIntf);
    LParser := TMusInfoFactory.CreateParser(LLogIntf);
    for LRun in LRuns do
      TMusInfoFactory.CreateLoader(TFakeTextSource.Create(LRun.Present, LRun.Text), LParser,
        LCatalog).Load;
    Result.Add('=== ' + LCaseName);
    Result.Add('warnings=' + Escape(LLog.Warnings));
    Result.Add('count=' + IntToStr(LCatalog.Count));
    for LIndex := 0 to LCatalog.Count - 1 do
    begin
      LEntry := LCatalog.GetEntry(LIndex);
      Result.Add(Format('entry[%d] map=%s id=%d name=%s num=%d', [LIndex, Escape(LEntry.MapName),
        LEntry.MusicId, Escape(LEntry.MusicName), LEntry.MusicNumber]));
    end;
    for LFind in LFinds do
    begin
      LSpace := Pos(' ', LFind);
      LId := StrToInt(Copy(LFind, 1, LSpace - 1));
      LMap := Copy(LFind, LSpace + 1, MaxInt);
      Result.Add(Format('find %d %s=%d', [LId, LMap, LCatalog.Find(LId, LMap)]));
    end;
    LRuns.Clear;
    LFinds.Clear;
  end;

var
  LIndex: Integer;
  LLine: string;
  LOptions: string;
  LRun: TCaseRun;
begin
  Result := TStringList.Create;
  LRuns := TList<TCaseRun>.Create;
  LFinds := TStringList.Create;
  try
    LCaseName := '';
    LCollecting := False;
    LJoiner := #13#10;
    LTrail := True;
    LCurrent := '';
    LLineNumber := 0;
    for LIndex := 0 to FLines.Count - 1 do
    begin
      LLine := FLines[LIndex];
      if Copy(LLine, 1, 4) = '@@@ ' then
      begin
        EndCase;
        LCaseName := Copy(LLine, 5, MaxInt);
        LCollecting := False;
      end
      else if Copy(LLine, 1, 3) = '@@ ' then
      begin
        FlushText;
        LOptions := Copy(LLine, 4, MaxInt);
        if Copy(LOptions, 1, 3) = 'run' then
        begin
          LRun.Present := True;
          LRun.Text := '';
          LRuns.Add(LRun);
          LJoiner := #13#10;
          LTrail := True;
          if Pos(' lf', LOptions) > 0 then
            LJoiner := #10;
          if Pos(' cr', LOptions) > 0 then
            LJoiner := #13;
          if Pos(' notrail', LOptions) > 0 then
            LTrail := False;
          LCurrent := '';
          LLineNumber := 0;
          LCollecting := True;
        end
        else if LOptions = 'missing' then
        begin
          LRun.Present := False;
          LRun.Text := '';
          LRuns.Add(LRun);
        end
        else if Copy(LOptions, 1, 5) = 'find ' then
          LFinds.Add(Copy(LOptions, 6, MaxInt));
      end
      else if LCollecting then
      begin
        if LLineNumber > 0 then
          LCurrent := LCurrent + LJoiner;
        Inc(LLineNumber);
        LCurrent := LCurrent + LLine;
      end;
    end;
    EndCase;
  finally
    LFinds.Free;
    LRuns.Free;
  end;
end;

end.
