function uniDemodVes = F_findRightVes(aisData, allResultData)
    os = 4;
    demodVes = [];
	for ii = 1 : 1 : length(allResultData)
		% �������н����ȷ֡�Ĵ���
		curData = allResultData{ii};
		curData(curData == ' ') = [];
		if length(curData) <= size(aisData, 2) && length(curData) >= 168
			curData = curData - 48;		% ת��Ϊdouble��, ������ԭ��Ϣ���Ƿ����
			rightVes = find(all(aisData(:,1:168) == repmat(curData(1:168), size(aisData, 1), 1), 2), 1);	% ���Ҵ���
            demodVes = [demodVes, rightVes];
		end
    end
    uniDemodVes = unique(demodVes);
end