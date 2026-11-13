/* Lists the frames and chunks of a FLIC file (issue #199): a diagnostic, not a decoder. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef unsigned char u8; typedef unsigned short u16; typedef unsigned int u32;
static u16 r16(const u8 *p){return p[0]|(p[1]<<8);}
static u32 r32(const u8 *p){return p[0]|(p[1]<<8)|(p[2]<<16)|((u32)p[3]<<24);}
int main(int argc,char**argv){
  FILE*f=fopen(argv[1],"rb"); if(!f)return 1; fseek(f,0,SEEK_END); long n=ftell(f); fseek(f,0,SEEK_SET);
  u8*d=malloc(n); fread(d,1,n,f); fclose(f);
  int counts[64]={0}; int ftypes[3]={0}; int multi=0,skipfirst=0,delayov=0;
  printf("size %u magic %04X frames %u %ux%u depth %u flags %u speed %u\n",r32(d),r16(d+4),r16(d+6),r16(d+8),r16(d+10),r16(d+12),r16(d+14),r32(d+16));
  long pos=128;
  while(pos+16<=n){
    u32 s=r32(d+pos); u16 t=r16(d+pos+4);
    if(t==0xF1FA){ ftypes[0]++; u16 c=r16(d+pos+6); if(r16(d+pos+8))delayov++; long p=pos+16;
      for(int i=0;i<c;i++){ u32 cs=r32(d+p); u16 ct=r16(d+p+4); if(ct<64)counts[ct]++;
        if(ct==4||ct==11){ u16 np=r16(d+p+6); if(np>1)multi++; if(np>=1&&d[p+8]!=0)skipfirst++; }
        p+=cs; }
    } else if(t==0xF100)ftypes[1]++; else ftypes[2]++;
    pos+=s; }
  printf("frames %d prefix %d other %d delayoverride %d end %s\n",ftypes[0],ftypes[1],ftypes[2],delayov,pos==n?"exact":"MISMATCH");
  for(int i=0;i<64;i++)if(counts[i])printf("chunk %d: %d\n",i,counts[i]);
  printf("palette chunks with several packets: %d, first packet with skip != 0: %d\n",multi,skipfirst);
  return 0; }
