function vesColTab = F_calVesCol(allVesselsSendBit, bitColSum)
	global observationTime transInterval bufferSize
    debug = 1;
    if debug 
        transInterval = 2;
        observationTime = 320;
        bufferSize = 12;
    end
	ves = allVesselsSendBit(:, 2).';			% ���д��Ĵ���
	startBit = allVesselsSendBit(:, 3).';		% ���д��ķ���ʱ��
	endBit = min(startBit+255-bufferSize, observationTime*9600);
	vesNum = max(unique(ves));			% �ܴ���
% 	clear allVesselsSendBit;
	
	% ���д����η��͵ĳ�ͻ��
	vesColTab = zeros(vesNum, floor(observationTime/transInterval));
    packageNum = 0;
	for vIdx = 1 : 1 : vesNum
		loc = find(ves == vIdx);
        if isempty(loc)
            continue;
        end
        packageNum = packageNum + length(loc);
		for seq = 1 : 1 : length(loc)
			vesColTab(vIdx, seq) = max(bitColSum(startBit(loc(seq)):endBit(loc(seq))));
		end
	end
end