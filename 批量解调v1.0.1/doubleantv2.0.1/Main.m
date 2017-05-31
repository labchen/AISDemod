function result = Main(sigPath)
% clear all;
% close all;
% clc;
tic;

debug = 0;
if debug ~= 1
%     dirName = uigetdir('D:\AIS', '选择AIS信号文件夹...');
dirName = sigPath;
    resultPath = [dirName, '\demodResult_2ant\'];
    mkdir(resultPath);
    sigFile = dir(dirName);
    fileName = cell(1, length(sigFile));
    fileNum = 1;
    for ii = 1 : 1 : length(sigFile)
        if sigFile(ii).isdir == 0 && ~strcmp(sigFile(ii).name, '.') ...
                && ~strcmp(sigFile(ii).name, '..') ...
                && strcmp(sigFile(ii).name(1 : 1 : 6), 'AISsig')
            % 不记录文件夹
            fileName{fileNum} = sigFile(ii).name;
            fileNum = fileNum + 1;
        end
    end
    fileName(fileNum : end) = [];       % 删除剩余的cell
    fileNum = fileNum - 1;

    F_initPar;
    for fileIdx = 1 : 1 : fileNum
        load([dirName, '\', fileName{fileIdx}]);
% 		demodResult = F_aisDemod(sig_out_noise);
        demodResult = F_aisDemod(sig);
        resultFileName = ['AISResult', fileName{fileIdx}(7: end)];
        save([resultPath, resultFileName, '_result.mat'], 'demodResult');
    end
else
    [fileName, pathName] = uigetfile('*.mat', '选择信号mat文件', 'E:\AIS\20140508_仿真结果');
    resultPath = [pathName, 'demodResult\'];
    mkdir(resultPath);
    load([pathName '\' fileName]);
% 	startLoc = 1;
% 	sigIn = sig_out_noise(:, startLoc : startLoc+4095);
    sigIn = sig_out_noise;
% 		figure;
% 		for ii = 1 : 1 : size(sigIn, 1)
% 			subplot(size(sigIn,1),1,ii);plot(abs(sigIn(ii, :)));
% 		end
% 		figure;
% 		plot(abs(sigIn));
% 		drawnow;
    F_initPar;
    demodResult = F_aisDemod(sigIn);
    save([resultPath fileName '_debugresult_ant1_new.mat'], 'demodResult');
end
result = 0;
toc;
end 