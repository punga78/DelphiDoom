{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the thread runners ask of the engine              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Threading.Services;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Threading.Intf;

type
  /// <summary>
  ///   One object that answers the two contracts of the thread runners: the messages go to
  ///   I_Warning and I_Error, and the memory primitives are the ones of d_delphi (so a chunk is
  ///   filled exactly as the single thread fills it)
  /// </summary>
  TEngineThreadServices = class(TInterfacedObject, IWorkerMessages, IWorkerMemoryOps)
  public
    procedure Warning(const AText: string);
    procedure Error(const AText: string);
    procedure Zero(ADest: Pointer; ACount: Integer);
    procedure Fill(ADest: Pointer; AValue, ACount: Integer);
    procedure FillInteger(ADest: Pointer; AValue, ACount: Integer);
    procedure Copy(ADest, ASource: Pointer; ACount: Integer);
  end;

implementation

uses
  d_delphi,
  i_system;

{ TEngineThreadServices }

procedure TEngineThreadServices.Warning(const AText: string);
begin
  I_Warning(AText);
end;

procedure TEngineThreadServices.Error(const AText: string);
begin
  I_Error(AText);
end;

procedure TEngineThreadServices.Zero(ADest: Pointer; ACount: Integer);
begin
  d_delphi.ZeroMemory(ADest, ACount);
end;

procedure TEngineThreadServices.Fill(ADest: Pointer; AValue, ACount: Integer);
begin
  memset(ADest, AValue, ACount);
end;

procedure TEngineThreadServices.FillInteger(ADest: Pointer; AValue, ACount: Integer);
begin
  memseti(ADest, AValue, ACount);
end;

procedure TEngineThreadServices.Copy(ADest, ASource: Pointer; ACount: Integer);
begin
  memcpy(ADest, ASource, ACount);
end;

end.
