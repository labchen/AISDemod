function seqOut = F_deNRZI(seqIn, zeroNum, revFlag)
% ----
% 本函数用来解NRZI编码
% 输入:
%	sigIn:输入信号为NRZI编码的二进制序列{-1 1}
%	zeroNum:差分时补零个数
%	revFlag:是否先进行序列翻转
% 输出:
%	sigOut:输出信号为解编码后的二进制序列{1 0}
% ----
	global DecodLenth
	if ~exist('revFlag', 'var')
		revFlag = 1;
	end
	if revFlag == 1
		seqIn = seqIn<0;
	end
	% 差分译码
	seqOut = mod(seqIn+[zeros(size(seqIn,1),zeroNum),seqIn(:,1:DecodLenth-zeroNum)], 2);
	% 反转比特
	seqOut = 1 - seqOut;
end