function [Delay, Freq, Syn_Mat] = Update_Delay_Freq_4os(sig, Delay_Id, Freq_Id, Standard_sig)
% ----
% �˺������ݸ�����ʱ��Ƶƫ��Χ�����źŵ�ʱ�Ӻ�Ƶƫֵ
% ����:
%	sig:�����Ƶ��ź�
%	Delay_Id:ʱ�ӹ��Ƶķ�Χ
%	Freq_Id:Ƶƫ���Ƶķ�Χ
%	Standard_sig:��׼�ź�
% ���:
%	Delay:ʱ�ӹ���
%	Freq:Ƶƫ����
%	Syn_Mat:���ֵ����
% ----
	global Rb os TrainingLength FlagLength
	% ����ʱ��Ƶƫ����ؾ���Ĺ���
	Syn_length = (TrainingLength+FlagLength)*os;      % ͬ�����кͿ�ʼ��־��32bit
	Num_Zero = length(Standard_sig) - Syn_length;       % �������(ͬ���ӱ�־)�Ĳ�������
	Freq_Precision = Rb / ((Num_Zero + Syn_length)/os);    % Ƶ�ʾ���, ������з���ʱ��ĵ���

	% ���㱾��ͬ�������ڲ�ͬƵƫ�µ�fftֵ
	Standard_fft = zeros(length(Freq_Id), length(Standard_sig));
	for ii = 1 : 1 : length(Freq_Id)
		% ��fft��ѭ����λ, �ƶ�һλ�����ƶ�һ��Ƶ�ʾ��ȵ�fftֵ
		Standard_fft(ii, :) = circshift(fft(Standard_sig.'), Freq_Id(ii));
	end

	Syn_Mat = zeros(length(Delay_Id), length(Freq_Id));
	for ii = 1 : 1 :length(Delay_Id)
		Sig_Window = [sig(Delay_Id(ii):(Syn_length+Delay_Id(ii)-1)), zeros(1,Num_Zero)];    % ����������źŵ�ǰ32bit(�������)�ڲ�ͬʱ���µ�fftֵ
		Sig_Window_fft = fft(Sig_Window);
		Syn_Mat(ii, :) = Sig_Window_fft*Standard_fft';           % �൱��ʱ�������ֵ
	end

	[m, p] = max(abs(Syn_Mat(:)));       % �ҵ�������ֵ
	% ȷ�����ֵλ�ö�Ӧ��ʱ�Ӻ�Ƶƫ
	Freq = Freq_Precision * Freq_Id(ceil(p ./ length(Delay_Id)));
	Delay_Pos = mod(p, length(Delay_Id));
	if Delay_Pos == 0
		Delay = Delay_Id(length(Delay_Id));
	else
		Delay = Delay_Id(Delay_Pos);
	end
end