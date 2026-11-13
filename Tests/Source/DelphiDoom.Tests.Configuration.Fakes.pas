{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the configuration library - fakes                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Configuration.Fakes;

interface

uses
  System.Classes,
  DelphiDoom.Configuration.Intf;

type
  /// <summary>A variable of the test reached through a pointer, as the engine reaches its globals</summary>
  TFakeConfigurationValue = class(TInterfacedObject, IConfigurationValueAccess)
  strict private
    FInteger: PInteger;
    FBoolean: PBoolean;
    FString: PString;
  public
    constructor Create(AInteger: PInteger; ABoolean: PBoolean; AString: PString);
    function GetInteger: Integer;
    procedure SetInteger(AValue: Integer);
    function GetBoolean: Boolean;
    procedure SetBoolean(AValue: Boolean);
    function GetString: string;
    procedure SetString(const AValue: string);
  end;

  /// <summary>
  ///   The messages and the console of a reset, written as the copy of the old code writes them
  ///   (DelphiDoom.Tests.Configuration.Legacy); CommandReset formats the default as
  ///   TEngineDefaults.CommandReset does
  /// </summary>
  TFakeResetSink = class(TInterfacedObject, IConfigurationResetSink)
  strict private
    FCommands: TStrings;
    FLog: TStrings;
  public
    constructor Create(const ACommands, ALog: TStrings);
    procedure ValueReset(const AName, ALowerName: string);
    function HasCommand(const ALowerName: string): Boolean;
    procedure CommandReset(const AName, ALowerName: string; const AItem: IConfigurationItem);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Configuration.Types;

{ TFakeConfigurationValue }

constructor TFakeConfigurationValue.Create(AInteger: PInteger; ABoolean: PBoolean; AString: PString);
begin
  inherited Create;
  FInteger := AInteger;
  FBoolean := ABoolean;
  FString := AString;
end;

function TFakeConfigurationValue.GetInteger: Integer;
begin
  Result := FInteger^;
end;

procedure TFakeConfigurationValue.SetInteger(AValue: Integer);
begin
  FInteger^ := AValue;
end;

function TFakeConfigurationValue.GetBoolean: Boolean;
begin
  Result := FBoolean^;
end;

procedure TFakeConfigurationValue.SetBoolean(AValue: Boolean);
begin
  FBoolean^ := AValue;
end;

function TFakeConfigurationValue.GetString: string;
begin
  Result := FString^;
end;

procedure TFakeConfigurationValue.SetString(const AValue: string);
begin
  FString^ := AValue;
end;

{ TFakeResetSink }

constructor TFakeResetSink.Create(const ACommands, ALog: TStrings);
begin
  inherited Create;
  FCommands := ACommands;
  FLog := ALog;
end;

procedure TFakeResetSink.ValueReset(const AName, ALowerName: string);
begin
  FLog.Add('Setting default value for ' + AName);
  FLog.Add('execute get ' + ALowerName);
end;

function TFakeResetSink.HasCommand(const ALowerName: string): Boolean;
begin
  Result := FCommands.IndexOf(ALowerName) >= 0;
end;

procedure TFakeResetSink.CommandReset(const AName, ALowerName: string;
  const AItem: IConfigurationItem);
const
  YES_NO: array[Boolean] of string = ('NO', 'YES');
var
  LParameter: string;
begin
  case AItem.Kind of
    cikInteger: LParameter := IntToStr(AItem.Defaults.IntegerValue);
    cikBoolean: LParameter := YES_NO[AItem.Defaults.BooleanValue];
  else
    LParameter := AItem.Defaults.StringValue;
  end;
  FLog.Add('Setting default value for ' + AName);
  FLog.Add('execute ' + ALowerName + ' ' + LParameter);
end;

end.
