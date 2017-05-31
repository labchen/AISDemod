function demodVesInfo = F_getDemodVesInfo(parTable, timeTable, allResultData, aisData)
% 获取每艘船的解调信息,包含发送信号次数，解对的次数
% 输入参数：
% vesName：timeTable中的船号
% allDataPos：timeTable中的发送时隙即每个信号的发送时隙
% allResultData：解调正确的数据
% aisData：模拟源所发送的船舶信息
% 输出参数：
% demodVesInfo：每艘船解调信息
vesName = timeTable(:, 2);
allDataPos = timeTable(:, 3);
vesNum = size(aisData, 1);
bitCol = F_calBitCol(timeTable); % 计算所有比特的冲突数
vesColTab = F_calVesCol(timeTable, bitCol); % 计算船舶冲突数
% 获取船舶的功率频偏时延DOA参数
allVes = sort(unique(timeTable(:, 2)));
vesLoc = zeros(length(allVes), 1);
for ii = 1:1:length(allVes)
    vesLoc(ii) = find(timeTable(:, 2) == allVes(ii), 1);
end
areasNo = timeTable(vesLoc, 4);
vesPar = parTable(areasNo, :);
% 计算解调出来的船舶
demodVesInfo = zeros(vesNum, 2); %第一列为发送次数，第二列为解对次数
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
title('每艘未解出船的冲突分布');
% 画图
% figure;
% plot(demodVesInfo(:, 1));
% hold on;
% plot(demodVesInfo(:, 2));
% title('船舶解调情况')
% figure;
% surf(undemodedVesCol);
% figure
% surf(undemodedVesPar);

% undemodedPos = zeros(length(undemodedVesNo), 2); % 第一列为船号,后边为发送信号的位置
% undemodedCol = zeros(length(undemodedVesNo), 2); % 第一列为船号，后边卫发送信号的冲突数
% undemodedPos(:, 1) = undemodedVesNo;
% undemodedCol(:, 1) = undemodedVesNo;
% for mm = 1:1:length(undemodedVesNo)
%     curPos = allDataPos(find(vesName ==undemodedVesNo(mm)));
%     curCol = bitCol(curPos);
end