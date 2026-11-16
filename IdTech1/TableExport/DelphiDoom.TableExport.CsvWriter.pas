{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the tables as CSV files                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.CsvWriter;

interface

uses
  DelphiDoom.TableExport.Intf;

type
  /// <summary>
  ///   Writes the things and the states as the CSV files that a spreadsheet reads. The
  ///   rows come from the lines of the patch that IExportDehWriter writes, so the columns are
  ///   the fields that the patch has. The names of the first built in states come from the
  ///   enumeration of the engine
  /// </summary>
  TExportCsvWriter = class(TInterfacedObject, IExportCsvWriter)
  strict private
    FStates: IExportStateSource;
    FEnums: IExportEnumNames;
    function StateName(AIndex: Integer): string;
    /// <summary>The position of the first line that is ALine; -1 if there is none</summary>
    class function IndexOfLine(const APatch: TArray<string>; const ALine: string): Integer; static;
  public
    /// <exception cref="EArgumentNilException">A source is nil</exception>
    constructor Create(const AStates: IExportStateSource; const AEnums: IExportEnumNames);
    function MobjInfo(const APatch: TArray<string>): TArray<string>;
    function States(const APatch: TArray<string>): TArray<string>;
    function Sprites: TArray<string>;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.TableExport.Types,
  DelphiDoom.TableExport.Text;

{ TExportCsvWriter }

constructor TExportCsvWriter.Create(const AStates: IExportStateSource; const AEnums: IExportEnumNames);
begin
  inherited Create;
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AEnums) then
    raise EArgumentNilException.Create('AEnums');
  FStates := AStates;
  FEnums := AEnums;
end;

function TExportCsvWriter.StateName(AIndex: Integer): string;
begin
  if AIndex < FEnums.Count(eeState) then
    Result := UpperCase(FEnums.Name(eeState, AIndex))
  else
    Result := 'S_STATE_' + IntToStr(AIndex);
end;

class function TExportCsvWriter.IndexOfLine(const APatch: TArray<string>; const ALine: string): Integer;
begin
  for Result := 0 to High(APatch) do
    if APatch[Result] = ALine then
      Exit;
  // The old code went on with -1 if the line was missing
  Result := -1;
end;

function TExportCsvWriter.MobjInfo(const APatch: TArray<string>): TArray<string>;
var
  LFirst: Integer;
  LLast: Integer;
  LIndex: Integer;
  LText: string;
  LKey: string;
  LValue: string;
  LHeader: string;
  LData: string;
  LRows: TList<string>;
begin
  LFirst := IndexOfLine(APatch, '# Things');
  LLast := IndexOfLine(APatch, '# States');
  LRows := TList<string>.Create;
  try
    LHeader := '';
    for LIndex := LFirst + 1 to LLast - 1 do
    begin
      LText := TExportText.Trim(APatch[LIndex]);
      if (LText <> '') and (Pos('#', LText) <> 1) and (Pos('//', LText) < 1) then
      begin
        if TExportText.StartsWith('THING ', UpperCase(LText)) then
        begin
          if LHeader = '' then
            LHeader := '"id"'
          else
            Break;
        end
        else if LHeader <> '' then
        begin
          TExportText.Split(LText, '=', LKey, LValue);
          LHeader := LHeader + ';' + '"' + TExportText.Trim(LKey) + '"';
        end;
      end;
    end;
    LRows.Add(LHeader);

    LData := '';
    for LIndex := LFirst + 1 to LLast - 1 do
    begin
      LText := TExportText.Trim(APatch[LIndex]);
      if (LText <> '') and (Pos('#', LText) <> 1) and (Pos('//', LText) < 1) then
      begin
        if Pos('THING ', UpperCase(LText)) < 1 then
        begin
          TExportText.Split(LText, '=', LKey, LValue);
          if LValue = '' then
            LValue := '-';
          LData := LData + ';' + '"' + LValue + '"';
        end
        else
        begin
          if LData <> '' then
            LRows.Add(LData);
          LData := '"' + IntToStr(LRows.Count - 1) + '"';
        end;
      end;
    end;
    if LData <> '' then
      LRows.Add(LData);
    Result := LRows.ToArray;
  finally
    LRows.Free;
  end;
end;

function TExportCsvWriter.States(const APatch: TArray<string>): TArray<string>;
var
  LFirst: Integer;
  LLast: Integer;
  LIndex: Integer;
  LChar: Integer;
  LText: string;
  LKey: string;
  LValue: string;
  LHeader: string;
  LData: string;
  LRows: TList<string>;
begin
  LFirst := IndexOfLine(APatch, '# States');
  LLast := IndexOfLine(APatch, '# Weapons');
  LRows := TList<string>.Create;
  try
    LHeader := '';
    for LIndex := LFirst + 1 to LLast - 1 do
    begin
      LText := TExportText.Trim(APatch[LIndex]);
      if (LText <> '') and (Pos('#', LText) <> 1) and (Pos('//', LText) < 1) then
      begin
        if TExportText.StartsWith('FRAME ', UpperCase(LText)) then
        begin
          if LHeader = '' then
            LHeader := '"Name";"id"'
          else
            Break;
        end
        else if LHeader <> '' then
        begin
          TExportText.Split(LText, '=', LKey, LValue);
          LHeader := LHeader + ';' + '"' + TExportText.Trim(LKey) + '"';
        end;
      end;
    end;
    LRows.Add(LHeader);
    LRows.Add('"S_NULL";"0";"0";"0";"0";"-1";"0";"NULL";"0";"0";"0";"0"');

    LData := '';
    for LIndex := LFirst + 1 to LLast - 1 do
    begin
      LText := TExportText.Trim(APatch[LIndex]);
      if (LText <> '') and (Pos('#', LText) <> 1) and (Pos('//', LText) < 1) then
      begin
        if not TExportText.StartsWith('FRAME ', UpperCase(LText)) then
        begin
          TExportText.Split(LText, '=', LKey, LValue);
          for LChar := 1 to Length(LValue) do
            if LValue[LChar] = '"' then
              LValue[LChar] := ' ';
          LData := LData + ';' + '"' + TExportText.Trim(LValue) + '"';
        end
        else
        begin
          if LData <> '' then
            LRows.Add('"' + StateName(LRows.Count - 1) + '";' + LData);
          LData := '"' + IntToStr(LRows.Count - 1) + '"';
        end;
      end;
    end;
    if LData <> '' then
      LRows.Add('"' + StateName(LRows.Count - 1) + '";' + LData);
    Result := LRows.ToArray;
  finally
    LRows.Free;
  end;
end;

function TExportCsvWriter.Sprites: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FStates.SpriteCount + 1);
  Result[0] := '"id";"Sprite"';
  for LIndex := 0 to FStates.SpriteCount - 1 do
    Result[LIndex + 1] := IntToStr(LIndex + 1) + ';' + '"' + FStates.SpriteName(LIndex) + '"';
end;

end.
