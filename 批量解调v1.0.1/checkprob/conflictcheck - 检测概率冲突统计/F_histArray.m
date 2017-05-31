function  F_histArray(arrayPower, arrayFreq, arrayDelay)
    maxPowerNum = max(arrayPower);
    disp(['最大功率差：', num2str(maxPowerNum)]);
    minPowerNum = min(arrayPower);
    disp(['最小功率差：', num2str(minPowerNum)]);
    stepPowerNum = (maxPowerNum - minPowerNum) / 10;
    
    maxFreqNum = max(arrayFreq);
    disp(['最大频偏差：', num2str(maxFreqNum)]);
    minFreqNum = min(arrayFreq);
    disp(['最小频偏差：', num2str(minFreqNum)]);
    stepFreqNum = (maxFreqNum - minFreqNum) / 10;
    
    maxDelayNum = max(arrayDelay);
    disp(['最大时延差：', num2str(maxDelayNum)]);
    minDelayNum = min(arrayDelay);
    disp(['最小时延差：', num2str(minDelayNum)]);
    stepDelayNum = (maxDelayNum - minDelayNum) / 10;
    
    
    xPower = minPowerNum: stepPowerNum : maxPowerNum;
    xFreq = minFreqNum: stepFreqNum : maxFreqNum;
    xDelay = minDelayNum : stepDelayNum : maxDelayNum;
    
    figure;
    subplot(3,1,1);
    hist(arrayPower, xPower);
    title('功率差分布');
    xlabel('db');
    ylabel('信号个数');
    subplot(3,1,2);
    hist(arrayFreq, xFreq);
    title('频偏差分布');
    xlabel('hz');
    ylabel('信号个数');
    subplot(3,1,3);
    hist(arrayDelay, xDelay);
    title('时延差分布');
    xlabel('bit');
    ylabel('信号个数');   
end