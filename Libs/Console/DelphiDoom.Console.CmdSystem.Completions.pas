{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 default argument completions         }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CmdSystem.h                 }
{  (ArgCompletion_Boolean, _Integer<min,max>, _String<strings>).               }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CmdSystem.Completions;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Types;

type
  /// <summary>
  ///   The completions of a command argument that the original makes with function templates: the
  ///   parameters of the template (a range, a list of strings) are the fields of the object, so each
  ///   object serves as a <c>TCmdArgCompletion</c> (<c>Completion.CompleteInteger</c> and so on).
  ///   The object must live as long as the commands that use it.
  /// </summary>
  TCmdCompletions = class
  strict private
    FMinimum: Integer;
    FMaximum: Integer;
    FStrings: TArray<AnsiString>;
  public
    /// <summary>For CompleteBoolean (no parameters)</summary>
    constructor Create; overload;
    /// <summary>ArgCompletion_Integer&lt;min,max&gt;</summary>
    constructor Create(const AMinimum, AMaximum: Integer); overload;
    /// <summary>ArgCompletion_String&lt;strings&gt;</summary>
    constructor Create(const AStrings: TArray<AnsiString>); overload;
    /// <summary>"name 0" and "name 1"</summary>
    procedure CompleteBoolean(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
    /// <summary>"name n" for each n from the minimum to the maximum</summary>
    procedure CompleteInteger(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
    /// <summary>"name s" for each string</summary>
    procedure CompleteString(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
  end;

implementation

{ TCmdCompletions }

constructor TCmdCompletions.Create;
begin
  inherited Create;
end;

constructor TCmdCompletions.Create(const AMinimum, AMaximum: Integer);
begin
  inherited Create;
  FMinimum := AMinimum;
  FMaximum := AMaximum;
end;

constructor TCmdCompletions.Create(const AStrings: TArray<AnsiString>);
begin
  inherited Create;
  FStrings := AStrings;
end;

procedure TCmdCompletions.CompleteBoolean(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
begin
  ACallback(AArgs.Argv(0) + ' 0');
  ACallback(AArgs.Argv(0) + ' 1');
end;

procedure TCmdCompletions.CompleteInteger(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
var
  LValue: Integer;
begin
  for LValue := FMinimum to FMaximum do
    ACallback(AArgs.Argv(0) + ' ' + AnsiString(IntToStr(LValue)));
end;

procedure TCmdCompletions.CompleteString(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FStrings) do
    ACallback(AArgs.Argv(0) + ' ' + FStrings[LIndex]);
end;

end.
