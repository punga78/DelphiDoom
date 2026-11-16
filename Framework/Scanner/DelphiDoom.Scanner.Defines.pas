{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the #define / #ifdef directives of the scripts }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Defines;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   The conditional part of a script (the old TDefinesPreprocessor): #DEFINE, #UNDEF,
  ///   #IFDEF, #IFNDEF, #ELSE, #ENDIF and #EXITIF. The names do not depend on the case. The
  ///   defines that a script makes or removes end with the call: the next script starts from
  ///   the defines of the creation. Mistakes are warnings to the log, with the lines around
  /// </summary>
  TScriptDefines = class
  private
    type
      TBlock = record
        InElse: Boolean;
        DoWrite: Boolean;
      end;
  private
    FDefines: TStringList;
    FBlocks: TArray<TBlock>;
    FLog: ILog;
    function IsWriting: Boolean;
    function IsPreviousWriting: Boolean;
    procedure Report(ALines: TStringList; ALine: Integer; const AMessage: string);
  public
    constructor Create(const ALog: ILog);
    destructor Destroy; override;
    procedure AddDefine(const ADefine: string);
    /// <summary>The text without the directives and without the lines that the conditions leave out</summary>
    function Preprocess(const AText: string): string;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TScriptDefines }

constructor TScriptDefines.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
  FDefines := TStringList.Create;
end;

destructor TScriptDefines.Destroy;
begin
  FDefines.Free;
  inherited Destroy;
end;

procedure TScriptDefines.AddDefine(const ADefine: string);
var
  LDefine: string;
begin
  LDefine := UpperCase(ADefine);
  if FDefines.IndexOf(LDefine) < 0 then
    FDefines.Add(LDefine);
end;

function TScriptDefines.IsWriting: Boolean;
begin
  Result := (Length(FBlocks) = 0) or FBlocks[High(FBlocks)].DoWrite;
end;

function TScriptDefines.IsPreviousWriting: Boolean;
begin
  Result := (Length(FBlocks) < 2) or FBlocks[High(FBlocks) - 1].DoWrite;
end;

procedure TScriptDefines.Report(ALines: TStringList; ALine: Integer; const AMessage: string);
var
  LIndex: Integer;
begin
  if not Assigned(FLog) then
    Exit;
  FLog.Warning('TDefinesPreprocessor.Preprocess(): ' + AMessage + ' (line ' + IntToStr(ALine) + ')'#13#10);
  for LIndex := ALine - 3 to ALine + 3 do
    if (LIndex >= 0) and (LIndex < ALines.Count) then
    begin
      if LIndex = 0 then
        FLog.Warning('                                  ' + ALines[LIndex] + #13#10)
      else
        FLog.Warning('--------------------------------->' + ALines[LIndex] + #13#10);
    end;
end;

function TScriptDefines.Preprocess(const AText: string): string;
var
  LInput: TStringList;
  LOutput: TStringList;
  LOldDefines: TStringList;
  LIndex: Integer;
  LLine: string;
  LUpper: string;
  LKeyword: string;
  LArgument: string;
  LWrite: Boolean;
begin
  LOldDefines := TStringList.Create;
  LInput := TStringList.Create;
  LOutput := TStringList.Create;
  try
    LOldDefines.AddStrings(FDefines);
    LInput.Text := AText;
    FBlocks := nil;
    for LIndex := 0 to LInput.Count - 1 do
    begin
      LLine := LInput[LIndex];
      LUpper := UpperCase(Trim(LLine));
      TScannerStrings.SplitAtFirst(LUpper, LKeyword, LArgument);
      if LKeyword = '#DEFINE' then
      begin
        if LArgument = '' then
          Report(LInput, LIndex, 'Identifier expected after #define keyword')
        else
          AddDefine(LArgument);
      end
      else if LKeyword = '#UNDEF' then
      begin
        if LArgument = '' then
          Report(LInput, LIndex, 'Identifier expected after #undef keyword')
        else if FDefines.IndexOf(LArgument) < 0 then
          Report(LInput, LIndex, '"' + LArgument + '" is not defined!')
        else
          FDefines.Delete(FDefines.IndexOf(LArgument));
      end
      else if LKeyword = '#IFDEF' then
      begin
        LWrite := (FDefines.IndexOf(LArgument) >= 0) and IsWriting;
        SetLength(FBlocks, Length(FBlocks) + 1);
        FBlocks[High(FBlocks)].InElse := False;
        FBlocks[High(FBlocks)].DoWrite := LWrite;
      end
      else if LKeyword = '#IFNDEF' then
      begin
        LWrite := (FDefines.IndexOf(LArgument) < 0) and IsWriting;
        SetLength(FBlocks, Length(FBlocks) + 1);
        FBlocks[High(FBlocks)].InElse := False;
        FBlocks[High(FBlocks)].DoWrite := LWrite;
      end
      else if LKeyword = '#ENDIF' then
      begin
        if Length(FBlocks) = 0 then
          Report(LInput, LIndex, '#ENDIF without opening')
        else
          SetLength(FBlocks, Length(FBlocks) - 1);
      end
      else if LKeyword = '#ELSE' then
      begin
        if LArgument <> '' then
          Report(LInput, LIndex, '#ELSE keyword followed by "' + LArgument + '" is not allowed')
        else if Length(FBlocks) = 0 then
          Report(LInput, LIndex, '#ELSE without opening')
        else if FBlocks[High(FBlocks)].InElse then
          Report(LInput, LIndex, '#ELSE keyword used twice')
        else
        begin
          FBlocks[High(FBlocks)].InElse := True;
          FBlocks[High(FBlocks)].DoWrite := not FBlocks[High(FBlocks)].DoWrite and IsPreviousWriting;
        end;
      end
      else if LKeyword = '#EXITIF' then
      begin
        if IsWriting then
          if FDefines.IndexOf(LArgument) >= 0 then
            Break;
      end
      else if IsWriting then
        LOutput.Add(LLine);
    end;
    Result := LOutput.Text;
    FDefines.Clear;
    FDefines.AddStrings(LOldDefines);
  finally
    LOutput.Free;
    LInput.Free;
    LOldDefines.Free;
  end;
end;

end.
