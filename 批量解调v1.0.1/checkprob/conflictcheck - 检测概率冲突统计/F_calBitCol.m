function bitColSum = F_calBitCol(allVesselsSendBit)
	global bufferSize observationTime
    debug = 1;
    if debug 
        bufferSize = 12;
        observationTime = 320;
    end
	disp('统计所有bit的冲突情况...');
	startLoc = allVesselsSendBit(:, 3);
	endLoc = min(startLoc+255-bufferSize, observationTime*9600);
	
	bitColSum = zeros(1, observationTime*9600);
	for ii = 1 : 1 : size(allVesselsSendBit, 1)
		bitColSum(startLoc(ii):endLoc(ii)) = ...
			bitColSum(startLoc(ii):endLoc(ii))+1;
	end
end 