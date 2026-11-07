{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the preprocessor of the scripts as a service   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.TextPreprocessor;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>
  ///   Port of SC_Preprocess (sc_utils.pas): the include source, the directives and the defines
  ///   of the game are given once; each call runs a new TScriptPreprocessor with the defines of
  ///   that moment, so nothing stays from a script to the next
  /// </summary>
  TScriptTextPreprocessor = class(TInterfacedObject, IScriptTextPreprocessor)
  strict private
    FSource: IScriptIncludeSource;
    FDirectives: TArray<IScriptDirective>;
    FDefines: IScriptDefinesSource;
    FLog: ILog;
  public
    /// <summary>ALog receives the warnings; it may be nil</summary>
    constructor Create(const ASource: IScriptIncludeSource; const ADirectives: TArray<IScriptDirective>;
      const ADefines: IScriptDefinesSource; const ALog: ILog);
    function Preprocess(const AText: string; AAddComment: Boolean): string;
  end;

implementation

uses
  DelphiDoom.Scanner.Preprocessor;

const
  SSourceMissing = 'TScriptTextPreprocessor: the include source is nil';
  SDefinesMissing = 'TScriptTextPreprocessor: the defines source is nil';

{ TScriptTextPreprocessor }

constructor TScriptTextPreprocessor.Create(const ASource: IScriptIncludeSource;
  const ADirectives: TArray<IScriptDirective>; const ADefines: IScriptDefinesSource; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create(SSourceMissing);
  if not Assigned(ADefines) then
    raise EArgumentNilException.Create(SDefinesMissing);
  FSource := ASource;
  FDirectives := ADirectives;
  FDefines := ADefines;
  FLog := ALog;
end;

function TScriptTextPreprocessor.Preprocess(const AText: string; AAddComment: Boolean): string;
var
  LPreprocessor: TScriptPreprocessor;
begin
  LPreprocessor := TScriptPreprocessor.Create(FSource, FDirectives, FLog);
  try
    Result := LPreprocessor.Preprocess(AText, AAddComment, FDefines.Defines);
  finally
    LPreprocessor.Free;
  end;
end;

end.
