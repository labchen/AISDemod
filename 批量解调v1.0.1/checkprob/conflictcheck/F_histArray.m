function  F_histArray(arrayPower, arrayFreq, arrayDelay)
    maxPowerNum = max(arrayPower);
    disp(['����ʲ', num2str(maxPowerNum)]);
    minPowerNum = min(arrayPower);
    disp(['��С���ʲ', num2str(minPowerNum)]);
    stepPowerNum = (maxPowerNum - minPowerNum) / 10;
    
    maxFreqNum = max(arrayFreq);
    disp(['���Ƶƫ�', num2str(maxFreqNum)]);
    minFreqNum = min(arrayFreq);
    disp(['��СƵƫ�', num2str(minFreqNum)]);
    stepFreqNum = (maxFreqNum - minFreqNum) / 10;
    
    maxDelayNum = max(arrayDelay);
    disp(['���ʱ�Ӳ', num2str(maxDelayNum)]);
    minDelayNum = min(arrayDelay);
    disp(['��Сʱ�Ӳ', num2str(minDelayNum)]);
    stepDelayNum = (maxDelayNum - minDelayNum) / 10;
    
    
    xPower = minPowerNum: stepPowerNum : maxPowerNum;
    xFreq = minFreqNum: stepFreqNum : maxFreqNum;
    xDelay = minDelayNum : stepDelayNum : maxDelayNum;
    
    figure;
    subplot(3,1,1);
    hist(arrayPower, xPower);
    title('���ʲ�ֲ�');
    xlabel('db');
    ylabel('�źŸ���');
    subplot(3,1,2);
    hist(arrayFreq, xFreq);
    title('Ƶƫ��ֲ�');
    xlabel('hz');
    ylabel('�źŸ���');
    subplot(3,1,3);
    hist(arrayDelay, xDelay);
    title('ʱ�Ӳ�ֲ�');
    xlabel('bit');
    ylabel('�źŸ���');   
end