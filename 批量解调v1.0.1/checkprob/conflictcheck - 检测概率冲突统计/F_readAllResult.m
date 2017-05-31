function [allData, allPos, allPar, slotNum] = F_readAllResult(resultPath, sigFiles)
	% ƴ�������źŽ��, Ҫ��һ���ļ��������н���ǳ���һ�ι۲�õ���, �������ִ���
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
		% ��ȡ��ǰ�ļ�������
        if exist('demodResult')
            flag1 = 1;
            allData = [allData, demodResult.data];
            allPos = [allPos; [demodResult.pos(:, 1) + lastLen, demodResult.pos(:, 2:end)]];
            slotNum = slotNum + demodResult.slotNum;
            if isfield(demodResult, 'par') == 1
                % ���ݾɰ汾, �ɰ汾��������û��par����ֶ�
                allPar = [allPar; demodResult.par];
            end
            lastLen = lastLen + (slotNum + 1) * os * blockLen;
        else
            flag1 = 0;
        end
    end
    if 1 == flag1
        allSlotNum = length(allData);
        % ɾ���ظ������֡, 3ʱ϶�����ݽ��������ͬ��֡�ж�Ϊ�ظ�֡
        locDelete = zeros(1, allSlotNum);
        for ii = 1 : 1 : allSlotNum
            if locDelete(ii) == 0
                curData = allData{ii};
                frameCheckLoc = find(allPos(:, 1) >= allPos(ii, 1) & allPos(:, 1) <= allPos(ii, 1) + 3 * blockLen * os - 1);
                for jj = 1 : 1 : length(frameCheckLoc)
                    % ��ȥ��ǰʱ϶��, �ж����������ظ���ʱ϶
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
            % ���ݾɰ汾, �ɰ汾��������û��par����ֶ�
            allPar(locDel, :) = [];
        end            
    else
        errStr = [sigFiles{ii}, '�ļ��洢���ݴ�����ȷ���ļ��к�����ȷ�ı�����Ϣ'];
        errordlg(errStr, '�����ļ��洢���ݴ���');
    end
end