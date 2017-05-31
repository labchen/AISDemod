function [JMLSE_result_dec] = F_jmlseDemod(sig, Delay_est, Doppler_est, H_est, num_est)

% 输入：
%   sig：输入的AIS信号
%   Delay_est：时延估计
%   Doppler_est：多普勒频移估计
%   num_est：估计出的信号个数
% 输出：
%   JMLSE_result_dec：JMLSE解调结果
%   

global os DataLength h0 truncate RisingLength FrameLength L symbols DecodLenth Rb

SigLength = length(sig);
DelayInt_est = round(Delay_est/os)*os;
DelayDec_est = Delay_est - DelayInt_est;
K = num_est;
% JMLSE解调
h0_delay = zeros(K,length(h0));
h0_eff_delay = zeros(K,length(h0));
for kk = 1 : 1 : K
    if DelayDec_est(kk)>=0
        h0_delay(kk,:) = [zeros(1,DelayDec_est(kk)), h0(1:end-DelayDec_est(kk))];
    else
        h0_delay(kk,:) = [h0(1-DelayDec_est(kk):end), zeros(1,-DelayDec_est(kk))];
    end
    tmp = repmat(circshift([1 -1j -1 1j],[0,-mod(DelayInt_est(kk)/os,4)]), 1, ceil(length(h0)/os/4));
    derotation_h = kron(tmp(1:length(h0)/os),ones(1,os));
    h0_eff_delay(kk,:) = h0_delay(kk,:).*derotation_h;
end
sig_ch_ext = [sig, zeros(1,max(DelayInt_est)+DecodLenth*os-SigLength)];
% 解旋
if truncate==1
    tmp = repmat([1j 1 -1j -1], 1, ceil(length(sig_ch_ext)/os/4));
elseif truncate==0
    tmp = repmat([-1 1j 1 -1j], 1, ceil(length(sig_ch_ext)/os/4));
end

derotation = kron(tmp(1:floor(length(sig_ch_ext)/os)), ones(1,os));
sig_derotate = sig_ch_ext(1:floor(length(sig_ch_ext)/os)*os) .* derotation;


t = (repmat(DelayInt_est.',1,FrameLength*os) + ...
    +repmat(RisingLength*os+(0:FrameLength*os-1),K,1)) / os / Rb;
CarrierOffset_est = exp(1j*2*pi*diag(Doppler_est)*t);
CarrierOffset_Mat_est = zeros(os*(L+1)*K,FrameLength);
for kk = 1 : 1 : K
    CarrierOffset_Mat_est((kk-1)*os*(L+1)+1:kk*os*(L+1),:) = ...
        repmat(reshape(CarrierOffset_est(kk,:),os,FrameLength), L+1, 1);
end

coeff = zeros(K*length(h0), ceil(length(sig_derotate)/os));
for kk = 1 : 1 : K
    tmp = H_est(kk) * h0_eff_delay(kk, :).';
    coeff((kk-1)*os*(L+1)+1:kk*os*(L+1),DelayInt_est(kk)/os+RisingLength+(1:FrameLength))...
        = repmat(tmp(:),1,FrameLength) .* CarrierOffset_Mat_est((kk-1)*os*(L+1)+1:kk*os*(L+1),:);
end

% detect using JMLSE
[dem, cumulated_metric] = ...
    VA_det_normal_mex(sig_derotate, coeff, K, os, L+1, symbols);
dem = reshape(dem, K, []);

det = zeros(K, DecodLenth);
for kk = 1 : 1 : K
    % correspond to truncation in gmsk_mod
    if truncate == 1
        det(kk,RisingLength+1:end) = dem(kk, DelayInt_est(kk)/os+...
            (RisingLength+2:DecodLenth+1));
    elseif truncate==0
        det(kk,RisingLength+1:end) = dem(kk, DelayInt_est(kk)/os+...
            (RisingLength+3:DecodLenth+2));
    end
end
JMLSE_result_dec = F_deNRZI(det, 2, 0);