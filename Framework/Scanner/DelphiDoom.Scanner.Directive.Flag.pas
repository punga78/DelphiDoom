{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - directive that runs a procedure                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Directive.Flag;

interface

uses
  System.SysUtils, DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>A directive made of one line that is exactly one of some words: it runs a procedure (VANILLA_DEMO_OFF)</summary>
  TFlagDirective = class(TInterfacedObject, IScriptDirective)
  private
    FWords: TArray<string>;
    FAction: TProc;
  public
    constructor Create(const AWords: TArray<string>; const AAction: TProc);
    function Execute(const AUpperLine: string): Boolean;
  end;

implementation

{ TFlagDirective }

constructor TFlagDirective.Create(const AWords: TArray<string>; const AAction: TProc);
begin
  inherited Create;
  FWords := AWords;
  FAction := AAction;
end;

function TFlagDirective.Execute(const AUpperLine: string): Boolean;
var
  LWord: string;
begin
  for LWord in FWords do
    if AUpperLine = LWord then
    begin
      if Assigned(FAction) then
        FAction();
      Exit(True);
    end;
  Result := False;
end;

end.
