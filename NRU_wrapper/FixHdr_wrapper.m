function project=FixHdr_wrapper(project,Task,Method);
FixAnalyzeHdr;
project=logProject('FixAnalyzeHdr-tool launched...',project,Task,Method);
return