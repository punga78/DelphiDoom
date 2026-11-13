{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 command system, the text buffer      }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CmdSystem.cpp              }
{  (InsertCommandText, AppendCommandText, ExecuteCommandBuffer).               }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CmdSystem.Buffer;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs;

type
  /// <summary>What the buffer does with each line it pulled: tokenized and ready to run</summary>
  TCmdExecuteTokenized = procedure(const AArgs: TIdCmdArgs) of object;

  /// <summary>
  ///   The command text of idCmdSystemLocal: text of at most 64 KB, lines ended by a line feed, a
  ///   carriage return or a semicolon outside quotes, the wait counter, and the tokenized commands
  ///   that piggyback on the text ("_execTokenized"). The text is bytes (AnsiString), as the
  ///   original is.
  /// </summary>
  TCmdBuffer = class
  strict private
    FLog: IIdLibLog;
    FCVars: IIdLibCVars;
    FRun: TCmdExecuteTokenized;
    FText: AnsiString;
    FWait: Integer;
    FTokenized: TObjectList<TIdCmdArgs>;
    function CTextLength(const AText: AnsiString): Integer;
  public
    /// <summary>
    ///   ARun runs a tokenized command; the cvars (optional) expand "$name" in the lines
    /// </summary>
    constructor Create(const ARun: TCmdExecuteTokenized; const ALog: IIdLibLog = nil; const ACVars: IIdLibCVars = nil);
    destructor Destroy; override;
    /// <summary>InsertCommandText: adds the text and a line feed at the start of the buffer</summary>
    procedure InsertText(const AText: AnsiString);
    /// <summary>AppendCommandText: adds the text at the end, without a line feed</summary>
    procedure AppendText(const AText: AnsiString);
    /// <summary>
    ///   Appends "_execTokenized" and remembers a copy of the arguments for when the line comes
    ///   (BufferCommandArgs with CMD_EXEC_APPEND)
    /// </summary>
    procedure AppendTokenized(const AArgs: TIdCmdArgs);
    /// <summary>ExecuteCommandBuffer</summary>
    procedure Execute;
    procedure SetWait(const AFrames: Integer);
    /// <summary>The text still in the buffer</summary>
    function PendingText: AnsiString;
    /// <summary>Empties the buffer, the tokenized commands and the wait</summary>
    procedure Clear;
  end;

const
  /// <summary>The line that stands for a tokenized command</summary>
  CMD_TOKENIZED_MARK = '_execTokenized';

implementation

uses
  DelphiDoom.Console.CmdSystem.Types;

{ TCmdBuffer }

constructor TCmdBuffer.Create(const ARun: TCmdExecuteTokenized; const ALog: IIdLibLog; const ACVars: IIdLibCVars);
begin
  inherited Create;
  FRun := ARun;
  FLog := ALog;
  FCVars := ACVars;
  FTokenized := TObjectList<TIdCmdArgs>.Create(True);
end;

destructor TCmdBuffer.Destroy;
begin
  FTokenized.Free;
  inherited Destroy;
end;

function TCmdBuffer.CTextLength(const AText: AnsiString): Integer;
var
  LNul: Integer;
begin
  // strlen: the text of a C string ends at the first NUL
  LNul := Pos(#0, string(AText));
  if LNul > 0 then
    Result := LNul - 1
  else
    Result := Length(AText);
end;

procedure TCmdBuffer.InsertText(const AText: AnsiString);
var
  LText: AnsiString;
  LLength: Integer;
begin
  LText := Copy(AText, 1, CTextLength(AText));
  LLength := Length(LText) + 1;
  if LLength + Length(FText) > CMD_MAX_BUFFER then
  begin
    if Assigned(FLog) then
      FLog.Printf('idCmdSystemLocal::InsertText: buffer overflow'#10);
    Exit;
  end;
  FText := LText + #10 + FText;
end;

procedure TCmdBuffer.AppendText(const AText: AnsiString);
var
  LText: AnsiString;
begin
  LText := Copy(AText, 1, CTextLength(AText));
  if Length(FText) + Length(LText) >= CMD_MAX_BUFFER then
  begin
    if Assigned(FLog) then
      FLog.Printf('idCmdSystemLocal::AppendText: buffer overflow'#10);
    Exit;
  end;
  FText := FText + LText;
end;

procedure TCmdBuffer.AppendTokenized(const AArgs: TIdCmdArgs);
var
  LCopy: TIdCmdArgs;
begin
  AppendText(CMD_TOKENIZED_MARK + #10);
  LCopy := TIdCmdArgs.Create(FCVars);
  LCopy.Assign(AArgs);
  FTokenized.Add(LCopy);
end;

procedure TCmdBuffer.Execute;
var
  LArgs: TIdCmdArgs;
  LIndex, LQuotes: Integer;
  LLine: AnsiString;
begin
  LArgs := TIdCmdArgs.Create(FCVars);
  try
    while Length(FText) > 0 do
    begin
      if FWait <> 0 then
      begin
        // skip out while text still remains in buffer, leaving it for next frame
        Dec(FWait);
        Break;
      end;

      // find a line feed or ; line break
      LQuotes := 0;
      LIndex := 1;
      while LIndex <= Length(FText) do
      begin
        if FText[LIndex] = '"' then
          Inc(LQuotes);
        if ((LQuotes and 1) = 0) and (FText[LIndex] = ';') then
          Break; // don't break if inside a quoted string
        if (FText[LIndex] = #10) or (FText[LIndex] = #13) then
          Break;
        Inc(LIndex);
      end;

      LLine := Copy(FText, 1, LIndex - 1);
      LLine := Copy(LLine, 1, CTextLength(LLine));

      if (LLine = CMD_TOKENIZED_MARK) and (FTokenized.Count > 0) then
      begin
        LArgs.Assign(FTokenized[0]);
        FTokenized.Delete(0);
      end
      else
        LArgs.TokenizeString(LLine, False);

      // delete the text from the command buffer: commands (exec) can insert data at the
      // beginning of the text buffer
      if LIndex > Length(FText) then
        FText := ''
      else
        Delete(FText, 1, LIndex);

      // execute the command line that we have already tokenized
      FRun(LArgs);
    end;
  finally
    LArgs.Free;
  end;
end;

procedure TCmdBuffer.SetWait(const AFrames: Integer);
begin
  FWait := AFrames;
end;

function TCmdBuffer.PendingText: AnsiString;
begin
  Result := FText;
end;

procedure TCmdBuffer.Clear;
begin
  FText := '';
  FWait := 0;
  FTokenized.Clear;
end;

end.
