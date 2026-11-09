{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - shared types of the variables of the scripts      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Variables.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The chains of the hash table of the names (must be a power of two)</summary>
  SCRIPT_VARIABLES_HASH_SIZE = 8192;
  /// <summary>How many of the last found positions the hash table remembers</summary>
  SCRIPT_VARIABLES_LAST_SEARCHES = 5;

type
  /// <summary>
  ///   Raised by the variables of the scripts when a buffer or a file is not what they wrote, or
  ///   when the files fail
  /// </summary>
  EScriptVariablesException = class(Exception);

  /// <summary>The value of a variable of type string</summary>
  TScriptStringValue = class(TObject)
  public
    Value: string;
    constructor Create(const AValue: string);
  end;

  /// <summary>The value of a variable of type integer</summary>
  TScriptIntegerValue = class(TObject)
  public
    Value: Integer;
    constructor Create(const AValue: Integer);
  end;

  /// <summary>The value of a variable of type float (single, as the scripts have it)</summary>
  TScriptFloatValue = class(TObject)
  public
    Value: Single;
    constructor Create(const AValue: Single);
  end;

resourcestring
  SScriptVariablesCannotLoadFile = 'TScriptVariables.LoadFromFile(): Can not load from file %s';
  SScriptVariablesTruncatedBuffer = 'TScriptVariables.LoadFromBuffer(): the buffer ends before the data';
  SScriptVariablesInvalidBuffer = 'TScriptVariables.LoadFromBuffer(): the buffer has a negative length or count';

implementation

{ TScriptStringValue }

constructor TScriptStringValue.Create(const AValue: string);
begin
  inherited Create;
  Value := AValue;
end;

{ TScriptIntegerValue }

constructor TScriptIntegerValue.Create(const AValue: Integer);
begin
  inherited Create;
  Value := AValue;
end;

{ TScriptFloatValue }

constructor TScriptFloatValue.Create(const AValue: Single);
begin
  inherited Create;
  Value := AValue;
end;

end.
