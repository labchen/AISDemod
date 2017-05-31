function [diff_dec,match_len,start_pos] = diff_algo(sigDemod,DecodLenth,Delay_est,Doppler_est)
% ��λ����㷨
% diff_dec ����㷨������
% diff_demodSig ��ȷ��Ϣ��
% diff_CRC ���������CRCУ��ֵ
% sigDemod �����ź�
% Delay_est ʱ�ӹ���
% Doppler_est Ƶƫ����

% DecodLenth = 256;
os = 4;
Rb = 9600;
fc = 10000;
Fs = Rb*os;
t = (0:DecodLenth*os-1)/Fs;
CarrierOffset_est = exp(-1j*2*pi*Doppler_est.'*t);
tmp_idx = Delay_est+(1:DecodLenth*os);
if tmp_idx(1)<1
    sigJudge = find(tmp_idx<1);
    sigDemod_est = [zeros(1,length(sigJudge)), sigDemod(1:tmp_idx(end))];
elseif tmp_idx(end)>length(sigDemod)
    sigJudge = find(tmp_idx>length(sigDemod));
    sigDemod_est = [sigDemod(tmp_idx(1):end), zeros(1,length(sigJudge))];
else
    sigDemod_est = sigDemod(tmp_idx);
end
Sig_Shift = sigDemod_est.*CarrierOffset_est;        % �ŵ����ƺ�����ź�

% ��ֽ��
sigI = real(Sig_Shift);
sigQ = imag(Sig_Shift);
sigI_delay1Bit = [zeros(1, 1*os) sigI(1 : end - 1*os)];
sigQ_delay1Bit = [zeros(1, 1*os) sigQ(1 : end - 1*os)];
sigJudge = sigI_delay1Bit.*sigQ - sigI.*sigQ_delay1Bit;
% 7.14���
% sigJudge = [sigJudge(os+1 : end) zeros(1, os)];

% ���ȹ�һ��
sigJudge = sigJudge / max(abs(sigJudge));

% ��ͨ�˲���
N = 300;
%         bandWidth = 25000;
freq = [0 fc fc Fs/2]*2/Fs;
amp = [1 1 0 0];
lpf = firls(N, freq, amp);

dem_high = conv(sigJudge, lpf);
dem_high = dem_high(N/2 + 1 : N/2 + length(sigJudge));

% % �۲��ͨ�˲���Ƶ��
% if debug == 1
%     f_tmp = -Fs/2 : 1/(length(sigJudge)/Fs) : Fs/2- 1/length(sigJudge)/Fs;
%     f_lpf = -Fs/2 : 1/(length(lpf)/Fs) : Fs/2- 1/(length(lpf)/Fs);
%     figure; semilogy(f_tmp, fftshift(abs(fft(sigJudge))));
%     hold on;
%     semilogy(f_lpf, fftshift(abs(fft(lpf))), 'r-');title('��ͨ�˲�ǰ�ź����ͨ�˲���������');
% end
%
% % �۲��˲�ǰ���ź�
% if debug == 1
%     figure;
%     subplot(211);plot(sigJudge);title('��λ��ּ��㷨');grid on;
%     subplot(212);plot(dem_high);title('�����˲���');grid on;
% end

% os��������ÿ�������㶼CRC����, ����һ����ȷ�Ϳ������(��Ѳ�����Ϊ3)
Training = ones(1,24);
Training(1:2:end) = 0;
StartFlag = [0 1 1 1 1 1 1 0];
Train_data = [Training,StartFlag];
match_len = 0;
start_pos = 41;
for os_loc = 1 : os
    % �����о�
    det = abs(dem_high((0:DecodLenth-1)*os+os_loc)<0); % not '>' since mapping
    % ��NRZI����
    dec = mod(det+[0 det(1, 1:DecodLenth-1)], 2);
    dec = 1 - dec;

    % ͬ�����м��
    idx = 1;
    while idx+7<=length(dec)
        if sum(dec(idx:idx+7)==[0 1 1 1 1 1 1 0])>=7
            startIndex = idx+8;
            if startIndex>32
                break;
            else
                idx = idx+1;
            end
        else
            if idx>50
                startIndex = 41;
                break;
            else
                idx = idx+1;
            end
        end
    end
    test_syn = dec(max(1,startIndex-32):(startIndex-1));
    len = length(test_syn);
    match_len_tmp = sum(test_syn==Train_data(end-len+1:end))/len;
    % ��¼��Ե�֡
	if match_len_tmp > match_len
		diff_dec = dec;
		match_len = match_len_tmp;
		start_pos = startIndex;
	end
end

