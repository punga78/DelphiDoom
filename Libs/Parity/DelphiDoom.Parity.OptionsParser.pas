{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the options of the command line                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.OptionsParser;

interface

uses
  DelphiDoom.Parity.Types;

type
  /// <summary>
  ///   Reads the options of the parity tools from the arguments of the program (the names are not case
  ///   sensitive): -statehash file, -statehash-detail first last, -framehash file, -framedump tic file,
  ///   -autodemo seed tics. What is not one of them is ignored
  /// </summary>
  TParityOptionsParser = class
  strict private
    class function FindName(const AArguments: TArray<string>; const AName: string): Integer; static;
    class function ReadText(const AArguments: TArray<string>; AIndex: Integer; const AName: string): string; static;
    class function ReadInteger(const AArguments: TArray<string>; AIndex: Integer;
      const AName: string): Int64; static;
  public
    /// <summary>The options asked for; EParityException when a value is missing or is not what it must be</summary>
    class function Parse(const AArguments: TArray<string>): TParityOptions; static;
  end;

implementation

uses
  System.SysUtils;

const
  SMissingValue = 'The option %s needs a value after it';
  SWrongNumber = 'The option %s needs a whole number, not "%s"';
  SDetailWithoutHash = 'The option -statehash-detail needs -statehash';
  SWrongRange = 'The range of -statehash-detail is wrong';
  SWrongTics = 'The number of tics of -autodemo must be more than 0';

{ TParityOptionsParser }

class function TParityOptionsParser.FindName(const AArguments: TArray<string>; const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AArguments) do
    if SameText(AArguments[LIndex], AName) then
      Exit(LIndex);
  Result := -1;
end;

class function TParityOptionsParser.ReadText(const AArguments: TArray<string>; AIndex: Integer;
  const AName: string): string;
begin
  if (AIndex < 0) or (AIndex > High(AArguments)) or (Copy(AArguments[AIndex], 1, 1) = '-') then
    raise EParityException.CreateFmt(SMissingValue, [AName]);
  Result := AArguments[AIndex];
end;

class function TParityOptionsParser.ReadInteger(const AArguments: TArray<string>; AIndex: Integer;
  const AName: string): Int64;
var
  LText: string;
begin
  if (AIndex < 0) or (AIndex > High(AArguments)) then
    raise EParityException.CreateFmt(SMissingValue, [AName]);
  LText := AArguments[AIndex];
  if not TryStrToInt64(LText, Result) then
    raise EParityException.CreateFmt(SWrongNumber, [AName, LText]);
end;

class function TParityOptionsParser.Parse(const AArguments: TArray<string>): TParityOptions;
var
  LIndex: Integer;
begin
  Result := Default(TParityOptions);
  Result.FrameDumpTic := -1;

  LIndex := FindName(AArguments, '-statehash');
  if LIndex >= 0 then
    Result.StateHashFile := ReadText(AArguments, LIndex + 1, '-statehash');

  LIndex := FindName(AArguments, '-statehash-detail');
  if LIndex >= 0 then
  begin
    if Result.StateHashFile = '' then
      raise EParityException.Create(SDetailWithoutHash);
    Result.StateDetail := True;
    Result.StateDetailFirstTic := Integer(ReadInteger(AArguments, LIndex + 1, '-statehash-detail'));
    Result.StateDetailLastTic := Integer(ReadInteger(AArguments, LIndex + 2, '-statehash-detail'));
    if (Result.StateDetailFirstTic < 0) or (Result.StateDetailLastTic < Result.StateDetailFirstTic) then
      raise EParityException.Create(SWrongRange);
  end;

  LIndex := FindName(AArguments, '-framehash');
  if LIndex >= 0 then
    Result.FrameHashFile := ReadText(AArguments, LIndex + 1, '-framehash');

  LIndex := FindName(AArguments, '-framedump');
  if LIndex >= 0 then
  begin
    Result.FrameDumpTic := Integer(ReadInteger(AArguments, LIndex + 1, '-framedump'));
    Result.FrameDumpFile := ReadText(AArguments, LIndex + 2, '-framedump');
    if Result.FrameDumpTic < 0 then
      raise EParityException.CreateFmt(SWrongNumber, ['-framedump', IntToStr(Result.FrameDumpTic)]);
  end;

  LIndex := FindName(AArguments, '-autodemo');
  if LIndex >= 0 then
  begin
    Result.AutoDemo := True;
    Result.AutoDemoSeed := Cardinal(ReadInteger(AArguments, LIndex + 1, '-autodemo') and $FFFFFFFF);
    Result.AutoDemoTics := Integer(ReadInteger(AArguments, LIndex + 2, '-autodemo'));
    if Result.AutoDemoTics <= 0 then
      raise EParityException.Create(SWrongTics);
  end;
end;

end.
