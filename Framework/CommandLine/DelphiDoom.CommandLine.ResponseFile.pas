{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the response files                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.ResponseFile;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Logging.Intf,
  DelphiDoom.CommandLine.Intf;

type
  /// <summary>
  ///   Expands the response files of a command line (the old FindResponseFile of the d_main
  ///   units). The messages are the ones of the old code, to the standard output
  /// </summary>
  TResponseFileExpander = class(TInterfacedObject, IResponseFileExpander)
  strict private
    FSource: IResponseFileSource;
    FLog: ILog;
    procedure AddTokens(const AText: string; const AItems: TList<string>);
  public
    constructor Create(const ASource: IResponseFileSource; const ALog: ILog);
    function Expand(const AArguments: TArray<string>; AMaxArguments: Integer): TArray<string>;
  end;

implementation

const
  SFoundResponseFile = 'Found response file %s!'#13#10;
  SMissingResponseFile = #13#10'No such response file: %s!'#13#10;

{ TResponseFileExpander }

constructor TResponseFileExpander.Create(const ASource: IResponseFileSource; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FSource := ASource;
  FLog := ALog;
end;

procedure TResponseFileExpander.AddTokens(const AText: string; const AItems: TList<string>);
var
  LIndex: Integer;
  LStart: Integer;
begin
  // a space or a line break ends an argument; tabs do not (as in the old code)
  LStart := 1;
  for LIndex := 1 to Length(AText) + 1 do
    if (LIndex > Length(AText)) or (AText[LIndex] = ' ') or (AText[LIndex] = #13) or
      (AText[LIndex] = #10) then
    begin
      if LIndex > LStart then
        AItems.Add(Copy(AText, LStart, LIndex - LStart));
      LStart := LIndex + 1;
    end;
end;

function TResponseFileExpander.Expand(const AArguments: TArray<string>;
  AMaxArguments: Integer): TArray<string>;
var
  LItems: TList<string>;
  LKept: TList<string>;
  LIndex: Integer;
  LFileName: string;
  LText: string;
begin
  LItems := TList<string>.Create;
  LKept := TList<string>.Create;
  try
    for LIndex := 0 to High(AArguments) do
      if (LIndex > 0) and (AArguments[LIndex] <> '') and (AArguments[LIndex][1] = '@') then
      begin
        LFileName := Copy(AArguments[LIndex], 2, Length(AArguments[LIndex]) - 1);
        if FSource.TryRead(LFileName, LText) then
        begin
          FLog.Info(Format(SFoundResponseFile, [LFileName]));
          AddTokens(LText, LItems);
        end
        else
          FLog.Info(Format(SMissingResponseFile, [LFileName]));
      end
      else
        LItems.Add(AArguments[LIndex]);

    for LIndex := 0 to LItems.Count - 1 do
      if LItems[LIndex] <> '' then
      begin
        LKept.Add(LItems[LIndex]);
        if LKept.Count = AMaxArguments then
          Break;
      end;
    Result := LKept.ToArray;
  finally
    LKept.Free;
    LItems.Free;
  end;
end;

end.
