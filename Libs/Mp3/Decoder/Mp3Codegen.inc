// Code generation switches of the mp3 decoder (issue #224).
//
// This file replaces Common\Doom32.inc for Libs\Mp3: it keeps only the code
// generation switches of the original (the application level ones, $APPTYPE GUI,
// $IMAGEBASE and the stack sizes, belong to the executables) so that the
// library does not need the folder Common.

{$IFNDEF FPC}
{$DEFINE DELPHI}
{$ENDIF}

{$B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$ALIGN 8}

{$IFDEF DEBUG}
{$O-}
{$ENDIF}
