function [conflict_aisData, conflict] = F_conflictStat(sendTimeBit)
    sigLen = 256;

    sigSum = size(sendTimeBit, 1);
    conflict = zeros(1, 35);
    count = 1;
    conflict_aisData = ones(sigSum, 1);

    for i = 1: 1: sigSum
        [row, col] = find(abs(sendTimeBit - sendTimeBit(i,1)) < sigLen);
        tempData = ones(1, sigLen);
         if size(row, 1) ~= 1
            for j = 1: 1: size(row, 1)
                if row(j) ~= i
                    if sendTimeBit(row(j), 1) - sendTimeBit(i,1) >= 0
                        tempData(sendTimeBit(row(j), 1) - sendTimeBit(i, 1) + 1 : sigLen) = tempData(sendTimeBit(row(j), 1) - sendTimeBit(i, 1) + 1 : sigLen) + 1;
                    else
                        tempData(1: sigLen - (sendTimeBit(i, 1) - sendTimeBit(row(j), 1))) = tempData(1: sigLen - (sendTimeBit(i, 1) - sendTimeBit(row(j), 1))) + 1;
                    end
                end
            end
            tempConflict = max(tempData);
%             if tempConflict > 10
%                 tempConflict = 10;
%             end
        %             if tempConflict == 2
        %                 powerDiffStat(1, count) = abs(parTable(timeTable(row(1), 4), 1) - parTable(timeTable(row(2), 4), 1));
        %                 count = count + 1;
        %             end
         else
            tempConflict = 1;
        end
        conflict_aisData(i, 1) = tempConflict;
        conflict(1, tempConflict) = conflict(1, tempConflict) + 1;
    end
    
    i = length(conflict);
    while(i>1 && conflict(i)==0)
        conflict(i) = [];
        i = i - 1;
    end
  
    con_sum = sum(conflict);
    conflict = conflict./con_sum;

    [x, y] = hist(conflict, length(conflict));
    figure(3)
    bar(conflict);
    grid;
    xlabel('��ͻ�������أ�');
    ylabel('ռ���ź����ٷֱȣ�%��');
    title('��ͻ�ź�ͳ��(ʵ�ʷֲ�)');
    % 
    % figure(4)
    % powerDiffStat = round(powerDiffStat);
    % [y, x] = hist(powerDiffStat, 20);
    % y = y/sum(y);
    % bar(x, y);
    % grid;
    % xlabel('���ʲdB��');
    % ylabel('ռ���س�ͻ�źŵİٷֱȣ�%��');
    % title('���س�ͻ�źŹ��ʲ�(ʵ�ʷֲ�)');
    % save conflictData conflict_aisData
end