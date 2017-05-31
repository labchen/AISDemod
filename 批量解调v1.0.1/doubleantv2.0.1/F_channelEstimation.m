function [delayEst, dopplerEst, hEst] = F_channelEstimation(sig)
% ----
% 此函数通过信号进行信道估计
% 输入:
%	sig:接收到的AIS信号
% 输出:
%	delayEst:时延估计
%	dopplerEst:频偏估计
%	hEst:信道响应幅值估计
% ----
	global BlockLength os Rb DecodLenth locSig
	if length(sig) < DecodLenth*os
		% 若信号长度小于译码长度则补零
		sig = [sig, zeros(1, DecodLenth*os-length(sig))];
	end
	% 粗同步
	First_Freq_Id = -27:27;
	max_delay = locSig.total_time_delay;
	First_Delay_Id = 1:max_delay;
	First_Standard_Signal = locSig.time_delay(1).synchronization_signal(1 : 256);
	[First_Delay, First_Freq, First_Mat] = Update_Delay_Freq_4os(sig, First_Delay_Id, First_Freq_Id, First_Standard_Signal);
	
	% 细同步
	Second_Delay_Id = max(1, First_Delay-6) : min(max_delay,First_Delay+6);
	Second_Freq_Id = max(-107,floor(First_Freq/37.5)-10) : min(107,ceil(First_Freq/37.5)+10);
	DelayIdx = Second_Delay_Id;
	FreqShiftRange = Second_Freq_Id;
	TotalNumDelay = length(Second_Delay_Id);
	FreqShiftRangeIdx = 1:length(Second_Freq_Id);

	synchronization_results_matrix = zeros(TotalNumDelay, length(FreqShiftRangeIdx));
% 	tic;
	for ii = 1 : 1 : TotalNumDelay
		n_time_delay = DelayIdx(ii);
% 		this_synchronization_signal_fft_all = zeros(length(FreqShiftRangeIdx), BlockLength*os);
		this_synchronization_signal_fft_all = zeros(BlockLength*os, length(FreqShiftRangeIdx));
		locSyncSigFFT = locSig.time_delay(n_time_delay).synchronization_signal_fft;
		for jj = 1 : 1 : length(FreqShiftRangeIdx)
			n_frequency_shift = FreqShiftRange(FreqShiftRangeIdx(jj));
			this_synchronization_signal_fft_all(:, jj) = circshift(locSyncSigFFT, n_frequency_shift);
		end
% 		this_synchronization_signal_fft_all = this_synchronization_signal_fft_all';
		sign_window = sig(1:BlockLength*os) .* locSig.time_delay(n_time_delay).synchronization_windows;
		sign_window_fft = fft(sign_window);
		synchronization_results_matrix(ii, :) = sign_window_fft*this_synchronization_signal_fft_all;
	end
% 	toc;
	[num, pos] = max(abs(synchronization_results_matrix(:)));
	time_synchronization = mod(pos, TotalNumDelay);
	if time_synchronization == 0
		time_synchronization = TotalNumDelay;
	end
	Second_Delay = Second_Delay_Id(time_synchronization);
	Second_Freq = 37.5*Second_Freq_Id(ceil(pos/TotalNumDelay));
% 		figure;surf(Second_Freq_Id,Second_Delay_Id,abs(synchronization_results_matrix))
% 		xlabel('频域','fontsize',30,'horizontalalignment','center')
% 		ylabel('时域','fontsize',30,'horizontalalignment','center')
% 		title('时频联合相关峰值图','fontsize',30,'horizontalalignment','center')
	
	% 精细同步
	t = (1:BlockLength*os).' / os / Rb;
	Third_Freq_Step = 2*37.5/50;
	Third_Delay_Id = max(1,Second_Delay-12*os) : min(max_delay,Second_Delay+12*os);
	% Third_Delay_Id = 1:min(max_delay,Second_Delay+100*os);
	TotalNumDelay = length(Third_Delay_Id);
	Third_Freq_Id = Second_Freq + (-37.5:Third_Freq_Step:37.5);
	Third_Mat = zeros(TotalNumDelay, length(Third_Freq_Id));
% 	tic;
	for ii = 1 : 1 : TotalNumDelay
		n_time_delay = Third_Delay_Id(ii);
% 		Third_Standard_fft = zeros(length(Third_Freq_Id), BlockLength*os);
		mulTmp = zeros(BlockLength*os, length(Third_Freq_Id));
		locSyncSignal = (locSig.time_delay(n_time_delay).synchronization_signal).';
		for jj = 1 : 1 : length(Third_Freq_Id)
			Third_Freq_Id_tmp = Third_Freq_Id(jj);
			mulTmp(:, jj) = locSyncSignal .* exp(1j*2*pi*Third_Freq_Id_tmp*t);
% 			Third_Standard_fft(jj, :) = fft(mulTmp);
% 			Third_Standard_fft(jj, :) = Third_Standard_fft(jj, :) ./ sum(abs(Third_Standard_fft(jj, :)).^2);
		end
		Third_Standard_fft = fft(mulTmp);
		Third_Standard_fft = (Third_Standard_fft ./ repmat(sum(abs(Third_Standard_fft).^2), size(Third_Standard_fft, 1), 1)).';
		Third_sig = sig(1:BlockLength*os) .* locSig.time_delay(n_time_delay).synchronization_windows;
		Third_sig_fft = fft(Third_sig);
		Third_Mat(ii, :) = ...
			Third_sig_fft*Third_Standard_fft';
	end
% 	toc;
	[num, pos] = max(abs(Third_Mat(:)));
	time_synchronization=mod(pos,TotalNumDelay);
	if time_synchronization==0
		time_synchronization = TotalNumDelay;
	end
	delayEst = Third_Delay_Id(time_synchronization)-33;
	dopplerEst = Third_Freq_Id(ceil(pos/TotalNumDelay));
	hEst = Third_Mat(pos);
end