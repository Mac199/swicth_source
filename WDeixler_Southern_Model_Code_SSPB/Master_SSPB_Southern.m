clc;
close all;

Node='189_3744947'; % Location of device placment
I_Meas='LINE.227_2772953_3'; %Current measurment location
step=2754;
Vnode=Node; %Voltage Measurment node, usually same as device node, so keep the same unless you want to look at voltages at a different node
Sys_Voltage=13.2e3; %what's the line to line voltage of the location of PB placement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Vbaseold = Sys_Voltage/sqrt(3);

filepath='Compile (C:\Users\wangying\Documents\switch_source\WDeixler_Southern_Model_Code_SSPB\master_Meldrim_M3222_M3442_OneFeeder.dss)'; % Here modify according to the name and location of the system file

DG_buses = fileread('BusListLocation2Phase1.txt'); % set DG location here
DG_buses = string(strsplit(DG_buses))';
%***************************************

DSSObj = actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0)
disp('Unable to start the OpenDSS Engine');
return
end

PBA_Node=Node; %This is the node where the PBA is installed
PBA_Line=I_Meas;%This is the line that terminates at the PBA bus (the line where to meaure current before compensation)
Line_Upstream=PBA_Line; %This is the line to measure current afetr compensation

V_measur_bus=Vnode; %This is the voltage measumrent bus to calacualte voltage ubalanace
    
DSSText = DSSObj.Text; % Used for all text interfacing from matlab to opendss
DSSCircuit = DSSObj.ActiveCircuit; % active circuit
DSSBus = DSSCircuit.ActiveBus;
% Write Path where Master and its associated files are stored and compile as per following command
DSSText.Command=filepath;
DSSText.Command='set voltagebases=[13.2 24.94 69.0]';
%DSSText.Command='batchedit load..* Vmin=0.75'; % Set Vmin lower so that load model property will remain same
DSSText.Command='solve';

%Initializes PB generators
DSSText.Command=['New Generator.671a1 Phases=1 Bus1=', PBA_Node '.1 ', 'kV=', num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=0'];
DSSText.Command=['New Generator.671a2 Phases=1 Bus1=', PBA_Node '.1 ', 'kV=', num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=0'];
DSSText.Command=['New Generator.671b1 Phases=1 Bus1=', PBA_Node '.2 ', 'kV=', num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=0'];
DSSText.Command=['New Generator.671b2 Phases=1 Bus1=', PBA_Node '.2 ', 'kV=', num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=0'];
DSSText.Command=['New Generator.671c1 Phases=1 Bus1=', PBA_Node '.3 ', 'kV=', num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=0'];
DSSText.Command=['New Generator.671c2 Phases=1 Bus1=', PBA_Node '.3 ', 'kV=', num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=0'];

%Initial DG placement
DSSText.Command = sprintf('new generator.PVGen%i phases=1 bus1=%s kV=7.967433714828 kW=10 kvar=0 model=3', 1, DG_buses(1));

DSSCircuit.Generators.Name = 'PVGen1'; % Sets Generator as active element

Buses = string(DSSCircuit.AllBusNames);
Nodes = string(DSSCircuit.AllNodeNames);

for i = 1:1000
   i
   
   SystemLosses0=(DSSCircuit.Losses)/1000; % Will Give you Distribution System Losses in kWs and kVArs
  

    DSSTransformers=DSSCircuit.Transformers;
    DSSCktElement = DSSCircuit.ActiveCktElement;

    DSSCircuit.SetActiveBus(V_measur_bus); % This is the node where voltage is measured for voltage unbalance
    DSSActiveBus=DSSCircuit.ActiveBus;
    Vbus671=DSSActiveBus.Voltages; % in complex value?

    alpha = exp(1j*2*pi/3);
    ABC_to_SEQ = 1/3*[1 1 1;1 alpha alpha^2;1 alpha^2 alpha];

    V_downABC671=[Vbus671(1)+j*Vbus671(2); Vbus671(3)+j*Vbus671(4); Vbus671(5)+j*Vbus671(6)];
    V_old=ABC_to_SEQ*V_downABC671;

    DSSCircuit.SetActiveBus(PBA_Node); % This is the node where the PBA is installed
    DSSActiveBus=DSSCircuit.ActiveBus;
    Vbus=DSSActiveBus.Voltages;
    V_ABC_before1=[Vbus(1)+j*Vbus(2); Vbus(3)+j*Vbus(4); Vbus(5)+j*Vbus(6)];
    I_line_before1=DSSCircuit.ActiveCktElement.Currents;
    I_ABC_before1=[I_line_before1(7)+j*I_line_before1(8); I_line_before1(9)+j*I_line_before1(10); I_line_before1(11)+j*I_line_before1(12)];

    DSSCircuit.SetActiveElement(PBA_Line); %This is the line that terminates at the PBA bus
    DSSActiveCktElement=DSSCircuit.ActiveCktElement;
    I_line=DSSActiveCktElement.Currents;
    I_ABC=[I_line(7)+j*I_line(8); I_line(9)+j*I_line(10); I_line(11)+j*I_line(12)];
    %%%%%%%%%%%%%%%%%%
    %Runs the device code algorithm to determine the optimal set points to be
    %used as inputs to the 6 generatros below (3 for real power and 3 for
    %reactive power)
    [Iabc_compensation,Iabc_power,ZCMMIN,Device_Losses] = PBAL_func_withlosses(V_ABC_before1,I_ABC_before1,50e3);
    Iabc_shunt=Iabc_compensation+Iabc_power;
    V_PB=V_ABC_before1;
    %%%%%%%%%%The part below simulates the optimal setpoint in the OpenDSS
    %%%%%%%%%%model***********%%%
    for n=1:6    
    S_inj=V_PB.*(conj(Iabc_shunt));
    if n>1
        type='Edit';
    else
        type='New';
    end
        DSSCircuit.Generators.Name = ('671a1');
        DSSCircuit.Generators.kW = real(S_inj(1))/1e3;

        DSSCircuit.Generators.Name = ('671a2');
        DSSCircuit.Generators.kVar = imag(S_inj(1))/1e3;

        DSSCircuit.Generators.Name = ('671b1');
        DSSCircuit.Generators.kW = real(S_inj(2))/1e3;

        DSSCircuit.Generators.Name = ('671b2');
        DSSCircuit.Generators.kVar = imag(S_inj(2))/1e3;

        DSSCircuit.Generators.Name = ('671c1');
        DSSCircuit.Generators.kW = real(S_inj(3))/1e3;

        DSSCircuit.Generators.Name = ('671c2');
        DSSCircuit.Generators.kVar = imag(S_inj(3))/1e3;
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

    SystemLosses1=(DSSCircuit.Losses)/1000;

    DSSCircuit.SetActiveElement(Line_Upstream); %This is the line ....
    DSSActiveCktElement=DSSCircuit.ActiveCktElement;
    I_line632=DSSActiveCktElement.Currents;
    I_ABC632=[I_line632(7)+j*I_line632(8); I_line632(9)+j*I_line632(10); I_line632(11)+j*I_line632(12)];


    I632seq_actual= ABC_to_SEQ*I_ABC632;

    %% Calculate "Actual" upstream current reduction
%     I0_red_actual = 100*(1-abs(I632seq_actual(1))/abs(I0632_old));
%     IP_red_actual = 100*(1-abs(I632seq_actual(2))/abs(IP632_old));
%     IN_red_actual = 100*(1-abs(I632seq_actual(3))/abs(IN632_old));

    DSSCircuit.SetActiveBus(PBA_Node); % This is the node where the PBA is installed
    DSSActiveBus=DSSCircuit.ActiveBus;
    Vbus_new=DSSActiveBus.Voltages;
    %V_downABC_new=[Vbus_new(1)+j*Vbus_new(2); Vbus_new(3)+j*Vbus_new(4); Vbus_new(5)+j*Vbus_new(6)];

    DSSCircuit.SetActiveBus(V_measur_bus); % This is the node where voltage is measured for voltage unbalance
    DSSActiveBus=DSSCircuit.ActiveBus;
    Vbus671_new=DSSActiveBus.Voltages;
    V_downABC671_new=[Vbus671_new(1)+j*Vbus671_new(2); Vbus671_new(3)+j*Vbus671_new(4); Vbus671_new(5)+j*Vbus671_new(6)];
    V_new=ABC_to_SEQ*V_downABC671_new;

    %disp(['Zero-sequence target reducation is ',num2str(I0_reduction),' percent','...Actual reduction is ', num2str(I0_red_actual), ' percent'])
    %disp(['Negative-sequence target reducation is ',num2str(IN_reduction),' percent','...Actual reduction is ', num2str(IN_red_actual), ' percent'])
    %disp(['Positive-sequence target reducation is ',num2str(IP_reduction),' percent','...Actual reduction is ', num2str(IP_red_actual), ' percent'])
    %disp(['.........................................................................'])
    %disp(['System Losses before balancing is ',num2str(SystemLosses0(1)),' kW','...Sysem Losses after balancing is ', num2str(SystemLosses1(1)), ' kW',' Losses reduction is ',num2str(SystemLosses0(1)-SystemLosses1(1)),' kW'])

%     I_Old_Target_Actual=[abs(I0632_old) abs(IN632_old) abs(IP632_old) abs(I632seq_new(1)) abs(I632seq_new(3))...
%         abs(I632seq_new(2)) abs(I632seq_actual(1)) abs(I632seq_actual(3)) abs(I632seq_actual(2)) SystemLosses0(1)-SystemLosses1(1) SystemLosses0(1) SystemLosses1(1)];
    %V in kV
%     V_Old_New=[abs(V_old(1))/1e3 abs(V_old(3))/1e3 abs(V_old(2))/1e3 abs(V_new(1))/1e3 abs(V_new(3))/1e3 abs(V_new(2))/1e3]; %in 0,1,2

%     Vabc_Old_New=[abs(V_downABC671(1))/1e3 abs(V_downABC671(2))/1e3 abs(V_downABC671(3))/1e3 abs(V_downABC671_new(1))/1e3 abs(V_downABC671_new(2))/1e3 abs(V_downABC671_new(3))/1e3]; %abc, to be used for NEMA% Unbalance
   
   DSSText.Command='calcvoltagebases';% Z Ding added
   DSSText.Command='solve';
   
   %% Voltage violation
   VV = DSSCircuit.AllBusVmagPu; % creates a vector of all the bus voltages
   Vmax = max(VV); % finds the maximum voltage
   VminTest = VV;
   VminTest(VminTest == 0) = []; % removes any buses with 0 voltage
   Vmin = min(VminTest); % finds minimum voltage
   if Vmax > 1.05
       idxVV = find(VV==Vmax); % finds the vector index where violation occurred
       disp('Voltage violation at bus ')
       disp(Nodes(idxVV)) % pulls node from node list where violation occurred
       disp('Max kW = ') 
       disp((DSSCircuit.Generators.Count - 6)*10) % finds total number of kW placed (-6 for the PB generators)
       break
   elseif Vmin < 0.95
       idxVV = find(VV==Vmin);
       disp('Voltage violation at bus ')
       disp(Nodes(idxVV))
       disp('Max kW = ') 
       disp((DSSCircuit.Generators.Count - 6)*10)
       disp(DSSCircuit.Generators.Count)
       break
   end

   %% Current Capacity
   DSSLines = DSSObj.ActiveCircuit.Lines; % sets lines as active
   DSSActiveCktElement = DSSObj.ActiveCircuit.ActiveCktElement;
   i_Line = DSSLines.First; % sets first line as active
   while i_Line > 0 % i_Line = 0 when out of lines
       BiDirCurrents = DSSActiveCktElement.CurrentsMagAng; % takes bidirectional current of line
       Currents = BiDirCurrents(1:size(BiDirCurrents,2)/2); % takes the currents in one direction only
       CurrentMag = Currents(1:2:end); % removes angles
       Amax = max(CurrentMag(:)); % finds maximum current
       if Amax > DSSActiveCktElement.NormalAmps % compares max current to ampacity rating of line
           disp('Current capacity reached at line ')
           disp(DSSActiveCktElement.Name)
           disp('Max kW = ') 
           disp((DSSCircuit.Generators.Count - 6)*10)
       break
       end
       i_Line = DSSLines.Next; % makes next line active
   end
   %% Substation backfeed
   DSSCircuit.SetActiveElement(['LINE.227_4349091_1']); % line entering substation
   BiDirPowers = DSSActiveCktElement.Powers; % bidirectional powers
   Powers = BiDirPowers(:,size(BiDirPowers,2)/2 + 1:end); % unidirectional powers
   RealPowers = Powers(:,1:2:end); % takes out imaginary powers
   pMax = max(RealPowers); % finds maximum power as this will be positive if backfeed occurs
   if pMax > 0 % checks if maximum power is positive
       [tMax,tPhaseMax] = find(RealPowers == pMax);
       disp('Substation backfeed occurred at phase')
       disp(tPhaseMax)
       disp('Max kW = ') 
       disp((DSSCircuit.Generators.Count - 6)*10)
       break
   end
   
   %% Voltage unbalance
   for k = 1:numel(Buses) % cycles through each bus
       DSSCircuit.SetActiveBus(Buses(k)); % sets current bus active
       DSSActiveBus=DSSCircuit.ActiveBus;
       VU = DSSActiveBus.puVmagAngle; % finds voltage of bus
       VU123 = VU(1:2:end); % removes angles
       VU123(VU123 == 0) = []; % removes voltages = 0
       M = mean(VU123); % finds mean of voltages at the bus
       unbalance = VU123./M * 100;% finds percent unbalance
       if max(unbalance(:)) > 110 % checks if unbalance is >10% from mean
           busU = Buses(k);
           phaseU = find(unbalance == max(unbalance(:)));
           disp('Voltage unbalance occurred at bus ')
           disp(busU)
           disp('Phase')
           disp(phaseU)
           disp('Max kW = ') 
           disp((DSSCircuit.Generators.Count - 6)*10)
           break
       elseif min(unbalance(:)) < 90 % checks if unbalance is <10% from mean
           busU = Buses(k);
           phaseU = find(unbalance == min(unbalance(:)));
           disp('Voltage unbalance occurred at bus ')
           disp(busU)
           disp('Phase')
           disp(phaseU)
           disp('Max kW = ') 
           disp((DSSCircuit.Generators.Count - 6)*10)
           break
       end
   end  
   %% Add new DG
   DSSCircuit.Generators.Name = sprintf('PVGen%i', i); % sets last placed DG as active
   GenBus = string(DSSCircuit.ActiveElement.Bus); % finds the bus this DG was placed`
   GenBusIdx = find(DG_buses == GenBus); % finds where in the bus list this DG was placed
   NewBus = DG_buses(GenBusIdx + 1); % takes next bus from the bus list
   DSSText.Command = sprintf('new generator.PVGen%i phases=1 bus1=%s kV=7.967433714828 kW=10 kvar=0 model=3', i+1, NewBus); % places new DG on this bus
   DSSCircuit.Generators.Name = sprintf('PVGen%i', i+1); % sets new DG as active

end