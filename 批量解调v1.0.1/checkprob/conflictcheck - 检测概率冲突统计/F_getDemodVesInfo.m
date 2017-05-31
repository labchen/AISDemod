function demodVesInfo = F_getDemodVesInfo(parTable, timeTable, allResultData, aisData)
% ��ȡÿ�Ҵ��Ľ����Ϣ,���������źŴ�������ԵĴ���
% ���������
% vesName��timeTable�еĴ���
% allDataPos��timeTable�еķ���ʱ϶��ÿ���źŵķ���ʱ϶
% allResultData�������ȷ������
% aisData��ģ��Դ�����͵Ĵ�����Ϣ
% ���������
% demodVesInfo��ÿ�Ҵ������Ϣ
vesName = timeTable(:, 2);
allDataPos = timeTable(:, 3);
vesNum = size(aisData, 1);
bitCol = F_calBitCol(timeTable); % �������б��صĳ�ͻ��
vesColTab = F_calVesCol(timeTable, bitCol); % ���㴬����ͻ��
% ��ȡ�����Ĺ���Ƶƫʱ��DOA����
allVes = sort(unique(timeTable(:, 2)));
vesLoc = zeros(length(allVes), 1);
for ii = 1:1:length(allVes)
    vesLoc(ii) = find(timeTable(:, 2) == allVes(ii), 1);
end
areasNo = timeTable(vesLoc, 4);
vesPar = parTable(areasNo, :);
% �����������Ĵ���
demodVesInfo = zeros(vesNum, 2); %��һ��Ϊ���ʹ������ڶ���Ϊ��Դ���
for ii = 1:1:vesNum
    demodVesInfo(ii, 1) = length(find(vesName == ii));
    curAisData = aisData(ii, 1:168);
    for jj = 1:1:length(allResultData)
        curData = allResultData{jj};
        curData(curData == ' ') = [];
        if length(curData) <= size(aisData, 2) && length(curData) >= 168
            curData = curData(1:168) - 48;
            if curData == curAisData
                demodVesInfo(ii, 2) = demodVesInfo(ii, 2) + 1;
            end
        end
    end
end
undemodedVesNo = find(demodVesInfo(:, 2) == 0);
undemodedVesCol = vesColTab(undemodedVesNo, :);
undemodedVesPar = vesPar(undemodedVesNo, :);
conflict = zeros(length(undemodedVesNo), 5);
for ii = 1:1:length(undemodedVesNo)
    curCol = undemodedVesCol(ii, 1:demodVesInfo(undemodedVesNo(ii), 1));
    conflict(ii, :) = [length(find(curCol == 1)), length(find(curCol == 2)),...
        length(find(curCol == 3)), length(find(curCol ==4)), length(find(curCol >= 5))];
end
plot(1:length(undemodedVesNo), conflict(:, 1), '-o', 1:length(undemodedVesNo), conflict(:, 2), '-o',...
    1:length(undemodedVesNo), conflict(:, 3), '-o', 1:length(undemodedVesNo), conflict(:, 4), '-o',...
    1:length(undemodedVesNo), conflict(:, 5), '-o');
legend('conflict = 1', 'conflict = 2', 'conflict = 3', 'conflict = 4', 'conflict >= 5');
title('ÿ��δ������ĳ�ͻ�ֲ�');
% ��ͼ
% figure;
% plot(demodVesInfo(:, 1));
% hold on;
% plot(demodVesInfo(:, 2));
% title('����������')
% figure;
% surf(undemodedVesCol);
% figure
% surf(undemodedVesPar);

% undemodedPos = zeros(length(undemodedVesNo), 2); % ��һ��Ϊ����,���Ϊ�����źŵ�λ��
% undemodedCol = zeros(length(undemodedVesNo), 2); % ��һ��Ϊ���ţ�����������źŵĳ�ͻ��
% undemodedPos(:, 1) = undemodedVesNo;
% undemodedCol(:, 1) = undemodedVesNo;
% for mm = 1:1:length(undemodedVesNo)
%     curPos = allDataPos(find(vesName ==undemodedVesNo(mm)));
%     curCol = bitCol(curPos);
end