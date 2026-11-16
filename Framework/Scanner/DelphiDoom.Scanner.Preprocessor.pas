{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the preprocessor of the scripts                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Preprocessor;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>
  ///   Prepares the text of a script (the old SC_Preprocess): follows #include, #include_all
  ///   and #include_wad (also written {$INCLUDE ...}) up to 31 levels, gives the other
  ///   directives to the IScriptDirective that wants them, and ends with the #define /
  ///   #ifdef part. Only the characters below 128 are kept. A file is never included inside
  ///   itself. The problems are warnings to the log
  /// </summary>
  TScriptPreprocessor = class
  public
    const
      MAX_INCLUDE_DEPTH = 32;
  private
    FSource: IScriptIncludeSource;
    FDirectives: TArray<IScriptDirective>;
    FLog: ILog;
    FIncludes: TStringList;
    FDepth: Integer;
    FAddComment: Boolean;
    procedure Warn(const AMessage: string);
    function ExpandIncludes(const AText: string): string;
    function TryDirectives(const AUpperLine: string): Boolean;
  public
    constructor Create(const ASource: IScriptIncludeSource; const ADirectives: TArray<IScriptDirective>;
      const ALog: ILog);
    /// <summary>
    ///   AAddComment puts a // comment before and after the text of each include; ADefines
    ///   are the names that are defined before the script starts
    /// </summary>
    function Preprocess(const AText: string; AAddComment: Boolean; const ADefines: TArray<string>): string;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.Scanner.Defines;

{ TScriptPreprocessor }

constructor TScriptPreprocessor.Create(const ASource: IScriptIncludeSource;
  const ADirectives: TArray<IScriptDirective>; const ALog: ILog);
begin
  inherited Create;
  FSource := ASource;
  FDirectives := ADirectives;
  FLog := ALog;
end;

procedure TScriptPreprocessor.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

function TScriptPreprocessor.TryDirectives(const AUpperLine: string): Boolean;
var
  LDirective: IScriptDirective;
begin
  for LDirective in FDirectives do
    if LDirective.Execute(AUpperLine) then
      Exit(True);
  Result := False;
end;

function TScriptPreprocessor.ExpandIncludes(const AText: string): string;
var
  LLines: TArray<string>;
  LIndex: Integer;
  LCharIndex: Integer;
  LLine: string;
  LCode: string;
  LUpper: string;
  LKeyword: string;
  LName: string;
  LIncluded: string;
  LAll: Boolean;
  LOne: Boolean;
  LLump: Boolean;
  LPosition: Integer;
begin
  Inc(FDepth);
  if FDepth >= MAX_INCLUDE_DEPTH then
  begin
    // like the old code, the depth is not given back
    Warn(Format('SC_Preprocess(): Include file maximum depth(%d) exceeded'#13#10, [FDepth]));
    Exit(AText);
  end;

  Result := '';
  LLines := TScannerStrings.SplitLines(AText);
  for LIndex := 0 to High(LLines) do
  begin
    LLine := LLines[LIndex];
    LPosition := Pos('//', LLine);
    if LPosition > 0 then
      LCode := Copy(LLine, 1, LPosition - 1)
    else
      LCode := LLine;
    LUpper := TScannerStrings.UpperAscii(TScannerStrings.Trim(LCode));

    LOne := False;
    LAll := False;
    LLump := False;
    if Pos('I', LUpper) > 1 then
    begin
      LOne := LUpper.StartsWith('#INCLUDE ') or LUpper.StartsWith('{$INCLUDE ') or
        LUpper.StartsWith('{$INCLUDE} ');
      LAll := LUpper.StartsWith('#INCLUDE_ALL ') or LUpper.StartsWith('{$INCLUDE_ALL ') or
        LUpper.StartsWith('{$INCLUDE_ALL} ');
      LLump := LUpper.StartsWith('#INCLUDE_WAD ') or LUpper.StartsWith('{$INCLUDE_WAD ') or
        LUpper.StartsWith('{$INCLUDE_WAD} ');
    end;

    if LOne or LAll or LLump then
    begin
      TScannerStrings.SplitAtFirst(TScannerStrings.Trim(LCode), LKeyword, LName);
      LName := TScannerStrings.Trim(LName);
      if LName <> '' then
      begin
        for LCharIndex := 1 to Length(LName) do
          if CharInSet(LName[LCharIndex], ['"', '''', '<', '>', '}', '{']) then
            LName[LCharIndex] := ' ';
        LName := TScannerStrings.Trim(LName);
        if LName <> '' then
        begin
          if LAll then
            LIncluded := FSource.ReadAllFiles(LName)
          else if LLump then
            LIncluded := FSource.ReadLump(LName)
          else
            LIncluded := FSource.ReadFile(LName);

          if LIncluded <> '' then
          begin
            LName := TScannerStrings.UpperAscii(LName);
            if FIncludes.IndexOf(LName) < 0 then
            begin
              FIncludes.Add(LName);
              if FAddComment then
                Result := Result + '//---->' + LCode + #13#10;
              Result := Result + ExpandIncludes(LIncluded) + #13#10;
              if FAddComment then
                Result := Result + '//---->' + LCode + ' + <--- end of include'#13#10;
              if FIncludes.IndexOf(LName) >= 0 then
                FIncludes.Delete(FIncludes.IndexOf(LName));
            end
            else
              Warn(Format('SC_Preprocess(): Invalid recoursive call of include file %s'#13#10, [LName]));
          end
          else
            Warn(Format('SC_Preprocess(): Include file %s does not exist or is empty'#13#10, [LName]));
        end;
      end;
    end
    else if not TryDirectives(LUpper) then
      Result := Result + LLine + #13#10;
  end;
  Dec(FDepth);
end;

function TScriptPreprocessor.Preprocess(const AText: string; AAddComment: Boolean;
  const ADefines: TArray<string>): string;
var
  LDecoded: string;
  LChar: Char;
  LDefines: TScriptDefines;
  LDefine: string;
begin
  FAddComment := AAddComment;
  FDepth := 0;
  FIncludes := TStringList.Create;
  try
    LDecoded := '';
    for LChar in AText do
      if Ord(LChar) < 128 then
        LDecoded := LDecoded + LChar;
    Result := ExpandIncludes(LDecoded);
  finally
    FIncludes.Free;
    FIncludes := nil;
  end;

  LDefines := TScriptDefines.Create(FLog);
  try
    for LDefine in ADefines do
      LDefines.AddDefine(LDefine);
    Result := LDefines.Preprocess(Result);
  finally
    LDefines.Free;
  end;
end;

end.
