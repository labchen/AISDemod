function [powerDiff, freqOffset, delayDiff] = F_findParameter(index, allDataPos, parRow, parTable)
%输入参数index为冲突信号编号，parRow = timeTable（ii，4）
%找两重冲突信号的功率、频偏、时延差
    sigLen = 256;
    [row,col] = find(abs(allDataPos(:,1)-allDataPos(index))<sigLen);%找到行号index信号中各冲突信号的行号，row应为2--表示冲突数
     
%   sigPower = zeros(1,length(row));
%   confParTableRow = zeros(1,length(row));
    sigPower = zeros(1,2);
    confParTableRow = zeros(1,2);
    for ii = 1 : 1 : 2
        confParTableRow = parRow(row(ii),1);%找到二重冲突信号在parTable中的行号
        sigPower(ii) = parTable(confParTableRow,1);
        sigFreq(ii) = parTable(confParTableRow,2);
        sigDelay(ii) = parTable(confParTableRow,3);
    end
       powerDiff = abs(sigPower(2) - sigPower(1));
       freqOffset = abs(sigFreq(2) - sigFreq(1));
       delayDiff = abs(sigDelay(2) - sigDelay(1));

    
    
end