function uniDemodVes = F_findRightVes(aisData, allResultData)
    os = 4;
    demodVes = [];
	for ii = 1 : 1 : length(allResultData)
		% 查找所有解调正确帧的船号
		curData = allResultData{ii};
		curData(curData == ' ') = [];
		if length(curData) <= size(aisData, 2) && length(curData) >= 168
			curData = curData - 48;		% 转换为double型, 并查找原信息中是否存在
			rightVes = find(all(aisData(:,1:168) == repmat(curData(1:168), size(aisData, 1), 1), 2), 1);	% 查找船号
            demodVes = [demodVes, rightVes];
		end
    end
    uniDemodVes = unique(demodVes);
end