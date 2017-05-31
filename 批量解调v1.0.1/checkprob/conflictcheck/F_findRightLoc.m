function isRight = F_findRightLoc(vesName, aisDataPos, aisResultPos, aisResultData, aisData)
	os = 4;
	blockLen = 256;
	isRight = zeros(1, size(vesName, 1));		% 当前帧是否被正确解调的标志
    
	for ii = 1 : 1 : length(aisResultData)
		% 查找所有解调正确帧的船号
		curData = aisResultData{ii};
		curData(curData == ' ') = [];
		if length(curData) <= size(aisData, 2) && length(curData) >= 168
			curData = curData - 48;		% 转换为double型, 并查找原信息中是否存在
			rightVes = find(all(aisData(:,1:168) == repmat(curData(1:168), size(aisData, 1), 1), 2), 1);	% 查找船号
			if ~isempty(rightVes)
				% 解对的帧在原信息中存在, 查找对应帧的发送时间
				frameStartLoc = find(aisDataPos * os >= aisResultPos(ii, 1) -  3 * blockLen * os & ...
					aisDataPos * os <= aisResultPos(ii, 1) +  3 * blockLen * os - 1);	% 找到当前解调出信息在时间表中可能的位置
				rightLoc = vesName(frameStartLoc) == rightVes;			% 确定解调出的帧在原信息中的位置
				isRight(frameStartLoc(rightLoc)) = 1;
			end
		end
	end
end