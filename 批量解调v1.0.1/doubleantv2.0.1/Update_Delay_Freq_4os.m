function [Delay, Freq, Syn_Mat] = Update_Delay_Freq_4os(sig, Delay_Id, Freq_Id, Standard_sig)
% ----
% 此函数根据给定的时延频偏范围估计信号的时延和频偏值
% 输入:
%	sig:待估计的信号
%	Delay_Id:时延估计的范围
%	Freq_Id:频偏估计的范围
%	Standard_sig:标准信号
% 输出:
%	Delay:时延估计
%	Freq:频偏估计
%	Syn_Mat:相关值矩阵
% ----
	global Rb os TrainingLength FlagLength
	% 更新时延频偏和相关矩阵的估计
	Syn_length = (TrainingLength+FlagLength)*os;      % 同步序列和开始标志的32bit
	Num_Zero = length(Standard_sig) - Syn_length;       % 相关序列(同步加标志)的补零数量
	Freq_Precision = Rb / ((Num_Zero + Syn_length)/os);    % 频率精度, 相关序列发送时间的倒数

	% 计算本地同步序列在不同频偏下的fft值
	Standard_fft = zeros(length(Freq_Id), length(Standard_sig));
	for ii = 1 : 1 : length(Freq_Id)
		% 先fft再循环移位, 移动一位就是移动一个频率精度的fft值
		Standard_fft(ii, :) = circshift(fft(Standard_sig.'), Freq_Id(ii));
	end

	Syn_Mat = zeros(length(Delay_Id), length(Freq_Id));
	for ii = 1 : 1 :length(Delay_Id)
		Sig_Window = [sig(Delay_Id(ii):(Syn_length+Delay_Id(ii)-1)), zeros(1,Num_Zero)];    % 计算待估计信号的前32bit(相关序列)在不同时延下的fft值
		Sig_Window_fft = fft(Sig_Window);
		Syn_Mat(ii, :) = Sig_Window_fft*Standard_fft';           % 相当于时域求相关值
	end

	[m, p] = max(abs(Syn_Mat(:)));       % 找到最大相关值
	% 确定最大值位置对应的时延和频偏
	Freq = Freq_Precision * Freq_Id(ceil(p ./ length(Delay_Id)));
	Delay_Pos = mod(p, length(Delay_Id));
	if Delay_Pos == 0
		Delay = Delay_Id(length(Delay_Id));
	else
		Delay = Delay_Id(Delay_Pos);
	end
end