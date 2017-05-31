function [powerDiff, freqOffset, delayDiff] = F_findParameter(index, allDataPos, parRow, parTable)
%�������indexΪ��ͻ�źű�ţ�parRow = timeTable��ii��4��
%�����س�ͻ�źŵĹ��ʡ�Ƶƫ��ʱ�Ӳ�
    sigLen = 256;
    [row,col] = find(abs(allDataPos(:,1)-allDataPos(index))<sigLen);%�ҵ��к�index�ź��и���ͻ�źŵ��кţ�rowӦΪ2--��ʾ��ͻ��
     
%   sigPower = zeros(1,length(row));
%   confParTableRow = zeros(1,length(row));
    sigPower = zeros(1,2);
    confParTableRow = zeros(1,2);
    for ii = 1 : 1 : 2
        confParTableRow = parRow(row(ii),1);%�ҵ����س�ͻ�ź���parTable�е��к�
        sigPower(ii) = parTable(confParTableRow,1);
        sigFreq(ii) = parTable(confParTableRow,2);
        sigDelay(ii) = parTable(confParTableRow,3);
    end
       powerDiff = abs(sigPower(2) - sigPower(1));
       freqOffset = abs(sigFreq(2) - sigFreq(1));
       delayDiff = abs(sigDelay(2) - sigDelay(1));

    
    
end