{******************************************************************************}
{                                                                              }
{  DelphiDoom: table export library - the saving of a file                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.Saver;

interface

uses
  System.SysUtils,
  DelphiDoom.TableExport.Saver.Intf;

type
  /// <summary>
  ///   The saving that DEH_Save* and Info_SavePascal did eight times: the name, its extension, the
  ///   folder, the message before and after
  /// </summary>
  TTableExportSaver = class(TInterfacedObject, ITableExportSaver)
  strict private
    FOutput: ITableExportOutput;
    function FileNameFor(const AName, ADefaultExtension: string): string;
  public
    constructor Create(const AOutput: ITableExportOutput);
    procedure SaveLines(const AName, ADefaultExtension, AMissingMessage, ASavedFormat: string;
      const ALines: TFunc<TArray<string>>);
    procedure SaveText(const AName, ADefaultExtension, AMissingMessage, ASavedFormat: string;
      const AText: TFunc<string>);
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TTableExportSaver }

constructor TTableExportSaver.Create(const AOutput: ITableExportOutput);
begin
  inherited Create;
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  FOutput := AOutput;
end;

function TTableExportSaver.FileNameFor(const AName, ADefaultExtension: string): string;
begin
  if Pos('.', AName) = 0 then
    Result := AName + ADefaultExtension
  else
    Result := AName;
  Result := FOutput.SaveFileName(Result);
end;

procedure TTableExportSaver.SaveLines(const AName, ADefaultExtension, AMissingMessage, ASavedFormat: string;
  const ALines: TFunc<TArray<string>>);
var
  LFileName: string;
begin
  if AName = '' then
  begin
    FOutput.Print(AMissingMessage);
    Exit;
  end;
  LFileName := FileNameFor(AName, ADefaultExtension);
  FOutput.SaveLines(LFileName, ALines());
  FOutput.Print(Format(ASavedFormat, [LFileName]));
end;

procedure TTableExportSaver.SaveText(const AName, ADefaultExtension, AMissingMessage, ASavedFormat: string;
  const AText: TFunc<string>);
begin
  SaveLines(AName, ADefaultExtension, AMissingMessage, ASavedFormat,
    function: TArray<string>
    begin
      Result := TScannerStrings.SplitLines(AText());
    end);
end;

end.
