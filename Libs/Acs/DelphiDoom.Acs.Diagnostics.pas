{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the errors                                }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Diagnostics;

interface

uses
  DelphiDoom.Acs.Intf;

type
  /// <summary>
  ///   Where the compiler stops: it raises EAcsCompileException with the lines that the old
  ///   compiler wrote in its error file. The position (line and file) is asked to the tokenizer
  /// </summary>
  TAcsDiagnostics = class
  private
    FPosition: IAcsSourcePosition;
  public
    /// <summary>Set when the tokenizer exists: until then an error has no position</summary>
    property Position: IAcsSourcePosition read FPosition write FPosition;
    procedure Fail(ACode: Integer; AWithPosition: Boolean); overload;
    procedure Fail(ACode: Integer; AWithPosition: Boolean; const AFormat: string;
      const AArguments: array of const); overload;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Acs.ErrorCodes, DelphiDoom.Acs.ErrorTexts, DelphiDoom.Acs.Types;

const
  SPositionLine = 'Line %d in file ''%s'' ...'#13#10;
  SErrorLine = 'Error #%d: %s'#13#10;

{ TAcsDiagnostics }

procedure TAcsDiagnostics.Fail(ACode: Integer; AWithPosition: Boolean);
begin
  Fail(ACode, AWithPosition, '', []);
end;

procedure TAcsDiagnostics.Fail(ACode: Integer; AWithPosition: Boolean; const AFormat: string;
  const AArguments: array of const);
var
  LMessage: string;
  LLine: Integer;
  LSourceName: string;
begin
  LLine := 0;
  LSourceName := '';
  LMessage := '';
  if AWithPosition and Assigned(FPosition) then
  begin
    LLine := FPosition.Line;
    LSourceName := FPosition.SourceName;
    LMessage := Format(SPositionLine, [LLine, LSourceName]);
  end;
  if (ACode <> ERR_NONE) and (TAcsErrorTexts.TextOf(ACode) <> '') then
    LMessage := LMessage + Format(SErrorLine, [ACode, TAcsErrorTexts.TextOf(ACode)]);
  if AFormat <> '' then
    LMessage := LMessage + Format(AFormat, AArguments) + #13#10;

  raise EAcsCompileException.Create(ACode, AWithPosition and Assigned(FPosition), LLine,
    LSourceName, LMessage);
end;

end.
