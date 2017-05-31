function seqOut = F_deNRZI(seqIn, zeroNum, revFlag)
% ----
% ������������NRZI����
% ����:
%	sigIn:�����ź�ΪNRZI����Ķ���������{-1 1}
%	zeroNum:���ʱ�������
%	revFlag:�Ƿ��Ƚ������з�ת
% ���:
%	sigOut:����ź�Ϊ������Ķ���������{1 0}
% ----
	global DecodLenth
	if ~exist('revFlag', 'var')
		revFlag = 1;
	end
	if revFlag == 1
		seqIn = seqIn<0;
	end
	% �������
	seqOut = mod(seqIn+[zeros(size(seqIn,1),zeroNum),seqIn(:,1:DecodLenth-zeroNum)], 2);
	% ��ת����
	seqOut = 1 - seqOut;
end