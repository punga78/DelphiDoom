{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the message list                                  }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.MessageLog;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf;

type
  /// <summary>One line of the message list</summary>
  TIdeMessage = record
    Kind: TIdeMessageKind;
    Text: string;
  end;

  /// <summary>
  ///   What the ide has written: each line with its kind, the last IDE_MESSAGE_LIMIT of them. The
  ///   window that shows the list is told when it changes. It replaces the old global
  ///   procedure LogOutput
  /// </summary>
  TIdeMessageLog = class(TInterfacedObject, IIdeLog)
  strict private
    FMessages: TList<TIdeMessage>;
    FOnChanged: TProc;
    function GetCount: Integer;
    function GetMessage(const AIndex: Integer): TIdeMessage;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   A text of many lines is many messages. Before the new ones are added the list is cut to
    ///   leave room for them (the oldest go first)
    /// </summary>
    procedure Write(const AKind: TIdeMessageKind; const AText: string);
    procedure WriteFormat(const AKind: TIdeMessageKind; const AFormat: string;
      const AArguments: array of const);
    procedure Clear;
    /// <summary>All the lines of text, one for each message, as the "save messages" command writes them</summary>
    function AsText: string;
    property Count: Integer read GetCount;
    property Messages[const AIndex: Integer]: TIdeMessage read GetMessage; default;
    property OnChanged: TProc read FOnChanged write FOnChanged;
  end;

implementation

uses
  System.Classes;

{ TIdeMessageLog }

constructor TIdeMessageLog.Create;
begin
  inherited Create;
  FMessages := TList<TIdeMessage>.Create;
end;

destructor TIdeMessageLog.Destroy;
begin
  FMessages.Free;
  inherited Destroy;
end;

function TIdeMessageLog.GetCount: Integer;
begin
  Result := FMessages.Count;
end;

function TIdeMessageLog.GetMessage(const AIndex: Integer): TIdeMessage;
begin
  Result := FMessages[AIndex];
end;

procedure TIdeMessageLog.Write(const AKind: TIdeMessageKind; const AText: string);
var
  LLines: TStringList;
  LMessage: TIdeMessage;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    while FMessages.Count >= IDE_MESSAGE_LIMIT do
      FMessages.Delete(0);
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LMessage.Kind := AKind;
      LMessage.Text := LLines[LIndex];
      FMessages.Add(LMessage);
    end;
  finally
    LLines.Free;
  end;
  if Assigned(FOnChanged) then
    FOnChanged();
end;

procedure TIdeMessageLog.WriteFormat(const AKind: TIdeMessageKind; const AFormat: string;
  const AArguments: array of const);
begin
  Write(AKind, Format(AFormat, AArguments));
end;

procedure TIdeMessageLog.Clear;
begin
  FMessages.Clear;
  if Assigned(FOnChanged) then
    FOnChanged();
end;

function TIdeMessageLog.AsText: string;
var
  LLines: TStringList;
  LMessage: TIdeMessage;
begin
  LLines := TStringList.Create;
  try
    for LMessage in FMessages do
      LLines.Add(LMessage.Text);
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

end.
