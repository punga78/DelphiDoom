{******************************************************************************}
{                                                                              }
{  DelphiDoom: fake client of the line editing of the Quake III console        }
{                                                                              }
{  Key state, clipboard, scrolling and connection state in one fake, with the  }
{  lines that Tools\Verifica\113q3\fieldops.inc prints for the same calls.     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.FieldHost;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.Field.Intf;

type
  /// <summary>The state of the keys, the clipboard, the connection and the scrolling, written by the test</summary>
  TFakeQ3FieldHost = class(TInterfacedObject, IQ3KeyState, IQ3Clipboard, IQ3ConsoleScroller, IQ3ClientState)
  strict private
    FLog: IQ3ConsoleLog;
    FDown: array[0..255] of Boolean;
    FClipboard: AnsiString;
    FHasClipboard: Boolean;
    FState: Integer;
    FUpdates: Integer;
  public
    constructor Create(const ALog: IQ3ConsoleLog);
    procedure SetKey(AKey: Integer; ADown: Boolean);
    procedure SetClipboard(const AText: AnsiString);
    procedure ClearClipboard;
    /// <summary>0 is "disconnected", 1 is "active" (the C driver sets cls.state the same way)</summary>
    procedure SetConnection(AActive: Boolean; ADisconnected: Boolean);
    function IsDown(AKey: Integer): Boolean;
    function TryGetText(out AText: AnsiString): Boolean;
    procedure PageUp;
    procedure PageDown;
    procedure Top;
    procedure Bottom;
    function IsActive: Boolean;
    function IsDisconnected: Boolean;
    procedure UpdateScreen;
    property Updates: Integer read FUpdates;
  end;

implementation

{ TFakeQ3FieldHost }

constructor TFakeQ3FieldHost.Create(const ALog: IQ3ConsoleLog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TFakeQ3FieldHost.SetKey(AKey: Integer; ADown: Boolean);
begin
  FDown[AKey and 255] := ADown;
end;

procedure TFakeQ3FieldHost.SetClipboard(const AText: AnsiString);
begin
  FClipboard := AText;
  FHasClipboard := True;
end;

procedure TFakeQ3FieldHost.ClearClipboard;
begin
  FClipboard := '';
  FHasClipboard := False;
end;

procedure TFakeQ3FieldHost.SetConnection(AActive: Boolean; ADisconnected: Boolean);
begin
  FState := Ord(AActive) * 2 + Ord(ADisconnected);
end;

function TFakeQ3FieldHost.IsDown(AKey: Integer): Boolean;
begin
  Result := FDown[AKey and 255];
end;

function TFakeQ3FieldHost.TryGetText(out AText: AnsiString): Boolean;
begin
  AText := FClipboard;
  Result := FHasClipboard;
end;

procedure TFakeQ3FieldHost.PageUp;
begin
  FLog.Print('[PageUp]'#10);
end;

procedure TFakeQ3FieldHost.PageDown;
begin
  FLog.Print('[PageDown]'#10);
end;

procedure TFakeQ3FieldHost.Top;
begin
  FLog.Print('[Top]'#10);
end;

procedure TFakeQ3FieldHost.Bottom;
begin
  FLog.Print('[Bottom]'#10);
end;

function TFakeQ3FieldHost.IsActive: Boolean;
begin
  Result := FState and 2 <> 0;
end;

function TFakeQ3FieldHost.IsDisconnected: Boolean;
begin
  Result := FState and 1 <> 0;
end;

procedure TFakeQ3FieldHost.UpdateScreen;
begin
  Inc(FUpdates);
  FLog.Print('[UpdateScreen]'#10);
end;

end.
