{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the speed library - fakes                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.Fakes;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Logging.Intf;

type
  /// <summary>A log that keeps the warnings and the errors, one per line</summary>
  TFakeLog = class(TInterfacedObject, ILog)
  strict private
    FWarnings: TStringList;
    FErrors: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: TStringList read FWarnings;
    property Errors: TStringList read FErrors;
  end;

implementation

{ TFakeLog }

constructor TFakeLog.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
  FErrors := TStringList.Create;
end;

destructor TFakeLog.Destroy;
begin
  FErrors.Free;
  FWarnings.Free;
  inherited Destroy;
end;

procedure TFakeLog.Info(const AText: string);
begin
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TFakeLog.Error(const AText: string);
begin
  FErrors.Add(AText);
end;

end.
