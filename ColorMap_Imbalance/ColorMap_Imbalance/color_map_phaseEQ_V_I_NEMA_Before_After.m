close all;
clc;

DSSObj = actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0)
disp('Unable to start the OpenDSS Engine');
return
end

DSSText = DSSObj.Text; % Used for all text interfacing from matlab to opendss
DSSCircuit = DSSObj.ActiveCircuit; % active circuit
DSSBus = DSSCircuit.ActiveBus;

alpha = exp(1j*2*pi/3);
ABC_to_SEQ = 1/3*[1 1 1;1 alpha alpha^2;1 alpha^2 alpha];
SEQ_to_ABC = [1 1 1;1 alpha^2 alpha;1 alpha alpha^2];

path='F:\swith source\ColorMap_Imbalance\ColorMap_Imbalance\MasterSherburne_SingleShapes_duty.DSS';
%*************************************************************************%
%*************************************************************************%
%*************************************************************************%

step=2754;
%DSS compile and solve
DSSText.Command=['Compile (',path,')'];
DSSText.Command='batchedit load..* Vmin=0.80'; % Set Vmin lower so that load model property will remain same
DSSText.Command='set mode=duty';

DSSText.Command='set number=1 stepsize=15m hour=0 sec=0';
DSSText.Command=['set hour=',num2str(0/4),' h=',num2str(900*step),' sec=',num2str(0)];


DSSText.Command='solve';

% DSSCircuit.Solution.hour
% DSSCircuit.Solution.second

PBA_Node='n100'
LineName='L5000_100'
FeederNode='N1';

Vbaseold = 8.32e3/sqrt(3)

DSSLines=DSSCircuit.Lines.AllNames;

M={};
for i=1:length(DSSLines)
DSSCircuit.Lines.name=char(DSSLines(i));

bus=DSSCircuit.ActiveCktElement.BusNames;
DSSCircuit.SetActiveBus(char(bus(2)));

if length(DSSCircuit.ActiveCktElement.Currents)==12 & length(DSSCircuit.ActiveBus.Voltages)==6
M{i,1}=DSSCircuit.ActiveCktElement.SeqCurrents(4); %I0, second terminal of the line (first terminal is index 1)
I_neutral(i,1)=DSSCircuit.ActiveCktElement.SeqCurrents(4)*3;


M{i,2}=DSSCircuit.ActiveBus.x; % To bus x coordinate
M{i,3}=DSSCircuit.ActiveBus.y; % To bus y coordinate

Vbus=DSSCircuit.ActiveBus.Voltages;
V_ABC_before(:,i)=[Vbus(1)+j*Vbus(2); Vbus(3)+j*Vbus(4); Vbus(5)+j*Vbus(6)];
I_line_before=DSSCircuit.ActiveCktElement.Currents;
I_ABC_before(:,i)=[I_line_before(7)+j*I_line_before(8); I_line_before(9)+j*I_line_before(10); I_line_before(11)+j*I_line_before(12)];

DSSCircuit.SetActiveBus(char(bus(1)));
M{i,4}=DSSCircuit.ActiveBus.x; % From bus x coordinate
M{i,5}=DSSCircuit.ActiveBus.y; % From bus y coordinate
M{i,6}=3; % # of phases
M{i,7}=bus(2); %To bus name
M{i,8}=bus(1); %From bus name
M{i,9}=DSSCircuit.ActiveCktElement.name; %element




else
    M{i,1}=NaN;
    I_neutral(i,1)=NaN;
    I_ABC_before(:,i)=[NaN+j*NaN; NaN+j*NaN; NaN+j*NaN];
    V_ABC_before(:,i)=[NaN+j*NaN; NaN+j*NaN; NaN+j*NaN];

    M{i,2}=DSSCircuit.ActiveBus.x; % To bus x coordinate
    M{i,3}=DSSCircuit.ActiveBus.y; % To bys y coordinate
    M{i,4}=DSSCircuit.ActiveBus.x; % From bus x coordinate
    M{i,5}=DSSCircuit.ActiveBus.y; % From bus y coordinate
    %****
    M{i,6}=1; % # of phases if 1 it means it could be 1 or 2
    %****
    M{i,7}=bus(2); %To bus name
    M{i,8}=bus(1); %From bus name
    M{i,9}=DSSCircuit.ActiveCktElement.name; %element
   
end
end

I_neutral_percentage=I_neutral/max(I_neutral);


%*******NEMA Voltage before******
[max_before_V, idx_max_before_V]=max(abs(transpose(V_ABC_before)),[],2);
[min_before_V, idx_min_before_V]=min(abs(transpose(V_ABC_before)),[],2);
mean_before_V=transpose(mean(abs(V_ABC_before)));

[max_deviation_from_mean_before_V, idx_mx_dv_mean_before_V]=max([abs(max_before_V-mean_before_V) abs(min_before_V-mean_before_V)],[],2);

NEMA_Before_V=max_deviation_from_mean_before_V./mean_before_V;

%*******NEMA Current before******

[max_before_I, idx_max_before_I]=max(abs(transpose(I_ABC_before)),[],2);
[min_before_I, idx_min_before_I]=min(abs(transpose(I_ABC_before)),[],2);
mean_before_I=transpose(mean(abs(I_ABC_before)));

[max_deviation_from_mean_before_I, idx_mx_dv_mean_before_I]=max([abs(max_before_I-mean_before_I) abs(min_before_I-mean_before_I)],[],2);

NEMA_Before_I=max_deviation_from_mean_before_I./mean_before_I;

figure(1)


for i=1:length(DSSLines)
        if M{i,4}>0 & M{i,2} & M{i,5} & M{i,5}
            %determines color based on percent reduction locally
            if NEMA_Before_V(i)>0 & NEMA_Before_V(i)<0.005 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',8)
                end
            
                  
            elseif NEMA_Before_V(i)>0.005 & NEMA_Before_V(i)<0.01 %color
                 % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',8)
                end
            
            
            elseif NEMA_Before_V(i)>0.01 & NEMA_Before_V(i)<0.015 %color
                  % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',8)
                end
            
            elseif NEMA_Before_V(i)>0.015 & NEMA_Before_V(i)<0.02 %color
                 % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',8)
                end
            
            elseif NEMA_Before_V(i)>0.02 & NEMA_Before_V(i)<0.025 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',8)
                end
            
            elseif NEMA_Before_V(i)>0.025 & NEMA_Before_V(i)<0.03 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',8)
                end
            
            
             elseif NEMA_Before_V(i)>0.03 & NEMA_Before_V(i)<0.035 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',8)
                end
            
             elseif NEMA_Before_V(i)>0.035
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',8)
                end
            
            
            end
        hold on
        end
end
caxis([0 4])
Color1=[0 1 1; 0 0 1; 0 1 0; 0.4660 0.6740 0.1880; 1 1 0; 0.9290 0.6940 0.1250; 0.8500 0.3250 0.0980; 1 0 0];
colormap(Color1);
colorbar; 
title(['Maximum Voltage imbalance (Before) , Max is ', num2str(max(NEMA_Before_V)*100), '% '])

DSSCircuit.SetActiveBus(PBA_Node);
DSSCircuit.Lines.name=LineName;
I_line_before1=DSSCircuit.ActiveCktElement.Currents;
I_ABC_before1=[I_line_before1(7)+j*I_line_before1(8); I_line_before1(9)+j*I_line_before1(10); I_line_before1(11)+j*I_line_before1(12)];
Vbus1=DSSCircuit.ActiveBus.Voltages;
V_ABC_before1=[Vbus1(1)+j*Vbus1(2); Vbus1(3)+j*Vbus1(4); Vbus1(5)+j*Vbus1(6)];

%***********Get data from Feeder head********%

DSSCircuit.Lines.name='L5000_1'; 
I_Sub_before=DSSCircuit.ActiveCktElement.Currents;
I_Sub_ABC_before=[I_Sub_before(7)+j*I_Sub_before(8); I_Sub_before(9)+j*I_Sub_before(10); I_Sub_before(11)+j*I_Sub_before(12)];
DSSCircuit.SetActiveBus(PBA_Node);

DSSCircuit.SetActiveBus(FeederNode);

Vbus_Sub_before=DSSCircuit.ActiveBus.Voltages; %
V_Sub_ABC_before=[Vbus_Sub_before(1)+j*Vbus_Sub_before(2); Vbus_Sub_before(3)+j*Vbus_Sub_before(4); Vbus_Sub_before(5)+j*Vbus_Sub_before(6)];

%***********************************************%

%Local Measurement
[Iabc_compensation,Iabc_power,ZCMMIN,Device_Losses] = PBAL_func_withlosses(V_ABC_before1,I_ABC_before1,50e3);
%Substation Measurement
% [Iabc_compensation,Iabc_power,ZCMMIN,Device_Losses] = PBAL_func_withlosses(V_Sub_ABC_before,I_Sub_ABC_before.*[1; .3; 1],50e3);


Iabc_shunt=Iabc_compensation+Iabc_power;

V_PB=V_ABC_before1;

for n=1:6    
% S_inj=V_PB.*(conj(Iabc_new-I_before))/rescale_V;
S_inj=V_PB.*(conj(Iabc_shunt));

if n>1
    type='Edit';
else
    type='New';
end

DSSText.Command=[type,' Generator.671a1 Phases=1 Bus1=', PBA_Node '.1 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=' num2str(real(S_inj(1))/1e3)];
DSSText.Command=[type,' Generator.671a2 Phases=1 Bus1=', PBA_Node '.1 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=' num2str(imag(S_inj(1))/1e3)];
DSSText.Command=[type,' Generator.671b1 Phases=1 Bus1=', PBA_Node '.2 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=' num2str(real(S_inj(2))/1e3)];
DSSText.Command=[type,' Generator.671b2 Phases=1 Bus1=', PBA_Node '.2 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=' num2str(imag(S_inj(2))/1e3)];
DSSText.Command=[type,' Generator.671c1 Phases=1 Bus1=', PBA_Node '.3 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=' num2str(real(S_inj(3))/1e3)];
DSSText.Command=[type,' Generator.671c2 Phases=1 Bus1=', PBA_Node '.3 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=' num2str(imag(S_inj(3))/1e3)];

DSSText.Command='calcv';% Z Ding added

DSSText.Command='set number=1 stepsize=15m hour=0 sec=0';
DSSText.Command=['set hour=',num2str(0/4),' h=',num2str(900*step),' sec=',num2str(0)];

DSSText.Command='solve';

DSSCircuit.SetActiveBus(PBA_Node); % This is the node where voltage is measured for voltage unbalance
DSSActiveBus=DSSCircuit.ActiveBus;
Vbus_new=DSSActiveBus.Voltages;
V_downABC_new=[Vbus_new(1)+j*Vbus_new(2); Vbus_new(3)+j*Vbus_new(4); Vbus_new(5)+j*Vbus_new(6)];
V_new=ABC_to_SEQ*V_downABC_new;

error(:,n)=V_downABC_new-V_PB;

V_PB=V_downABC_new;

end



   


% colormap(Color1);
% colorbar; 

%neutral current


%LINE.LN6170256-1


%getting system nutral current acorss network if PhaseEQ is applied on node
%above


M_B={};
for i=1:length(DSSLines)
DSSCircuit.Lines.name=char(DSSLines(i));

bus_B=DSSCircuit.ActiveCktElement.BusNames;
DSSCircuit.SetActiveBus(char(bus_B(2)));

if length(DSSCircuit.ActiveCktElement.Currents)==12 & length(DSSCircuit.ActiveBus.Voltages)==6
M_B{i,1}=DSSCircuit.ActiveCktElement.SeqCurrents(4); %I0, second terminal of the line (first terminal is index 1)
I_neutral_B(i,1)=DSSCircuit.ActiveCktElement.SeqCurrents(4)*3;

Vbus=DSSCircuit.ActiveBus.Voltages;
V_ABC_after(:,i)=[Vbus(1)+j*Vbus(2); Vbus(3)+j*Vbus(4); Vbus(5)+j*Vbus(6)];
I_line_after=DSSCircuit.ActiveCktElement.Currents;
I_ABC_after(:,i)=[I_line_after(7)+j*I_line_after(8); I_line_after(9)+j*I_line_after(10); I_line_after(11)+j*I_line_after(12)];

M_B{i,2}=DSSCircuit.ActiveBus.x; % To bus x coordinate
M_B{i,3}=DSSCircuit.ActiveBus.y; % To bus y coordinate


DSSCircuit.SetActiveBus(char(bus_B(1)));
M_B{i,4}=DSSCircuit.ActiveBus.x; % From bus x coordinate
M_B{i,5}=DSSCircuit.ActiveBus.y; % From bus y coordinate
M_B{i,6}=3; % # of phases
M_B{i,7}=bus_B(2); %To bus name
M_B{i,8}=bus_B(1); %From bus name
M_B{i,9}=DSSCircuit.ActiveCktElement.name; %element




else
    M_B{i,1}=NaN;
    I_neutral_B(i,1)=NaN;
    
    I_ABC_after(:,i)=[NaN+j*NaN; NaN+j*NaN; NaN+j*NaN];
    V_ABC_after(:,i)=[NaN+j*NaN; NaN+j*NaN; NaN+j*NaN];
    
    M_B{i,2}=DSSCircuit.ActiveBus.x; % To bus x coordinate
    M_B{i,3}=DSSCircuit.ActiveBus.y; % To bys y coordinate
    M_B{i,4}=DSSCircuit.ActiveBus.x; % From bus x coordinate
    M_B{i,5}=DSSCircuit.ActiveBus.y; % From bus y coordinate
    %****
    M_B{i,6}=1; % # of phases if 1 it means it could be 1 or 2
    %****
    M_B{i,7}=bus_B(2); %To bus name
    M_B{i,8}=bus_B(1); %From bus name
    M_B{i,9}=DSSCircuit.ActiveCktElement.name; %element
    
end
end

% I_neutral_percentage_B=I_neutral_B/max(I_neutral);

%*******NEMA Voltage after******
[max_after_V, idx_max_after_V]=max(abs(transpose(V_ABC_after)),[],2);
[min_after_V, idx_min_after_V]=min(abs(transpose(V_ABC_after)),[],2);
mean_after_V=transpose(mean(abs(V_ABC_after)));
 
[max_deviation_from_mean_after_V, idx_mx_dv_mean_after_V]=max([abs(max_after_V-mean_after_V) abs(min_after_V-mean_after_V)],[],2);
 
NEMA_After_V=max_deviation_from_mean_after_V./mean_after_V;


%*******NEMA Current after******
[max_after_I, idx_max_after_I]=max(abs(transpose(I_ABC_after)),[],2);
[min_after_I, idx_min_after_I]=min(abs(transpose(I_ABC_after)),[],2);
mean_after_I=transpose(mean(abs(I_ABC_after)));
 
[max_deviation_from_mean_after_I, idx_mx_dv_mean_after_I]=max([abs(max_after_I-mean_after_I) abs(min_after_I-mean_after_I)],[],2);
 
NEMA_After_I=max_deviation_from_mean_after_I./mean_after_I;


I_neutral_percentage_B=I_neutral/max(I_neutral);
% I_neutral_balanced_percentage=I_neutral_balanced/max(I_neutral);

I_neutral_balanced_percentage2_B=(I_neutral-I_neutral_B)./I_neutral;

% I_neutral_percentage_B=I_neutral/max(I_neutral);
% I_neutral_balanced_percentage=I_neutral_balanced/max(I_neutral);

% I_neutral_balanced_percentage2=(I_neutral-I_neutral_balanced)./I_neutral;
figure(2)


for i=1:length(DSSLines)
        if M{i,4}>0 & M{i,2} & M{i,5} & M{i,5}
            %determines color based on percent reduction locally
            if NEMA_After_V(i)>0 & NEMA_After_V(i)<0.005 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',8)
                end
            
                  
            elseif NEMA_After_V(i)>0.005 & NEMA_After_V(i)<0.01 %color
                 % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',8)
                end
            
            
            elseif NEMA_After_V(i)>0.01 & NEMA_After_V(i)<0.015 %color
                  % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',8)
                end
            
            elseif NEMA_After_V(i)>0.015 & NEMA_After_V(i)<0.02 %color
                 % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',8)
                end
            
            elseif NEMA_After_V(i)>0.02 & NEMA_After_V(i)<0.025 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',8)
                end
            
            elseif NEMA_After_V(i)>0.025 & NEMA_After_V(i)<0.03 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',8)
                end
            
            
             elseif NEMA_After_V(i)>0.03 & NEMA_After_V(i)<0.035 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',8)
                end
            
             elseif NEMA_After_V(i)>0.035
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',8)
                end
            
            
            end
        hold on
        end
end
caxis([0 4])
Color1=[0 1 1; 0 0 1; 0 1 0; 0.4660 0.6740 0.1880; 1 1 0; 0.9290 0.6940 0.1250; 0.8500 0.3250 0.0980; 1 0 0];
colormap(Color1);
colorbar; 
title(['Maximum Voltage imbalance (After) , Max is ', num2str(max(NEMA_After_V)*100), '% '])


figure(3)

for i=1:length(DSSLines)
        if M{i,4}>0 & M{i,2} & M{i,5} & M{i,5}
            %determines color based on percent reduction locally
            if NEMA_Before_I(i)>0 & NEMA_Before_I(i)<0.1 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',8)
                end
            
                  
            elseif NEMA_Before_I(i)>0.1 & NEMA_Before_I(i)<0.2 %color
                 % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',8)
                end
            
            
            elseif NEMA_Before_I(i)>0.2 & NEMA_Before_I(i)<0.3 %color
                  % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',8)
                end
            
            elseif NEMA_Before_I(i)>0.3 & NEMA_Before_I(i)<0.4 %color
                 % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',8)
                end
            
            elseif NEMA_Before_I(i)>0.4 & NEMA_Before_I(i)<0.5 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',8)
                end
            
            elseif NEMA_Before_I(i)>0.5 & NEMA_Before_I(i)<0.6 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',8)
                end
            
            
             elseif NEMA_Before_I(i)>0.6 & NEMA_Before_I(i)<0.7 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',8)
                end
            
             elseif NEMA_Before_I(i)>0.7
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',8)
                end
            
            
            end
        hold on
        end
end
caxis([0 80])
Color1=[0 1 1; 0 0 1; 0 1 0; 0.4660 0.6740 0.1880; 1 1 0; 0.9290 0.6940 0.1250; 0.8500 0.3250 0.0980; 1 0 0];
colormap(Color1);
colorbar; 
title(['Maximum phase imbalance (Before) , Max is ', num2str(max(NEMA_Before_I)*100), '% '])

figure(4)


for i=1:length(DSSLines)
        if M{i,4}>0 & M{i,2} & M{i,5} & M{i,5}
            %determines color based on percent reduction locally
            if NEMA_After_I(i)>0 & NEMA_After_I(i)<0.1 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 1], 'LineWidth',8)
                end
            
                  
            elseif NEMA_After_I(i)>0.1 & NEMA_After_I(i)<0.2 %color
                 % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 0 1], 'LineWidth',8)
                end
            
            
            elseif NEMA_After_I(i)>0.2 & NEMA_After_I(i)<0.3 %color
                  % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0 1 0], 'LineWidth',8)
                end
            
            elseif NEMA_After_I(i)>0.3 & NEMA_After_I(i)<0.4 %color
                 % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.4660 0.6740 0.1880], 'LineWidth',8)
                end
            
            elseif NEMA_After_I(i)>0.4 & NEMA_After_I(i)<0.5 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 1 0], 'LineWidth',8)
                end
            
            elseif NEMA_After_I(i)>0.5 & NEMA_After_I(i)<0.6 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.9290 0.6940 0.1250], 'LineWidth',8)
                end
            
            
             elseif NEMA_After_I(i)>0.6 & NEMA_After_I(i)<0.7 %color
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [0.8500 0.3250 0.0980], 'LineWidth',8)
                end
            
             elseif NEMA_After_I(i)>0.7
                % determines thinkness based on amount of current/normalized to max
                if I_neutral_percentage(i)>0 & I_neutral_percentage(i)<0.125 %thickness
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',1)
                elseif I_neutral_percentage(i)>0.125 & I_neutral_percentage(i)<0.25
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',2)
                elseif I_neutral_percentage(i)>0.25 & I_neutral_percentage(i)<0.375
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',3)
                elseif I_neutral_percentage(i)>0.375 & I_neutral_percentage(i)<0.5
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',4)
                elseif I_neutral_percentage(i)>0.5 & I_neutral_percentage(i)<0.625
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',5)
                elseif I_neutral_percentage(i)>0.625 & I_neutral_percentage(i)<0.75
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',6)
                elseif I_neutral_percentage(i)>0.75 & I_neutral_percentage(i)<0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',7)
                elseif I_neutral_percentage(i)>0.875
                plot([M{i,4},M{i,2}]/1e6, [M{i,5},M{i,3}]/1e6, 'color', [1 0 0], 'LineWidth',8)
                end
            
            
            end
        hold on
        end
end
caxis([0 80])
Color1=[0 1 1; 0 0 1; 0 1 0; 0.4660 0.6740 0.1880; 1 1 0; 0.9290 0.6940 0.1250; 0.8500 0.3250 0.0980; 1 0 0];
colormap(Color1);
colorbar; 
title(['Maximum phase imbalance (After) , Max is ', num2str(max(NEMA_After_I)*100), '% '])




    

