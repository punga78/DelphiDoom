{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - #CREATEPALETTE                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Directive.CreatePalette;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>"#CREATEPALETTE arguments": asks for the palettes to be made</summary>
  TCreatePaletteDirective = class(TInterfacedObject, IScriptDirective)
  private
    FGenerator: IPaletteGenerator;
    FLog: ILog;
  public
    constructor Create(const AGenerator: IPaletteGenerator; const ALog: ILog);
    function Execute(const AUpperLine: string): Boolean;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TCreatePaletteDirective }

constructor TCreatePaletteDirective.Create(const AGenerator: IPaletteGenerator; const ALog: ILog);
begin
  inherited Create;
  FGenerator := AGenerator;
  FLog := ALog;
end;

function TCreatePaletteDirective.Execute(const AUpperLine: string): Boolean;
var
  LKeyword: string;
  LArgument: string;
begin
  Result := AUpperLine.StartsWith('#CREATEPALETTE');
  if not Result then
    Exit;
  TScannerStrings.SplitAtFirst(AUpperLine, LKeyword, LArgument);
  if LKeyword <> '#CREATEPALETTE' then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format('SC_Preprocess(): Unknown directive %s'#13#10, [LKeyword]));
  end
  else
    FGenerator.Generate(LArgument);
end;

end.
