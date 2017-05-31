function result = detectProbability(resultpath, filename, sigpath)

resultPath = uigetdir('F:\跑数据\动态\','选择AIS结果文件');
% resultPath = resultpath;
[dataFile, dataPath] = uigetfile('F:\跑数据\动态\','选择AIS数据文件');
% dataFile = filename;
% dataPath = sigpath;


allResultFiles = dir(resultPath);
flag = 1;
for ii = 3 : 1 : length(allResultFiles)
    name = allResultFiles(ii).name;
%     strMath = 'AISResult\W*\.mat';
    resultFileName{flag} = name;
    flag = flag + 1;
end

%导入AISData的数据
dataFileName = [dataPath,'\', dataFile];

load(dataFileName);
allDataLen = length(aisData);
vesName = timeTable(:, 2);
allDataPos = timeTable(:, 3);
parTableRow = timeTable(:, 4);
areasPar = parTable; % 个小区的功率频偏时延DOA
% 
% [conflict_aisData, conflict_account] = F_conflictStat(allDataPos);
% conflict_result_account = zeros(1, length(conflict_account));
[allResultData, allResultPos, allResultPar, slotResultNum] = F_readAllResult(resultPath, resultFileName);


%计算系统的解调概率
uniDemodVes = F_findRightVes(aisData, allResultData);
allVesNum = size(aisData,1);
disp('所有船舶的解调概率：');
disp(length(uniDemodVes)/allVesNum);
result = length(uniDemodVes)/allVesNum;
dlmwrite('./result.txt', result,'delimiter', '\t', '-append');

% isRight = F_findRightLoc(vesName, allDataPos, allResultPos, allResultData, aisData);
demodVesInfo = F_getDemodVesInfo(areasPar, timeTable, allResultData, aisData);
%计算各个冲突数的解调概率
% for ii = 1 : 1 : length(isRight)  
%     if (isRight(ii) == 1)
%        conflict_tmp = conflict_aisData(ii);
%        conflict_result_account(conflict_tmp) =  conflict_result_account(conflict_tmp) + 1;
%     end
% end
% 
% %画出各个冲突情况的解调个数
% figure;
% bar(conflict_result_account./conflict_account);
% grid;
% xlabel('冲突信号个数');
% ylabel('各个冲突信号的解调比率（%）');
% title('冲突信号解调个数统计(实际分布)');
% 
% 
% isRight = F_findRightLoc(vesName, allDataPos, allResultPos, allResultData, aisData);
% detectResult = 0;
% detectVes = [];
% detect_one_two_ves = [];
% powerDiff = [];
% freqOffset = [];
% delayDiff = [];
% for ii= 1 : 1 : length(isRight)
%    if(isRight(ii) == 1)
%        detectVes = [detectVes, vesName(ii)];
% %        if(conflict_aisData(ii) == 2 || conflict_aisData(ii) == 1)
% %           detect_one_two_ves = [detect_one_two_ves, vesName(ii)]; 
% %           if conflict_aisData(ii) == 2
% %             [powerDiffTmp, freqOffsetTmp, delayDiffTmp] = F_findParameter(ii, allDataPos, parTableRow, parTable);
% %             powerDiff = [powerDiff, powerDiffTmp];
% %             freqOffset = [freqOffset, freqOffsetTmp];
% %             delayDiff = [delayDiff, delayDiffTmp];
% %           end
% %        end
%        conflict_tmp = conflict_aisData(ii);
%        conflict_result_account(conflict_tmp) =  conflict_result_account(conflict_tmp) + 1;
%    end
% end
% 
% %统计二重冲突，一重冲突中一共出现多少艘船发送信号：
% oneTwoConflictVesName = [];
% for ii = 1 : 1 : length(conflict_aisData)
%    if conflict_aisData(ii) == 2 || conflict_aisData(ii) == 1
%        oneTwoConflictVesName = [oneTwoConflictVesName, vesName(ii)];
%    end
% end
% 
% detect_one_two_ves_result = unique(detect_one_two_ves);
% allOneTwoConflictVesName = unique(oneTwoConflictVesName);
% disp('一重二重冲突船舶的解调概率：');
% disp(length(detect_one_two_ves_result)/length(allOneTwoConflictVesName));
% 
% %画出各个冲突情况的解调个数
% figure;
% bar(conflict_result_account./conflict_account);
% grid;
% xlabel('冲突信号个数');
% ylabel('各个冲突信号的解调比率（%）');
% title('冲突信号解调个数统计(实际分布)');
% 
% % 画出功率差，频偏差，时延差的图形
% subplot(3,1,1);
% plot(powerDiff);
% title('功率差dB');
% xlabel('解调信号');
% ylabel('db');
% subplot(3,1,2);
% plot(freqOffset);
% title('频偏差');
% xlabel('解调信号');
% ylabel('HZ');
% subplot(3,1,3);
% plot(delayDiff);
% title('时延差');
% xlabel('解调信号');
% ylabel('bit');
% 
% % 均分的直方图
% % F_histArray(powerDiff, freqOffset, delayDiff);
% 
% end
