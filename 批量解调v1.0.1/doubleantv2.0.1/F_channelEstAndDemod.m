function [delayEst, dopplerEst, hEst, flag, decisionSeq, match_len, startIndex] = ...
	F_channelEstAndDemod(sig)
% ----
% �˺������źŲ������Ʋ����, ���ŵ�����, Ȼ�����VA���, �粻�ɹ�����в�ֽ��
% ���ֽ��֮ǰ���ɼ������Ĵ���(Ϊ�˷����ٶȴ˴�δ��)
% ����:
%	sig:���յ���AIS�ź�
% ���:
%	delayEst:ʱ�ӹ���
%	dopplerEst:Ƶƫ����
%	hEst:�ŵ���Ӧ��ֵ����
%	flag:�ҵ�ͬ��λ�ı�־
%	decisionSeq:���������
%	match_len:ƥ��̶�
%	startIndex:ͬ�����еĿ�ʼλ��
% ----
	global Training StartFlag DecodLenth TrainingLength FlagLength locSig ...
		mode os
	if length(sig)<DecodLenth*os
		% ���źų���С�����볤������
		sig = [sig, zeros(1,DecodLenth*os-length(sig))];
	end
	% �ŵ���������
	[delayEst, dopplerEst, hEst] = F_channelEstimation(sig);
	% VA���������ͬ��λ
	VA_dec = F_viterbiDemod(sig, delayEst, dopplerEst);
	VA_dec = F_deNRZI(VA_dec, 1);
	
	% ����ͬ��λ
	startIndex = F_findDataLoc(VA_dec);
	Train_data = [Training, StartFlag];
	test_syn = VA_dec(max(1,startIndex-(TrainingLength+FlagLength)):(startIndex-1));
	len = length(test_syn);
	decisionSeq = VA_dec;
	match_len_VA = sum(test_syn==Train_data(end-len+1:end))/len;
	if strcmp(mode, 'diff')
		% ��Ϊ���+VAģʽ���ж�VA�������ȷ��, ����ȫ��ȷ��������, ������в�ֽ����
		% ����ȷ�ʽϸߵ�������Ϊ���
		if match_len_VA ~= 1
			% �ڴ˴��ɼӾ���ĳ���..mex_v2
			[diff_dec, match_len_diff, startIndex_diff] = diff_algo(sig, DecodLenth,...
				delayEst, dopplerEst);
			if match_len_diff > match_len_VA
				decisionSeq = diff_dec;
				match_len = match_len_diff;
			else
				decisionSeq = VA_dec;
				match_len = match_len_VA;
			end
		else
			decisionSeq = VA_dec;
			match_len = match_len_VA;
		end
	else
		match_len = match_len_VA;
	end
	flag = 1;
	if match_len < 0.5
		% ��ƥ���С��0.5����Ϊ������ȷ���
		delayEst = locSig.total_time_delay-33;
		flag = 0;
		hEst =  0;
		return;
	end
end