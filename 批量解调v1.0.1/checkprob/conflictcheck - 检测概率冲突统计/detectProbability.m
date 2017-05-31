function result = detectProbability(resultpath, filename, sigpath)

resultPath = uigetdir('F:\������\��̬\','ѡ��AIS����ļ�');
% resultPath = resultpath;
[dataFile, dataPath] = uigetfile('F:\������\��̬\','ѡ��AIS�����ļ�');
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

%����AISData������
dataFileName = [dataPath,'\', dataFile];

load(dataFileName);
allDataLen = length(aisData);
vesName = timeTable(:, 2);
allDataPos = timeTable(:, 3);
parTableRow = timeTable(:, 4);
areasPar = parTable; % ��С���Ĺ���Ƶƫʱ��DOA
% 
% [conflict_aisData, conflict_account] = F_conflictStat(allDataPos);
% conflict_result_account = zeros(1, length(conflict_account));
[allResultData, allResultPos, allResultPar, slotResultNum] = F_readAllResult(resultPath, resultFileName);


%����ϵͳ�Ľ������
uniDemodVes = F_findRightVes(aisData, allResultData);
allVesNum = size(aisData,1);
disp('���д����Ľ�����ʣ�');
disp(length(uniDemodVes)/allVesNum);
result = length(uniDemodVes)/allVesNum;
dlmwrite('./result.txt', result,'delimiter', '\t', '-append');

% isRight = F_findRightLoc(vesName, allDataPos, allResultPos, allResultData, aisData);
demodVesInfo = F_getDemodVesInfo(areasPar, timeTable, allResultData, aisData);
%���������ͻ���Ľ������
% for ii = 1 : 1 : length(isRight)  
%     if (isRight(ii) == 1)
%        conflict_tmp = conflict_aisData(ii);
%        conflict_result_account(conflict_tmp) =  conflict_result_account(conflict_tmp) + 1;
%     end
% end
% 
% %����������ͻ����Ľ������
% figure;
% bar(conflict_result_account./conflict_account);
% grid;
% xlabel('��ͻ�źŸ���');
% ylabel('������ͻ�źŵĽ�����ʣ�%��');
% title('��ͻ�źŽ������ͳ��(ʵ�ʷֲ�)');
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
% %ͳ�ƶ��س�ͻ��һ�س�ͻ��һ�����ֶ����Ҵ������źţ�
% oneTwoConflictVesName = [];
% for ii = 1 : 1 : length(conflict_aisData)
%    if conflict_aisData(ii) == 2 || conflict_aisData(ii) == 1
%        oneTwoConflictVesName = [oneTwoConflictVesName, vesName(ii)];
%    end
% end
% 
% detect_one_two_ves_result = unique(detect_one_two_ves);
% allOneTwoConflictVesName = unique(oneTwoConflictVesName);
% disp('һ�ض��س�ͻ�����Ľ�����ʣ�');
% disp(length(detect_one_two_ves_result)/length(allOneTwoConflictVesName));
% 
% %����������ͻ����Ľ������
% figure;
% bar(conflict_result_account./conflict_account);
% grid;
% xlabel('��ͻ�źŸ���');
% ylabel('������ͻ�źŵĽ�����ʣ�%��');
% title('��ͻ�źŽ������ͳ��(ʵ�ʷֲ�)');
% 
% % �������ʲƵƫ�ʱ�Ӳ��ͼ��
% subplot(3,1,1);
% plot(powerDiff);
% title('���ʲ�dB');
% xlabel('����ź�');
% ylabel('db');
% subplot(3,1,2);
% plot(freqOffset);
% title('Ƶƫ��');
% xlabel('����ź�');
% ylabel('HZ');
% subplot(3,1,3);
% plot(delayDiff);
% title('ʱ�Ӳ�');
% xlabel('����ź�');
% ylabel('bit');
% 
% % ���ֵ�ֱ��ͼ
% % F_histArray(powerDiff, freqOffset, delayDiff);
% 
% end
