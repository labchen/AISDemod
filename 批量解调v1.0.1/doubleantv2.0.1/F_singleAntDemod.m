function [sig, aisData, sigPos, parsEst] = F_singleAntDemod(sig)
% ----
% �˺���Ϊ����AIS�ź�(����ͻ�ź�)�ĵ����߽������
% ����:
%	sigIn:����Ľ���AIS�ź�
% ���:
%	sigOut:����ǿ�źź���ź�, ���ٴε��øú�������س�ͻ
%	aisData:������������Ϣ
%	sigPos:�����ȷ�ź�λ��
%	parsEst:���Ƴ����ź�ʱ��Ƶƫ
% ----
	global BlockLength os DataLength Training StartFlag EndFlag DecodLenth ...
		L RisingLength FrameLength truncate symbols h0 Start_pos ant_num Rb ...
		TrainingLength FlagLength
	sig_ch_sic = sig;
	SigLength = length(sig);     % �źų���
	if SigLength> 3*BlockLength*os
		% �����ʼλ��, ��Գ�ͻ�źŵĽ��, ���
		% AIS��Ŀ��ͨ�����û���������������_v2.0
		sicStartLoc = [1,(BlockLength-TrainingLength-FlagLength)*os+1, 1];	
% 		sicStartLoc = [1,1];		% �޳�ͻ�ź�ʱ��������ʱ��
	else
		sicStartLoc = [1,1];
	end
	
	K = length(sicStartLoc);			% �����ʼλ������
	num_est = 0;					% �����ź���
	BufferLength = 24*ones(1, K);	% ���źŵĻ���������
	
	VA_result_dec = zeros(K, DecodLenth);
	Delay_est = zeros(1, K);
	Doppler_est = zeros(1, K);
	H_est = zeros(1, K);
	VA_dec_start = zeros(1, K);
	VA_dec_end = zeros(1, K);
	DataIdx = cell(1, K);
	for kk = 1 : 1 : K
		[delayEst, dopplerEst, hEst, flag, decisionSeq, match_len, dataLoc] = ...
			F_channelEstAndDemod(sig_ch_sic(sicStartLoc(kk):end));
		if flag == 0
			% δ�ҵ�ͬ��, �����һ����ʼλ�ý�
			continue;
		end
		num_est = num_est+1;        % �ҵ�ͬ��, �����źŸ�����1
		VA_result_dec(num_est, :) = decisionSeq;		% ��¼�ŵ�������VA����Ľ��
		Delay_est(num_est) = delayEst+sicStartLoc(kk)-1;	% ����sicStartLoc����Delay_est
		Doppler_est(num_est) = dopplerEst;				% ��¼���Ƴ����ź�Ƶƫ
		H_est(num_est) = hEst;
		VA_dec_start(num_est) = dataLoc;				% ��¼���Ƴ�����Ϣλ��
		[VA_dec_end(num_est), sic_flag] = F_findEndFlag(decisionSeq, VA_dec_start(num_est));	% ���ҽ�����־
		DataIdx{num_est} = VA_dec_start(num_est):VA_dec_end(num_est);       % ���ݱ��
		
		% �ؽ���ǿ�źŲ���ȥ
		if sic_flag == 1
			% �ҵ�������־, �ؽ�ѵ�����кͽ�����־
			DataFrame_r = [Training StartFlag decisionSeq(DataIdx{num_est}) EndFlag];
		else
			% δ�ҵ�������־, �ӿ�ʼ��־���Ƶĺ�184λ, �ؽ�ѵ������
			DataFrame_r = [Training StartFlag decisionSeq(DataIdx{num_est})];
		end
		sig_gmsk_ext_r = F_aisModul(DataFrame_r, 0);
		
		% ʹ���ع��ź��ٹ���Ƶƫλ��
		sig_ch_est = F_cutSig(sig_ch_sic, Delay_est(num_est), length(sig_gmsk_ext_r));
		% �����������ؽ��ź����¹���Ƶƫ
		TuneRange = dopplerEst+(-25:0.5:25);   % ����Ƶƫ������ǰ��25Hz��Χ���������
		TuneCorr = zeros(1,length(TuneRange));
		t = (Delay_est(num_est)+(0:length(sig_gmsk_ext_r)-1))/os/Rb;
		for freqIdx = 1:length(TuneRange)
			CarrierOffset_tmp = exp(1j*2*pi*TuneRange(freqIdx)*t);
			sig_tmp = CarrierOffset_tmp.*sig_gmsk_ext_r;
			TuneCorr(freqIdx) = sig_ch_est*sig_tmp'/(sig_tmp*sig_tmp');
		end
		[maxCorr, maxPos] = max(TuneCorr);   % �ҵ����������Ƶƫλ��
		Doppler_est(num_est) = TuneRange(maxPos);
		H_est(num_est) = TuneCorr(maxPos);
		CarrierOffset_est_VA = exp(1j*2*pi*Doppler_est(num_est)*t);     % ��λ����
		
		% ��kk<Kʱ���и�������
		if kk < K
			PhaseShift_est = 1;
			sig_ch_i = PhaseShift_est*H_est(num_est).*CarrierOffset_est_VA.*sig_gmsk_ext_r;     % ���ݹ�����λ�ͷ��Ȼָ�һ���û��ź�
			% ��������
			sig_ch_sic = F_sigSIC(sig_ch_sic, sig_ch_i, Delay_est(num_est), length(sig_gmsk_ext_r));
		end
	end
	if num_est < K
		% ɾ�������Ŀռ�
		VA_result_dec(num_est+1:end, :) = [];
		Delay_est(num_est+1:end) = [];
		Doppler_est(num_est+1:end) = [];
		VA_dec_start(num_est+1:end) = [];
		VA_dec_end(num_est+1:end) = [];
		DataIdx(num_est+1:end) = [];
	end
	
	K = num_est;        % ��¼���Ƴ����źŸ���
	aisData = [];
	sigPos = [];
	parsEst = [];
	if K ~= 0
		data_rec_VA = cell(1, K);
		VA_crc_check = zeros(1, K);
        for kk = 1 : 1 : K
			% �Է�����ĸ��źŽ���CRCУ��
			[data_rec_VA{kk}, VA_crc_check(kk)] = F_CRCcheck(VA_result_dec(kk, :));
        end
		
        if ~(all(VA_crc_check == 0))
            [JMLSE_result_dec] = F_jmlseDemod(sig, Delay_est, Doppler_est, H_est, num_est);
            JMLSE_dec_start = zeros(1, K);
            data_rec_JMLSE = cell(1, K);
            JMLSE_crc_check = zeros(1, K);
            for kk = 1 : 1 : K
                JMLSE_dec_start(kk) = F_findDataLoc(JMLSE_result_dec(kk, :));
                [data_rec_JMLSE{kk}, JMLSE_crc_check(kk)] = F_CRCcheck(JMLSE_result_dec(kk, :));
            end
            JMLSE_dec_end = DataLength + JMLSE_dec_start - 1;
        else
            JMLSE_crc_check = -ones(1,K);
        end
		
		% ��¼���У��ͨ�����ź�, ��������������ǿ�źŵ��ź������ٴε����߽��
		corrNum = K - sum(VA_crc_check & JMLSE_crc_check);
		corrLoc = 1;
		for SIC_idx = 1 : 1 : K
            if VA_crc_check(SIC_idx) == 0
				aisData{corrLoc} = num2str(data_rec_VA{SIC_idx});
				sigPos(corrLoc, :) = [Start_pos, cell2mat(ant_num)];
				parsEst(corrLoc, :) = [Delay_est(SIC_idx) Doppler_est(SIC_idx)];
				corrLoc = corrLoc + 1;
				DataIdx{SIC_idx} = VA_dec_start(SIC_idx):VA_dec_end(SIC_idx);
				BufferLength(SIC_idx) = 24-(VA_dec_end(SIC_idx)-VA_dec_start(SIC_idx)+1-DataLength);
				DataFrame_r = [Training StartFlag VA_result_dec(SIC_idx,DataIdx{SIC_idx}) EndFlag];
				sig_ch_i = F_aisModul(DataFrame_r, BufferLength(SIC_idx), Delay_est(SIC_idx), Doppler_est(SIC_idx), H_est(SIC_idx));
				sig = F_sigSIC(sig, sig_ch_i, Delay_est(SIC_idx), BlockLength*os);
				continue;
			elseif JMLSE_crc_check(SIC_idx)==0
				aisData{corrLoc} = num2str(data_rec_JMLSE{SIC_idx});
				sigPos(corrLoc, :) = [Start_pos, cell2mat(ant_num)];
				parsEst(corrLoc, :) = [Delay_est(SIC_idx) Doppler_est(SIC_idx)];
				corrLoc = corrLoc + 1;
				DataIdx{SIC_idx} = JMLSE_dec_start(SIC_idx):JMLSE_dec_end(SIC_idx);
				BufferLength(SIC_idx) = 24-(JMLSE_dec_end(SIC_idx)-JMLSE_dec_start(SIC_idx)+1-DataLength);
				DataFrame_r = [Training StartFlag VA_result_dec(SIC_idx,DataIdx{SIC_idx}) EndFlag];
				sig_ch_i = F_aisModul(DataFrame_r, BufferLength(SIC_idx), Delay_est(SIC_idx), Doppler_est(SIC_idx), H_est(SIC_idx));
				sig = F_sigSIC(sig, sig_ch_i, Delay_est(SIC_idx), BlockLength*os);
            end
		end
	end
end