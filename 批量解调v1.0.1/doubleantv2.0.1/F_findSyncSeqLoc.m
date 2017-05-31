function startIndex = F_findDataLoc(decSeq)
% ----
% �˺������ҽ�����������Ϣ��ͬ��λλ��
% ����:
%	decSeq:��������������
% ���:
%	startIndex:��Ϣ��ʼλ��
% ----
	global StartFlag FlagLength TrainingLength RisingLength
	
	idx = 1;
	while idx+FlagLength-1 <= length(decSeq)
		if sum(decSeq(idx:idx+7) == StartFlag) >= 7
			startIndex = idx+FlagLength;
			if startIndex > TrainingLength+FlagLength
				break;
			else
				idx = idx+1;
			end
		else
			if idx > 50
				startIndex = RisingLength+TrainingLength+FlagLength+1;
				break;
			else
				idx = idx+1;
			end
		end
	end
end