function [allData, allPos, allPar, slotNum] = F_readAllResult(resultPath, sigFiles)
	% 拼接所有信号结果, 要求一个文件夹下所有结果是出自一次观测得到的, 否则会出现错误
    global flag1
	allData = [];
	allPos = [];
	slotNum = 0;
	allPar = [];
	lastLen = 0;
	os = 4;
	blockLen = 256;
	for ii = 1 : 1 : length(sigFiles)
		load([resultPath, '/', sigFiles{ii}]);		% demodResult: data, pos, slotNum, par
		% 读取当前文件的内容
        if exist('demodResult')
            flag1 = 1;
            allData = [allData, demodResult.data];
            allPos = [allPos; [demodResult.pos(:, 1) + lastLen, demodResult.pos(:, 2:end)]];
            slotNum = slotNum + demodResult.slotNum;
            if isfield(demodResult, 'par') == 1
                % 兼容旧版本, 旧版本程序解调出没有par这个字段
                allPar = [allPar; demodResult.par];
            end
            lastLen = lastLen + (slotNum + 1) * os * blockLen;
        else
            flag1 = 0;
        end
    end
    if 1 == flag1
        allSlotNum = length(allData);
        % 删除重复解调的帧, 3时隙内内容解调内容相同的帧判断为重复帧
        locDelete = zeros(1, allSlotNum);
        for ii = 1 : 1 : allSlotNum
            if locDelete(ii) == 0
                curData = allData{ii};
                frameCheckLoc = find(allPos(:, 1) >= allPos(ii, 1) & allPos(:, 1) <= allPos(ii, 1) + 3 * blockLen * os - 1);
                for jj = 1 : 1 : length(frameCheckLoc)
                    % 除去当前时隙外, 判断其他可能重复的时隙
                    if frameCheckLoc(jj) ~= ii
                        if strcmp(allData{frameCheckLoc(jj)}, curData) == 1
                            locDelete(frameCheckLoc(jj)) = 1;
                        end
                    end
                end
            end 
        end
        
        locDel = find(locDelete == 1);

        allData(locDel) = [];
        allPos(locDel, :) = [];
        if isfield(demodResult, 'par') == 1
            % 兼容旧版本, 旧版本程序解调出没有par这个字段
            allPar(locDel, :) = [];
        end            
    else
        errStr = [sigFiles{ii}, '文件存储数据错误，请确认文件中含有正确的变量信息'];
        errordlg(errStr, '输入文件存储数据错误');
    end
end