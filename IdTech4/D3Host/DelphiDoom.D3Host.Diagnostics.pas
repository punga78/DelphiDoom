{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - warnings and errors list                  }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Common.cpp (Warning, DWarning,      }
{  PrintWarnings, ClearWarnings, DumpWarnings).                                }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Diagnostics;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf;

type
  /// <summary>
  ///   The warnings (at most 256, no duplicates) that are kept to be printed later, and the errors that
  ///   were raised, to be written to warnings.txt. The sort is the one of idStrList::Sort: without
  ///   regard to case (idStr::Icmp); the C++ sorts with qsort, which is not stable, so two texts that
  ///   differ only by case can come out in either order (the sort here is not stable either).
  /// </summary>
  TD3Diagnostics = class
  strict private
    FPrinter: ID3Printer;
    FFiles: ID3CommonFileSystem;
    FSettings: ID3CommonSettings;
    FCaption: AnsiString;
    FWarnings: TList<AnsiString>;
    FErrors: TList<AnsiString>;
    procedure SortList(const AList: TList<AnsiString>);
    class function AddUnique(const AList: TList<AnsiString>; const AText: AnsiString): Boolean; static;
    procedure WriteText(const AFile: ID3CommonFile; const AText: AnsiString);
  public
    constructor Create(const APrinter: ID3Printer; const AFiles: ID3CommonFileSystem;
      const ASettings: ID3CommonSettings);
    destructor Destroy; override;
    /// <summary>idCommonLocal::Warning: prints "WARNING:" and remembers the text, up to 256 of them</summary>
    procedure Warning(const AText: AnsiString);
    /// <summary>idCommonLocal::DWarning: prints in yellow, only with the developer cvar</summary>
    procedure DWarning(const AText: AnsiString);
    /// <summary>idCommonLocal::PrintWarnings: the sorted list, with the caption and the count</summary>
    procedure PrintWarnings;
    /// <summary>idCommonLocal::ClearWarnings: a new caption ("during ...") and an empty list</summary>
    procedure ClearWarnings(const AReason: AnsiString);
    /// <summary>idCommonLocal::DumpWarnings: warnings.txt of fs_savepath with the warnings and the errors</summary>
    procedure DumpWarnings;
    /// <summary>errorList.AddUnique( errorMessage ), what Error does</summary>
    procedure AddError(const AText: AnsiString);
    function WarningCount: Integer;
    function WarningAt(const AIndex: Integer): AnsiString;
    function ErrorCount: Integer;
    function ErrorAt(const AIndex: Integer): AnsiString;
    function Caption: AnsiString;
  end;

implementation

uses
  System.Generics.Defaults, DelphiDoom.IdLib.Text.Str;

const
  SWarningsFileName = 'warnings.txt';
  SSavePath = 'fs_savepath';
  SWarningHeader = '------------- Warnings ---------------' + #10;
  SDuring = 'during %s...' + #10;
  SMoreThanWarnings = 'more than %d warnings' + #10;
  SWarningCount = '%d warnings' + #10;

constructor TD3Diagnostics.Create(const APrinter: ID3Printer; const AFiles: ID3CommonFileSystem;
  const ASettings: ID3CommonSettings);
begin
  inherited Create;
  FPrinter := APrinter;
  FFiles := AFiles;
  FSettings := ASettings;
  FWarnings := TList<AnsiString>.Create;
  FErrors := TList<AnsiString>.Create;
end;

destructor TD3Diagnostics.Destroy;
begin
  FErrors.Free;
  FWarnings.Free;
  inherited Destroy;
end;

class function TD3Diagnostics.AddUnique(const AList: TList<AnsiString>; const AText: AnsiString): Boolean;
begin
  // idList::AddUnique compares with operator==, which is case sensitive
  Result := not AList.Contains(AText);
  if Result then
    AList.Add(AText);
end;

procedure TD3Diagnostics.SortList(const AList: TList<AnsiString>);
begin
  AList.Sort(TComparer<AnsiString>.Construct(
    function(const ALeft, ARight: AnsiString): Integer
    var
      LLeft: TIdStr;
    begin
      LLeft := TIdStr.Create(ALeft);
      Result := LLeft.Icmp(ARight);
    end));
end;

procedure TD3Diagnostics.WriteText(const AFile: ID3CommonFile; const AText: AnsiString);
begin
  if AText <> '' then
    AFile.Write(AText[1], Length(AText));
end;

procedure TD3Diagnostics.Warning(const AText: AnsiString);
var
  LMessage: AnsiString;
begin
  LMessage := TD3MessageText.Limit(AText);
  FPrinter.Printf(D3_COLOR_YELLOW + 'WARNING: ' + D3_COLOR_RED + LMessage + #10);
  if FWarnings.Count < D3_MAX_WARNING_LIST then
    AddUnique(FWarnings, LMessage);
end;

procedure TD3Diagnostics.DWarning(const AText: AnsiString);
begin
  // don't confuse non-developers with techie stuff...
  if not FSettings.Developer then
    Exit;
  FPrinter.Printf(D3_COLOR_YELLOW + 'WARNING: ' + TD3MessageText.Limit(AText) + #10);
end;

procedure TD3Diagnostics.PrintWarnings;
var
  LIndex: Integer;
begin
  if FWarnings.Count = 0 then
    Exit;
  SortList(FWarnings);
  FPrinter.Printf(SWarningHeader);
  FPrinter.Printf(AnsiString(Format(SDuring, [string(FCaption)])));
  for LIndex := 0 to FWarnings.Count - 1 do
    FPrinter.Printf(D3_COLOR_YELLOW + 'WARNING: ' + D3_COLOR_RED + FWarnings[LIndex] + #10);
  if FWarnings.Count >= D3_MAX_WARNING_LIST then
    FPrinter.Printf(AnsiString(Format(SMoreThanWarnings, [D3_MAX_WARNING_LIST])))
  else
    FPrinter.Printf(AnsiString(Format(SWarningCount, [FWarnings.Count])));
end;

procedure TD3Diagnostics.ClearWarnings(const AReason: AnsiString);
begin
  FCaption := AReason;
  FWarnings.Clear;
end;

procedure TD3Diagnostics.AddError(const AText: AnsiString);
begin
  AddUnique(FErrors, AText);
end;

procedure TD3Diagnostics.DumpWarnings;
var
  LFile: ID3CommonFile;
  LIndex: Integer;
  LText: TIdStr;
begin
  if FWarnings.Count = 0 then
    Exit;
  LFile := FFiles.OpenFileWrite(SWarningsFileName, SSavePath);
  if not Assigned(LFile) then
    Exit;
  WriteText(LFile, '------------- Warnings ---------------' + #10#10);
  WriteText(LFile, AnsiString(Format(SDuring, [string(FCaption)])));
  SortList(FWarnings);
  for LIndex := 0 to FWarnings.Count - 1 do
  begin
    LText := TIdStr.Create(FWarnings[LIndex]);
    LText.RemoveColors;
    FWarnings[LIndex] := LText.Text;
    WriteText(LFile, 'WARNING: ' + FWarnings[LIndex] + #10);
  end;
  if FWarnings.Count >= D3_MAX_WARNING_LIST then
    WriteText(LFile, AnsiString(Format(#10 + 'more than %d warnings!' + #10, [D3_MAX_WARNING_LIST])))
  else
    WriteText(LFile, AnsiString(Format(#10 + '%d warnings.' + #10, [FWarnings.Count])));
  WriteText(LFile, #10#10 + '-------------- Errors ---------------' + #10#10);
  SortList(FErrors);
  for LIndex := 0 to FErrors.Count - 1 do
  begin
    LText := TIdStr.Create(FErrors[LIndex]);
    LText.RemoveColors;
    FErrors[LIndex] := LText.Text;
    WriteText(LFile, 'ERROR: ' + FErrors[LIndex]);
  end;
  LFile.ForceFlush;
  FFiles.CloseFile(LFile);
end;

function TD3Diagnostics.WarningCount: Integer;
begin
  Result := FWarnings.Count;
end;

function TD3Diagnostics.WarningAt(const AIndex: Integer): AnsiString;
begin
  Result := FWarnings[AIndex];
end;

function TD3Diagnostics.ErrorCount: Integer;
begin
  Result := FErrors.Count;
end;

function TD3Diagnostics.ErrorAt(const AIndex: Integer): AnsiString;
begin
  Result := FErrors[AIndex];
end;

function TD3Diagnostics.Caption: AnsiString;
begin
  Result := FCaption;
end;

end.
