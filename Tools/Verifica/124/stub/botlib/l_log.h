/* Stub of l_log.h: the log of the harness goes to the output with the prefix L| */
void Log_Write(char *fmt, ...);
void Log_Print(char *fmt, ...);
FILE *Log_FilePointer(void);
