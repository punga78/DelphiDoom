// Replacement of Doom32.inc for the mp3 DLL and its tests.
//
// The units of MP3LIB start with {$I Doom32.inc}. The real file also sets
// application level switches ($APPTYPE GUI, $IMAGEBASE, stack sizes) that
// belong to the engine executables and would change the type of a console
// test project. This file keeps only the code generation switches of the
// original: put the folder Libs\Mp3\Shim in the include path BEFORE the
// folder of the engine and the compiler finds this file first.

{$IFNDEF FPC}
{$DEFINE DELPHI}
{$ENDIF}

{$B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$ALIGN 8}

{$IFDEF DEBUG}
{$O-}
{$ENDIF}
