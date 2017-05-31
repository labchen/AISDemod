function isRight = F_findRightLoc(vesName, aisDataPos, aisResultPos, aisResultData, aisData)
	os = 4;
	blockLen = 256;
	isRight = zeros(1, size(vesName, 1));		% ��ǰ֡�Ƿ���ȷ����ı�־
    
	for ii = 1 : 1 : length(aisResultData)
		% �������н����ȷ֡�Ĵ���
		curData = aisResultData{ii};
		curData(curData == ' ') = [];
		if length(curData) <= size(aisData, 2) && length(curData) >= 168
			curData = curData - 48;		% ת��Ϊdouble��, ������ԭ��Ϣ���Ƿ����
			rightVes = find(all(aisData(:,1:168) == repmat(curData(1:168), size(aisData, 1), 1), 2), 1);	% ���Ҵ���
			if ~isempty(rightVes)
				% ��Ե�֡��ԭ��Ϣ�д���, ���Ҷ�Ӧ֡�ķ���ʱ��
				frameStartLoc = find(aisDataPos * os >= aisResultPos(ii, 1) -  3 * blockLen * os & ...
					aisDataPos * os <= aisResultPos(ii, 1) +  3 * blockLen * os - 1);	% �ҵ���ǰ�������Ϣ��ʱ����п��ܵ�λ��
				rightLoc = vesName(frameStartLoc) == rightVes;			% ȷ���������֡��ԭ��Ϣ�е�λ��
				isRight(frameStartLoc(rightLoc)) = 1;
			end
		end
	end
end