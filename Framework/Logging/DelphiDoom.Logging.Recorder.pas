{******************************************************************************}
{                                                                              }
{  DelphiDoom: logging library - a sink that remembers                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Logging.Recorder;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Types, DelphiDoom.Logging.Intf;

type
  /// <summary>One message that was written</summary>
  TLogEntry = record
    Channel: TLogChannel;
    Text: string;
  end;

  /// <summary>A sink that keeps what it receives: for the tests, and for the output before the files exist</summary>
  TLogRecorder = class(TInterfacedObject, ILogSink)
  private
    FEntries: TList<TLogEntry>;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TLogEntry;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Write(AChannel: TLogChannel; const AText: string);
    /// <summary>The texts of a channel, one after the other</summary>
    function TextOf(AChannel: TLogChannel): string;
    procedure Clear;
    property Count: Integer read GetCount;
    property Entries[AIndex: Integer]: TLogEntry read GetEntry; default;
  end;

implementation

{ TLogRecorder }

constructor TLogRecorder.Create;
begin
  inherited Create;
  FEntries := TList<TLogEntry>.Create;
end;

destructor TLogRecorder.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

function TLogRecorder.GetCount: Integer;
begin
  Result := FEntries.Count;
end;

function TLogRecorder.GetEntry(AIndex: Integer): TLogEntry;
begin
  Result := FEntries[AIndex];
end;

procedure TLogRecorder.Write(AChannel: TLogChannel; const AText: string);
var
  LEntry: TLogEntry;
begin
  LEntry.Channel := AChannel;
  LEntry.Text := AText;
  FEntries.Add(LEntry);
end;

function TLogRecorder.TextOf(AChannel: TLogChannel): string;
var
  LEntry: TLogEntry;
begin
  Result := '';
  for LEntry in FEntries do
    if LEntry.Channel = AChannel then
      Result := Result + LEntry.Text;
end;

procedure TLogRecorder.Clear;
begin
  FEntries.Clear;
end;

end.
