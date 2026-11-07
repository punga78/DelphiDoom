{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - a message list that remembers        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.FakeLog;

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   Keeps every message as "KIND|text", with the CR and LF written as \r and \n: this is the
  ///   form of the log lines of the golden files
  /// </summary>
  TFakeIdeLog = class(TInterfacedObject, IIdeLog)
  strict private
    FLines: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function Lines: TStrings;
    /// <summary>The lines, with a folder replaced by a marker</summary>
    function LinesWithout(const AFolder, AMarker: string): TArray<string>;
    procedure Clear;
    procedure Write(const AKind: TIdeMessageKind; const AText: string);
    procedure WriteFormat(const AKind: TIdeMessageKind; const AFormat: string;
      const AArguments: array of const);
  end;

implementation

{ TFakeIdeLog }

constructor TFakeIdeLog.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TFakeIdeLog.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TFakeIdeLog.Lines: TStrings;
begin
  Result := FLines;
end;

function TFakeIdeLog.LinesWithout(const AFolder, AMarker: string): TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FLines.Count);
  for LIndex := 0 to FLines.Count - 1 do
    Result[LIndex] := StringReplace(FLines[LIndex], AFolder, AMarker, [rfReplaceAll, rfIgnoreCase]);
end;

procedure TFakeIdeLog.Clear;
begin
  FLines.Clear;
end;

procedure TFakeIdeLog.Write(const AKind: TIdeMessageKind; const AText: string);
const
  KIND_NAMES: array[TIdeMessageKind] of string = ('NORMAL', 'INFO', 'WARNING', 'ERROR');
begin
  FLines.Add(KIND_NAMES[AKind] + '|' +
    StringReplace(StringReplace(AText, #13, '\r', [rfReplaceAll]), #10, '\n', [rfReplaceAll]));
end;

procedure TFakeIdeLog.WriteFormat(const AKind: TIdeMessageKind; const AFormat: string;
  const AArguments: array of const);
begin
  Write(AKind, Format(AFormat, AArguments));
end;

end.
