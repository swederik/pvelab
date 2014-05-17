function FixAnalyzeHdr_OkCancelReturn(nr);

global FinalResult

if nargin == 1
	uiresume(gcf);	
	FinalResult = nr;
end;